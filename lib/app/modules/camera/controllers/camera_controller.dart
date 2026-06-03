import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:get/get.dart';
import '../../../../main.dart';
import '../../../core/face_utils.dart';

class CustomCameraController extends GetxController {
  CameraController? cameraController;
  final isInitialized = false.obs;
  final isVerifying = false.obs;

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
    if (cameras.isEmpty) {
      Future.delayed(Duration.zero, () {
        Get.snackbar('Error', 'No cameras available on this device');
      });
      return;
    }

    // Try to find a front-facing camera, fallback to the first available
    CameraDescription? selectedCamera;
    for (var camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        selectedCamera = camera;
        break;
      }
    }
    selectedCamera ??= cameras.first;

    // Some Android devices (Xiaomi MediaTek) silently render a black preview
    // when given yuv420 format. Default format + low preset is the most
    // compatible combination. Explicit resumePreview() kicks the surface
    // texture if the platform paused it after initialize.
    final ctrl = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await ctrl.initialize();
      await ctrl.lockCaptureOrientation(DeviceOrientation.portraitUp);
      await ctrl.resumePreview();
      cameraController = ctrl;
      isInitialized.value = true;
    } catch (e) {
      await ctrl.dispose();
      Future.delayed(Duration.zero, () {
        Get.snackbar('Camera Error', 'Could not initialize camera: $e');
      });
    }
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
