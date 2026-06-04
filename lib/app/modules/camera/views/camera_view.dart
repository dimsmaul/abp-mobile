import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme.dart';
import '../controllers/camera_controller.dart';

class CameraView extends GetView<CustomCameraController> {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Block the system back gesture while the captured photo is being
      // processed so the user can't cancel an in-flight check-in.
      final canPop = controller.stage.value != CameraStage.captured;
      return PopScope(
        canPop: canPop,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(child: _body()),
        ),
      );
    });
  }

  Widget _body() {
    if (controller.permissionDenied.value) {
      return _permissionDeniedState();
    }

    final path = controller.capturedPath.value;
    if (path != null) {
      return _capturedLayer(path);
    }

    final ctrl = controller.cameraController;
    if (!controller.isInitialized.value || ctrl == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: ctrl.value.previewSize?.height ?? 480,
                height: ctrl.value.previewSize?.width ?? 720,
                child: CameraPreview(ctrl),
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
            onPressed: () => Get.back(),
          ),
        ),
        _shutter(),
      ],
    );
  }

  Widget _capturedLayer(String path) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
        // Subtle scrim so any themed dialog on top reads with high contrast.
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.15)),
        ),
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Photo locked, processing...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        // MIUI's "Roboto" replacement can ship without the
                        // full Latin glyph table — fall back to system sans
                        // serifs so the text never renders as tofu boxes.
                        fontFamilyFallback: [
                          'Roboto',
                          'sans-serif',
                          'sans-serif-medium',
                          'Arial',
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shutter() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Obx(() {
          final busy = controller.stage.value == CameraStage.capturing;
          return GestureDetector(
            onTap: busy ? null : controller.takePictureManual,
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
    );
  }

  Widget _permissionDeniedState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.no_photography_outlined,
              color: Colors.white, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Camera Permission Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enable the camera permission in Settings so we can take a selfie for attendance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.openAppSettingsForPermission,
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: Get.back,
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
