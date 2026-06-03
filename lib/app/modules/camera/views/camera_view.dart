import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../controllers/camera_controller.dart';
import '../../../core/theme.dart';

class CameraView extends GetView<CustomCameraController> {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          if (!controller.isInitialized.value || controller.cameraController == null) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          return Stack(
            children: [
              // Camera preview: raw CameraPreview at natural size, centred.
              // The plugin owns its aspect ratio and surface texture; any
              // outer Transform/scale wrapper on Xiaomi MediaTek breaks
              // the GL surface attach and we get a black window.
              Positioned.fill(
                child: Center(
                  child: CameraPreview(controller.cameraController!),
                ),
              ),
              // Top Bar (Back button)
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                  onPressed: () => Get.back(),
                ),
              ),

              // Face-check overlay (only when requireFace + verifying)
              Obx(() {
                if (!controller.isVerifying.value) return const SizedBox.shrink();
                return Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Memverifikasi wajah…',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }),

              // Hint banner when face required
              if (controller.requireFace)
                Positioned(
                  top: 16,
                  left: 64,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Pastikan wajah Anda terlihat jelas di tengah frame.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),

              // Bottom Control Bar
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Obx(() {
                    final busy = controller.isVerifying.value;
                    return GestureDetector(
                      onTap: busy ? null : controller.takePicture,
                      child: Opacity(
                        opacity: busy ? 0.5 : 1.0,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
