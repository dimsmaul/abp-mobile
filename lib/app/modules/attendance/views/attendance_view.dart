import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme.dart';
import '../controllers/attendance_controller.dart';

class AttendanceView extends GetView<AttendanceController> {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final String type = Get.arguments ?? 'check_in';
    final String title = type == 'check_in' ? 'Check In' : 'Check Out';
    final Color actionColor =
        type == 'check_in' ? AppTheme.success : AppTheme.danger;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(child: _buildCameraPreview()),
            const SizedBox(height: 24),
            _buildLocationInfo(),
            const SizedBox(height: 32),
            _buildSubmitButton(title, type, actionColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Obx(() {
      final hasImage = controller.image.value != null;
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.cardBorder),
          image: hasImage
              ? DecorationImage(
                  image: FileImage(controller.image.value!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasImage
            ? Stack(
                children: [
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: controller.pickImage,
                      child: const Icon(Icons.refresh),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      size: 64, color: AppTheme.textHint),
                  const SizedBox(height: 16),
                  Text("No Image Captured",
                      style: TextStyle(
                          color: AppTheme.textHint, fontSize: 18)),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: controller.pickImage,
                    child: const Text("Take Selfie"),
                  ),
                ],
              ),
      );
    });
  }

  Widget _buildLocationInfo() {
    return Obx(() => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Current Location",
                        style:
                            TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    Text(
                      controller.currentPosition.value != null
                          ? "${controller.currentPosition.value!.latitude.toStringAsFixed(6)}, ${controller.currentPosition.value!.longitude.toStringAsFixed(6)}"
                          : "Determining location...",
                      style: const TextStyle(
                          color: AppTheme.textPrimary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildSubmitButton(String title, String type, Color color) {
    return Obx(() => ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : () => controller.submitAttendance(type),
          style: ElevatedButton.styleFrom(backgroundColor: color),
          child: controller.isLoading.value
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : Text("Submit $title"),
        ));
  }
}
