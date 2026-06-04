import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../controllers/announcement_controller.dart';

class AnnouncementListView extends GetView<AnnouncementController> {
  const AnnouncementListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Pengumuman'),
        backgroundColor: AppTheme.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.announcements.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.announcements.isEmpty) {
          return _buildEmpty();
        }
        return RefreshIndicator(
          onRefresh: () => controller.fetchAnnouncements(reset: true),
          color: AppTheme.primary,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
                  !controller.isLoadingMore.value &&
                  controller.hasMore.value) {
                controller.fetchAnnouncements();
              }
              return false;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: controller.announcements.length +
                  (controller.hasMore.value ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                if (i >= controller.announcements.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _buildItem(controller.announcements[i]);
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.campaign_outlined, size: 56, color: AppTheme.textHint),
            SizedBox(height: 12),
            Text(
              'Belum ada pengumuman',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(Map item) {
    final id = item['id']?.toString() ?? '';
    final title = item['title']?.toString() ?? '';
    final body = item['body']?.toString() ?? '';
    final priority = item['priority']?.toString() ?? 'normal';
    final isPinned = item['isPinned'] == true;
    final publisher = (item['publishedBy'] is Map)
        ? (item['publishedBy']['name']?.toString() ?? '')
        : '';
    final published = DateTime.tryParse(item['publishedAt']?.toString() ?? '');

    final pColor = _priorityColor(priority);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => controller.openDetail(id),
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
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: pColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (isPinned)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.push_pin, size: 16, color: AppTheme.warning),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 12, color: AppTheme.textHint),
                const SizedBox(width: 4),
                Text(
                  published != null
                      ? DateFormat('dd MMM yyyy').format(published)
                      : '',
                  style: const TextStyle(
                      color: AppTheme.textHint, fontSize: 11),
                ),
                if (publisher.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.person_outline,
                      size: 12, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      publisher,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textHint, fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'high':
        return AppTheme.danger;
      case 'low':
        return AppTheme.textHint;
      default:
        return AppTheme.primary;
    }
  }
}
