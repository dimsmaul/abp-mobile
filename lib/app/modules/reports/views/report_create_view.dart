import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme.dart';
import '../controllers/reports_controller.dart';

class ReportCreateView extends GetView<ReportsController> {
  const ReportCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(title: const Text("New Report")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _photoPicker(),
            const SizedBox(height: 20),
            const Text("Category",
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            _categorySelector(),
            const SizedBox(height: 20),
            const Text("Description",
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: controller.descriptionController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: "Describe the issue (min 10 chars)",
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            const SizedBox(height: 24),
            Obx(() => ElevatedButton(
                  onPressed:
                      controller.isSubmitting.value ? null : controller.submit,
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text("Submit Report"),
                )),
          ],
        ),
      ),
    );
  }

  Widget _photoPicker() {
    return Obx(() {
      final img = controller.image.value;
      return InkWell(
        onTap: controller.pickPhoto,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.cardBorder,
              style: img == null ? BorderStyle.solid : BorderStyle.none,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: img == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_a_photo_outlined,
                        size: 48, color: AppTheme.primary),
                    SizedBox(height: 8),
                    Text("Tap to take photo",
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ],
                )
              : Image.file(img, fit: BoxFit.cover),
        ),
      );
    });
  }

  Widget _categorySelector() {
    return Obx(() => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ReportsController.categories.map((c) {
            final selected = controller.category.value == c;
            return ChoiceChip(
              label: Text(c[0].toUpperCase() + c.substring(1)),
              selected: selected,
              onSelected: (_) => controller.category.value = c,
            );
          }).toList(),
        ));
  }
}
