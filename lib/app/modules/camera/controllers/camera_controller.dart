import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../main.dart';
import '../../../core/face_utils.dart';

class CustomCameraController extends GetxController {
  CameraController? cameraController;
  final isInitialized = false.obs;
  final isVerifying = false.obs;
  final permissionDenied = false.obs;

  /// When true (passed via Get.arguments['requireFace']), the captured photo
  /// is validated against an ML Kit face detector before returning. If no
  /// face is detected, capture is rejected and the user is asked to retake.
  bool get requireFace {
    final args = Get.arguments;
    if (args is Map && args['requireFace'] == true) return true;
    return false;
  }

  @override
  void onInit() {
    super.onInit();
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Explicit runtime permission gate. The camera plugin SOMETIMES requests
    // on its own, but on MIUI / Xiaomi Android 12+ that request silently
    // fails when the privacy indicator denies background access — leading
    // to a black preview without any error surfaced to Dart.
    final status = await Permission.camera.request();
    debugPrint('[camera] Permission.camera status=$status');
    if (!status.isGranted) {
      permissionDenied.value = true;
      Future.delayed(Duration.zero, () {
        Get.snackbar(
          'Izin Kamera Ditolak',
          status.isPermanentlyDenied
              ? 'Aktifkan izin kamera di Pengaturan untuk mengambil foto.'
              : 'Izin kamera dibutuhkan untuk presensi.',
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

    // Try to find a front-facing camera, fallback to the first available.
    CameraDescription? selectedCamera;
    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        selectedCamera = camera;
        break;
      }
    }
    selectedCamera ??= cameras.first;

    final ctrl = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      // PLAIN initialize() only. Any post-init reconfiguration
      // (lockCaptureOrientation, resumePreview, etc.) on camera_android_camerax
      // causes a CameraGraph teardown/recreate cycle that GCs the Pigeon
      // ProxyApi observer for the Texture, surfacing as
      // 'missing-instance-error: Observer.onChanged failed because native
      // instance was not in the instance manager' — and a black preview.
      await ctrl.initialize();
      cameraController = ctrl;
      isInitialized.value = true;
      debugPrint(
          '[camera] initialized aspect=${ctrl.value.aspectRatio} preview=${ctrl.value.previewSize}');
    } catch (e) {
      await ctrl.dispose();
      debugPrint('[camera] init error: $e');
      Future.delayed(Duration.zero, () {
        Get.snackbar('Camera Error', 'Could not initialize camera: $e');
      });
    }
  }

  Future<void> openAppSettingsForPermission() async {
    await openAppSettings();
  }

  Future<void> takePicture() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile picture = await cameraController!.takePicture();

      if (requireFace) {
        isVerifying.value = true;
        final ok = await hasFace(picture.path);
        isVerifying.value = false;
        if (!ok) {
          Get.snackbar(
            'Wajah tidak terdeteksi',
            'Pastikan wajah Anda terlihat jelas di tengah frame, lalu ambil ulang.',
            duration: const Duration(seconds: 3),
          );
          return;
        }
      }

      Get.back(result: picture.path);
    } catch (e) {
      isVerifying.value = false;
      Get.snackbar('Error', 'Failed to take picture: $e');
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}
