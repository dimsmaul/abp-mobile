import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../../../../main.dart';

class CustomCameraController extends GetxController {
  CameraController? cameraController;
  final isInitialized = false.obs;

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

    cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await cameraController!.initialize();
      isInitialized.value = true;
    } catch (e) {
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
      // Return the file path back to the previous screen (Attendance)
      Get.back(result: picture.path);
    } catch (e) {
      Get.snackbar('Error', 'Failed to take picture: $e');
    }
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}
