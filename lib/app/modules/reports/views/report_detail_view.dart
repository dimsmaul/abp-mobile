import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../controllers/reports_controller.dart';

class ReportDetailView extends GetView<ReportsController> {
  const ReportDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(title: const Text("Report Detail")),
      body: Obx(() {
        if (controller.isDetailLoading.value && controller.detail.value == null) {
          return const _DetailSkeleton();
        }
        final d = controller.detail.value;
        if (d == null) return const SizedBox.shrink();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _photo(d['photoUrl']?.toString()),
              const SizedBox(height: 20),
              _statusCard(d),
              const SizedBox(height: 16),
              _infoSection(d),
              const SizedBox(height: 16),
              _validationSection(d),
            ],
          ),
        );
      }),
    );
  }

  Widget _photo(String? url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: url == null || url.isEmpty
            ? Container(
                color: AppTheme.cardBorder,
                child: const Icon(Icons.image_not_supported,
                    color: AppTheme.textHint, size: 56),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.cardBorder,
                  child: const Icon(Icons.broken_image,
                      color: AppTheme.textHint, size: 56),
                ),
              ),
      ),
    );
  }

  Widget _statusCard(Map d) {
    final status = d['status']?.toString() ?? 'pending';
    final cat = d['category']?.toString() ?? 'other';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reportCategoryLabel(cat),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 18)),
                const SizedBox(height: 4),
                Text(_dateStr(d['createdAt']?.toString()),
                    style: const TextStyle(color: AppTheme.textHint)),
              ],
            ),
          ),
          _statusBadge(status),
        ],
      ),
    );
  }

  Widget _infoSection(Map d) {
    return _section(
      title: "Description",
      child: Text(d['description']?.toString() ?? '-',
          style: const TextStyle(fontSize: 15, height: 1.5)),
    );
  }

  Widget _validationSection(Map d) {
    final v = d['validation'];
    if (v == null || v is! Map) {
      return _section(
        title: "Validation",
        child: const Text("Awaiting manager review",
            style: TextStyle(color: AppTheme.textHint)),
      );
    }
    return _section(
      title: "Validation",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (v['validatedAt'] != null)
            Text(_dateStr(v['validatedAt'].toString()),
                style: const TextStyle(color: AppTheme.textHint)),
          if (v['notes'] != null) ...[
            const SizedBox(height: 8),
            Text(v['notes'].toString(),
                style: const TextStyle(fontSize: 14, height: 1.4)),
          ],
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  fontSize: 13)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  String _dateStr(String? iso) {
    if (iso == null) return '-';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('dd MMM yyyy • HH:mm').format(d);
  }

  Widget _statusBadge(String status) {
    final color = reportStatusColor(status);
    final label = reportStatusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Loading Skeleton ────────────────────────────────────────
class _DetailSkeleton extends StatefulWidget {
  const _DetailSkeleton();

  @override
  State<_DetailSkeleton> createState() => _DetailSkeletonState();
}

class _DetailSkeletonState extends State<_DetailSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final opacity = 0.4 + (_ctrl.value * 0.4);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _box(opacity, height: 240, radius: 16),
              const SizedBox(height: 20),
              _card(opacity, [
                _box(opacity, height: 18, widthFactor: 0.4),
                const SizedBox(height: 8),
                _box(opacity, height: 12, widthFactor: 0.6),
              ]),
              const SizedBox(height: 16),
              _card(opacity, [
                _box(opacity, height: 12, widthFactor: 0.3),
                const SizedBox(height: 12),
                _box(opacity, height: 12, widthFactor: 0.9),
                const SizedBox(height: 6),
                _box(opacity, height: 12, widthFactor: 0.8),
                const SizedBox(height: 6),
                _box(opacity, height: 12, widthFactor: 0.5),
              ]),
              const SizedBox(height: 16),
              _card(opacity, [
                _box(opacity, height: 12, widthFactor: 0.3),
                const SizedBox(height: 12),
                _box(opacity, height: 12, widthFactor: 0.7),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _box(
    double opacity, {
    required double height,
    double widthFactor = 1.0,
    double radius = 8,
  }) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.cardBorder.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _card(double opacity, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
