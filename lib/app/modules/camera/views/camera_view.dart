import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme.dart';
import '../controllers/camera_controller.dart';

/// Thin shell page. The actual capture happens in the OS camera app via
/// image_picker (see controller). This page just shows a loading state
/// while the system camera UI is up — and the face-verification spinner
/// after a frame returns.
class CameraView extends GetView<CustomCameraController> {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          final verifying = controller.isVerifying.value;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primary),
                const SizedBox(height: 20),
                Text(
                  verifying ? 'Memverifikasi wajah…' : 'Membuka kamera…',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                if (controller.requireFace) ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Selfie wajib — pastikan wajah Anda jelas di tengah frame.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: Get.back,
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
