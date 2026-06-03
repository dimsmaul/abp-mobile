import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/face_utils.dart';

/// Camera flow now uses the system camera intent via image_picker rather than
/// a live CameraPreview widget. Reason: Flutter's `camera` plugin (CameraX
/// backend) consistently rendered a black preview on Xiaomi / MIUI devices
/// — the surface initialised, frames flowed, but the GL texture never
/// attached. The native camera UI is faster, supports the front-camera
/// preference, and bypasses the OEM-specific Flutter texture bug entirely.
///
/// Post-capture, the ML Kit face check still runs when `requireFace=true`,
/// so the anti-spoof gate is preserved.
class CustomCameraController extends GetxController {
  final isVerifying = false.obs;
  final didLaunch = false.obs;

  /// When true (passed via `Get.arguments['requireFace']`), the captured
  /// photo is validated against an ML Kit face detector before returning.
  bool get requireFace {
    final args = Get.arguments;
    if (args is Map && args['requireFace'] == true) return true;
    return false;
  }

  @override
  void onReady() {
    super.onReady();
    // Auto-launch the system camera the moment the route shows.
    _capture();
  }

  Future<void> _capture() async {
    if (didLaunch.value) return;
    didLaunch.value = true;
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1920,
        imageQuality: 88,
      );
      if (picked == null) {
        Get.back();
        return;
      }
      if (requireFace) {
        isVerifying.value = true;
        final ok = await hasFace(picked.path);
        isVerifying.value = false;
        if (!ok) {
          Get.snackbar(
            'Wajah tidak terdeteksi',
            'Pastikan wajah terlihat jelas, lalu ambil ulang.',
            duration: const Duration(seconds: 3),
          );
          // Re-open the camera so user can retake immediately.
          didLaunch.value = false;
          await Future.delayed(const Duration(milliseconds: 250));
          _capture();
          return;
        }
      }
      Get.back(result: picked.path);
    } catch (e) {
      isVerifying.value = false;
      Get.snackbar('Camera Error', 'Gagal membuka kamera: $e');
      Get.back();
    }
  }

  /// Kept for backwards compatibility with the old custom UI. Wires to the
  /// same capture path so any caller that still calls `takePicture()`
  /// continues to work.
  Future<void> takePicture() async {
    didLaunch.value = false;
    await _capture();
  }
}
