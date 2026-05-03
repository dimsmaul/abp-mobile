import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
          return const Center(child: CircularProgressIndicator());
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
                Text(_label(cat),
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

  String _label(String c) => c[0].toUpperCase() + c.substring(1);

  String _dateStr(String? iso) {
    if (iso == null) return '-';
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return DateFormat('dd MMM yyyy • HH:mm').format(d);
  }

  Widget _statusBadge(String status) {
    final colors = {
      'pending': (AppTheme.warning, 'Pending'),
      'approved': (AppTheme.success, 'Approved'),
      'rejected': (AppTheme.danger, 'Rejected'),
      'need_revision': (Colors.orange, 'Need Revision'),
    };
    final (color, label) = colors[status] ?? (AppTheme.textHint, status);
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
