import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../controllers/reports_controller.dart';

class ReportsListView extends GetView<ReportsController> {
  const ReportsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Laporan Saya'),
        backgroundColor: AppTheme.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/reports/create'),
        icon: const Icon(Icons.add),
        label: const Text('Buat Laporan'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.fetchMyReports,
          color: AppTheme.primary,
          child: Obx(() {
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _filterChips()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                  sliver: _buildBody(),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _filterChips() {
    final filters = <String?>[
      null,
      'pending',
      'approved',
      'need_revision',
      'rejected',
    ];
    return SizedBox(
      height: 48,
      child: Obx(() {
        final current = controller.filterStatus.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final f = filters[i];
            final selected = current == f;
            final label = f == null ? 'Semua' : reportStatusLabel(f);
            return _filterChip(
              label: label,
              selected: selected,
              onTap: () => controller.setFilter(f),
            );
          },
        );
      }),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppTheme.primary : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.cardBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (controller.isLoading.value && controller.reports.isEmpty) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, __) => const _Skeleton(),
          childCount: 3,
        ),
      );
    }
    if (controller.reports.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: const Center(child: _Empty()),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _item(controller.reports[i]),
        childCount: controller.reports.length,
      ),
    );
  }

  Widget _item(Map item) {
    final created = DateTime.tryParse(item['createdAt']?.toString() ?? '');
    final dateStr = created != null
        ? DateFormat('dd MMM yyyy • HH:mm').format(created)
        : '';
    final category = item['category']?.toString() ?? 'other';
    final status = item['status']?.toString() ?? 'pending';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => controller.openDetail(item['id'].toString()),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _categoryIcon(category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reportCategoryLabel(category),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 12, color: AppTheme.textHint),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                dateStr,
                                style: const TextStyle(
                                  color: AppTheme.textHint,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item['description']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
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
    final colorMap = {
      'weather': const Color(0xFF3B82F6), // blue
      'technical': AppTheme.warning,
      'progress': AppTheme.primary,
      'other': AppTheme.textHint,
    };
    final color = colorMap[cat] ?? AppTheme.textHint;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconMap[cat] ?? Icons.note_outlined,
        color: color,
        size: 18,
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = reportStatusColor(status);
    final label = reportStatusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.description_outlined,
                color: AppTheme.primary, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada laporan',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ajukan laporan lapangan pertama Anda',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textHint, fontSize: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => Get.toNamed('/reports/create'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Buat Laporan'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE2E8F0),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 180,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
