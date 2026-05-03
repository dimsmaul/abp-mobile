import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../controllers/reports_controller.dart';

class ReportsListView extends GetView<ReportsController> {
  const ReportsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text("My Reports"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/reports/create'),
        icon: const Icon(Icons.add),
        label: const Text("New Report"),
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.reports.isEmpty) {
                return _buildEmpty();
              }
              return RefreshIndicator(
                onRefresh: controller.fetchMyReports,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _buildItem(controller.reports[i]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = <String?>[null, 'pending', 'approved', 'rejected', 'need_revision'];
    return SizedBox(
      height: 56,
      child: Obx(() {
        final current = controller.filterStatus.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = filters[i];
            return ChoiceChip(
              label: Text(f == null ? 'All' : _statusLabel(f)),
              selected: current == f,
              onSelected: (_) => controller.setFilter(f),
            );
          },
        );
      }),
    );
  }

  Widget _buildItem(Map item) {
    final created = DateTime.tryParse(item['createdAt']?.toString() ?? '');
    final dateStr = created != null
        ? DateFormat('dd MMM yyyy • HH:mm').format(created)
        : '';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => controller.openDetail(item['id'].toString()),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _categoryIcon(item['category']?.toString() ?? 'other'),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _categoryLabel(item['category']?.toString() ?? 'other'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                _statusBadge(item['status']?.toString() ?? 'pending'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item['description']?.toString() ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Text(dateStr,
                    style: const TextStyle(
                        color: AppTheme.textHint, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.inbox_outlined, size: 56, color: AppTheme.textHint),
            SizedBox(height: 12),
            Text("No reports yet",
                style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text("Tap New Report to submit one",
                style: TextStyle(color: AppTheme.textHint)),
          ],
        ),
      ),
    );
  }

  Widget _categoryIcon(String cat) {
    final iconMap = {
      'weather': Icons.cloud_outlined,
      'technical': Icons.build_outlined,
      'progress': Icons.trending_up,
      'other': Icons.note_outlined,
    };
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconMap[cat] ?? Icons.note_outlined,
          color: AppTheme.primary, size: 20),
    );
  }

  String _categoryLabel(String c) {
    return c[0].toUpperCase() + c.substring(1);
  }

  String _statusLabel(String s) {
    return s
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
