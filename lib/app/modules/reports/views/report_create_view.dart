import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../controllers/reports_controller.dart';

class ReportCreateView extends GetView<ReportsController> {
  const ReportCreateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('New Report'),
        backgroundColor: AppTheme.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
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
                    Text('Tap to take photo',
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
    return Obx(() {
      // Touch the observable inside the Obx scope so it actually subscribes
      // to changes. Nested builders (LayoutBuilder etc) run later, outside
      // the tracking scope, which is what triggered the "improper use of
      // GetX" exception when we accessed `.value` only from inside them.
      final currentCategory = controller.category.value;
      return LayoutBuilder(builder: (ctx, constraints) {
        // Two-up grid sized to fit the available width with an 8px gap.
        final cardWidth = (constraints.maxWidth - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ReportsController.categories.map((c) {
            final selected = currentCategory == c;
            final color = _categoryColor(c);
            return SizedBox(
              width: cardWidth,
              child: _CategoryCard(
                label: reportCategoryLabel(c),
                icon: _categoryIcon(c),
                color: color,
                selected: selected,
                onTap: () => controller.category.value = c,
              ),
            );
          }).toList(),
        );
      });
    });
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'weather':
        return Icons.cloud_outlined;
      case 'technical':
        return Icons.build_outlined;
      case 'progress':
        return Icons.trending_up;
      default:
        return Icons.note_outlined;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'weather':
        return const Color(0xFF3B82F6); // blue
      case 'technical':
        return AppTheme.warning;
      case 'progress':
        return AppTheme.primary;
      default:
        return AppTheme.textHint;
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.10)
                : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : AppTheme.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // Mirrors the list card's icon badge (40×40 tinted circle).
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? color : AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
