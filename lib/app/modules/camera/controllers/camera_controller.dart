import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../main.dart';
import '../../../core/dialogs.dart';
import '../../../core/face_embed.dart';
import '../../../core/image_utils.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/attendance_queue_service.dart';
import '../../home/controllers/home_controller.dart';

enum CameraStage { initializing, ready, capturing, captured, done }

class CustomCameraController extends GetxController {
  CameraController? cameraController;
  final isInitialized = false.obs;
  final permissionDenied = false.obs;

  final stage = CameraStage.initializing.obs;

  // Captured photo state ---------------------------------------------------
  final capturedPath = Rxn<String>();
  List<double>? _capturedEmbedding;
  bool _captureTriggered = false;

  ApiService? get _api =>
      Get.isRegistered<ApiService>() ? Get.find<ApiService>() : null;
  AttendanceQueueService? get _queue =>
      Get.isRegistered<AttendanceQueueService>()
          ? Get.find<AttendanceQueueService>()
          : null;

  bool get requireFace {
    final args = Get.arguments;
    if (args is Map && args['requireFace'] == true) return true;
    return false;
  }

  /// When set ('check_in' / 'check_out') the camera handles the entire
  /// attendance flow end-to-end: capture → embed → GPS → POST → result
  /// dialog. Otherwise the camera returns the result and the caller
  /// decides (enrollment, avatar, report photo, etc).
  String? get attendanceType {
    final args = Get.arguments;
    if (args is Map) {
      final v = args['attendanceType'];
      if (v == 'check_in' || v == 'check_out') return v as String;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    debugPrint('[camera] Permission.camera status=$status');
    if (!status.isGranted) {
      permissionDenied.value = true;
      Future.delayed(Duration.zero, () {
        Get.snackbar(
          'Camera Permission Denied',
          status.isPermanentlyDenied
              ? 'Enable the camera permission in Settings to take a photo.'
              : 'Camera permission is required for attendance.',
        );
      });
      return;
    }

    if (cameras.isEmpty) {
      Future.delayed(Duration.zero, () {
        Get.snackbar('Error', 'No cameras available on this device');
      });
      return;
    }

    CameraDescription? selected;
    for (final c in cameras) {
      if (c.lensDirection == CameraLensDirection.front) {
        selected = c;
        break;
      }
    }
    selected ??= cameras.first;

    final ctrl = CameraController(
      selected,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await ctrl.initialize();
      cameraController = ctrl;
      isInitialized.value = true;
      stage.value = CameraStage.ready;
      debugPrint(
        '[camera] initialized aspect=${ctrl.value.aspectRatio} preview=${ctrl.value.previewSize}',
      );
    } catch (e) {
      await ctrl.dispose();
      debugPrint('[camera] init error: $e');
      Future.delayed(Duration.zero, () {
        Get.snackbar('Camera Error', 'Could not initialize camera: $e');
      });
    }
  }

  /// Shutter button handler. Used for every flow — the controller branches
  /// based on [requireFace] / [attendanceType] for what to do after the
  /// still has been captured.
  Future<void> takePictureManual() async {
    if (_captureTriggered) return;
    _captureTriggered = true;
    stage.value = CameraStage.capturing;

    final ctrl = cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) {
      _captureTriggered = false;
      return;
    }

    try {
      final XFile picture = await ctrl.takePicture();
      capturedPath.value = picture.path;
      stage.value = CameraStage.captured;

      // Do NOT call ctrl.dispose() here. The camera plugin still has a
      // queued onCaptureCompleted → unlockAutoFocus callback that fires
      // shortly after takePicture() returns. Disposing now closes the
      // device underneath that callback and triggers
      // `IllegalStateException: CameraDevice was already closed`, which
      // is uncaught and kills the process (force close on the device).
      // The view stops rendering CameraPreview as soon as capturedPath is
      // set (it switches to Image.file), so the texture is already idle.
      // Real cleanup happens in onClose() when the GetX controller is
      // removed.

      if (requireFace) {
        final embedding =
            await FaceEmbedder.instance.embedFromFile(picture.path);
        _capturedEmbedding = embedding?.toList();
      }

      if (attendanceType != null) {
        await _submitAttendance(picture.path);
      } else if (requireFace) {
        // Enrollment / non-attendance face flow.
        stage.value = CameraStage.done;
        Get.back(result: {
          'path': picture.path,
          'embedding': _capturedEmbedding,
        });
      } else {
        // Non-face flow (avatar / report photo). Return the path String for
        // backward compatibility with existing callers.
        stage.value = CameraStage.done;
        Get.back(result: picture.path);
      }
    } catch (e) {
      debugPrint('[camera] capture error: $e');
      await _resetAfterError('Failed to capture photo: $e');
    }
  }

  Future<void> _submitAttendance(String photoPath) async {
    final type = attendanceType;
    final api = _api;
    if (type == null || api == null) {
      await _resetAfterError('Service not ready. Please try again.');
      return;
    }

    showAppLoadingDialog('Validating & sending…');

    Position? position;
    try {
      position = await _resolvePosition();
    } catch (e) {
      closeAppLoadingDialog();
      await showAppResultDialog(
        success: false,
        title: 'Location Problem',
        message: 'Could not read location: $e',
      );
      await _retake();
      return;
    }
    if (position == null) {
      closeAppLoadingDialog();
      await showAppResultDialog(
        success: false,
        title: 'Location Not Ready',
        message: 'Turn on GPS and grant location permission, then try again.',
      );
      await _retake();
      return;
    }

    File toUpload;
    try {
      toUpload = await stripExif(
        File(photoPath),
        maxDimension: 1280,
        quality: 80,
      );
    } catch (_) {
      toUpload = File(photoPath);
    }

    final fileName = toUpload.path.split('/').last;
    final embedding = _capturedEmbedding;
    final formData = dio_pkg.FormData.fromMap({
      'photo': await dio_pkg.MultipartFile.fromFile(
        toUpload.path,
        filename: fileName,
      ),
      'latitude': position.latitude,
      'longitude': position.longitude,
      if (embedding != null) 'faceEmbedding': jsonEncode(embedding),
    });

    try {
      final response = await api.dio.post(
        type == 'check_in'
            ? '/mobile/attendances/check-in'
            : '/mobile/attendances/check-out',
        data: formData,
      );

      closeAppLoadingDialog();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        final payload =
            body is Map && body['data'] is Map ? body['data'] as Map : null;
        final isWithinZone = payload?['isWithinZone'] == true;
        final score = _asDouble(payload?['faceScore']);
        final baseMsg = (body is Map ? body['message'] : null) ??
            'Attendance submitted successfully';
        final lines = <String>[
          baseMsg,
          isWithinZone ? '✓ Inside office zone' : '⚠ Outside office zone',
          if (score != null)
            '✓ Face match (score ${score.toStringAsFixed(3)})',
        ];
        stage.value = CameraStage.done;
        await showAppResultDialog(
          success: true,
          title: type == 'check_in'
              ? 'Check-in Successful'
              : 'Check-out Successful',
          message: lines.join('\n'),
        );
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().refresh();
        }
        Get.offAllNamed('/dashboard');
      }
    } on dio_pkg.DioException catch (e) {
      debugPrint(
        '[attendance] submit DioException: type=${e.type} status=${e.response?.statusCode} body=${e.response?.data}',
      );
      closeAppLoadingDialog();
      if (_isNetworkError(e)) {
        await _queue?.enqueue(
          type: type,
          photoPath: photoPath,
          lat: position.latitude,
          lng: position.longitude,
          embedding: _capturedEmbedding,
        );
        await showAppResultDialog(
          success: true,
          title: 'Saved Offline',
          message: 'No connection. Your attendance will be submitted '
              'automatically once you are back online.',
        );
        stage.value = CameraStage.done;
        Get.offAllNamed('/dashboard');
        return;
      }

      final data = e.response?.data;
      final rawMsg = (data is Map ? data['message'] : null) ??
          'Failed to submit attendance';
      final errBlock = data is Map && data['error'] is Map
          ? data['error'] as Map
          : null;
      final code = errBlock?['code']?.toString();
      final details = errBlock?['details'];
      final score = details is Map ? _asDouble(details['score']) : null;
      final threshold =
          details is Map ? _asDouble(details['threshold']) : null;

      // Friendly message for face-not-enrolled — the user needs to upload a
      // clear face photo before they can check in.
      String msg = rawMsg.toString();
      if (code == 'FACE_NOT_ENROLLED' ||
          msg.toLowerCase().contains('face') &&
              msg.toLowerCase().contains('not')) {
        msg =
            'Face not registered. Open profile and upload a clear face photo '
            'as your profile picture.';
      }

      final extra = <String>[];
      if (code != null) extra.add('Code: $code');
      if (score != null && threshold != null) {
        extra.add(
          'Face score ${score.toStringAsFixed(3)} '
          '(minimum ${threshold.toStringAsFixed(2)})',
        );
      }
      await showAppResultDialog(
        success: false,
        title: 'Attendance Failed',
        message: [msg, ...extra].join('\n'),
        okLabel: 'Try Again',
      );
      await _retake();
    } catch (e) {
      closeAppLoadingDialog();
      await showAppResultDialog(
        success: false,
        title: 'Error',
        message: e.toString(),
        okLabel: 'Try Again',
      );
      await _retake();
    }
  }

  Future<Position?> _resolvePosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition();
  }

  /// Tolerant numeric coerce — Postgres `DECIMAL` columns surface as strings
  /// through the `pg` Node driver, so direct `as num?` casts on the JSON
  /// payload blow up with "type 'String' is not a subtype of 'num?'".
  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  bool _isNetworkError(dio_pkg.DioException e) {
    return e.type == dio_pkg.DioExceptionType.connectionError ||
        e.type == dio_pkg.DioExceptionType.connectionTimeout ||
        e.type == dio_pkg.DioExceptionType.receiveTimeout ||
        e.type == dio_pkg.DioExceptionType.sendTimeout ||
        (e.error is SocketException);
  }

  /// Reset to ready so the user can retake. Disposes the previous camera
  /// controller (now safe — capture callbacks have drained by the time the
  /// user has tapped through the error dialog) and re-opens.
  Future<void> _retake() async {
    capturedPath.value = null;
    _capturedEmbedding = null;
    _captureTriggered = false;
    stage.value = CameraStage.initializing;
    isInitialized.value = false;
    final old = cameraController;
    cameraController = null;
    if (old != null) {
      try {
        await old.dispose();
      } catch (_) {}
    }
    await _initCamera();
  }

  Future<void> _resetAfterError(String message) async {
    closeAppLoadingDialog();
    await showAppResultDialog(
      success: false,
      title: 'Error',
      message: message,
      okLabel: 'Try Again',
    );
    await _retake();
  }

  Future<void> openAppSettingsForPermission() async {
    await openAppSettings();
  }

  @override
  void onClose() {
    () async {
      try {
        await cameraController?.dispose();
      } catch (_) {}
    }();
    super.onClose();
  }
}
