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
          if (controller.permissionDenied.value) {
            return _permissionDeniedState(context);
          }
          if (!controller.isInitialized.value ||
              controller.cameraController == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          return Stack(
            children: [
              // Pattern from the camera package docs: give the Texture an
              // explicit width/height (sensor preview size, swapped for
              // portrait so the rotated frame still maps 1:1), then let
              // FittedBox cover the screen. Plain Center collapses the
              // Texture to 0x0 because CameraPreview has no intrinsic size.
              Positioned.fill(
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width:
                          controller.cameraController!.value.previewSize?.height ?? 480,
                      height:
                          controller.cameraController!.value.previewSize?.width ?? 720,
                      child: CameraPreview(controller.cameraController!),
                    ),
                  ),
                ),
              ),

              // Back button
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 30),
                  onPressed: () => Get.back(),
                ),
              ),

              // Face-verification overlay
              Obx(() {
                if (!controller.isVerifying.value) {
                  return const SizedBox.shrink();
                }
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

              if (controller.requireFace)
                Positioned(
                  top: 16,
                  left: 64,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
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

              // Capture button
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
                            border:
                                Border.all(color: Colors.white, width: 4),
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

  Widget _permissionDeniedState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined,
              color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Izin Kamera Diperlukan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aktifkan izin kamera di Pengaturan agar bisa mengambil selfie untuk presensi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.openAppSettingsForPermission,
            icon: const Icon(Icons.settings),
            label: const Text('Buka Pengaturan'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: Get.back,
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
