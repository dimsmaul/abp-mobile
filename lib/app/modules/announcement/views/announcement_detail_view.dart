import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../controllers/announcement_controller.dart';

class AnnouncementDetailView extends GetView<AnnouncementController> {
  const AnnouncementDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(title: const Text('Detail Pengumuman')),
      body: Obx(() {
        if (controller.isDetailLoading.value && controller.detail.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final d = controller.detail.value;
        if (d == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Pengumuman tidak ditemukan',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          );
        }
        return _buildBody(d);
      }),
    );
  }

  Widget _buildBody(Map d) {
    final title = d['title']?.toString() ?? '';
    final body = d['body']?.toString() ?? '';
    final priority = d['priority']?.toString() ?? 'normal';
    final isPinned = d['isPinned'] == true;
    final publisher = (d['publishedBy'] is Map)
        ? (d['publishedBy']['name']?.toString() ?? '—')
        : '—';
    final published = DateTime.tryParse(d['publishedAt']?.toString() ?? '');
    final expires = DateTime.tryParse(d['expiresAt']?.toString() ?? '');

    final pColor = _priorityColor(priority);
    final pLabel = _priorityLabel(priority);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pLabel,
                    style: TextStyle(
                      color: pColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isPinned)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.push_pin, size: 12, color: AppTheme.warning),
                        SizedBox(width: 4),
                        Text(
                          'Disematkan',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            _meta('Dipublikasi oleh', publisher),
            const SizedBox(height: 6),
            _meta(
              'Tanggal terbit',
              published != null
                  ? DateFormat('dd MMM yyyy • HH:mm').format(published)
                  : '—',
            ),
            if (expires != null) ...[
              const SizedBox(height: 6),
              _meta(
                'Berakhir',
                DateFormat('dd MMM yyyy').format(expires),
              ),
            ],
            const SizedBox(height: 18),
            const Divider(color: AppTheme.cardBorder, height: 1),
            const SizedBox(height: 18),
            Text(
              body,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textHint, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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

  String _priorityLabel(String p) {
    switch (p) {
      case 'high':
        return 'TINGGI';
      case 'low':
        return 'RENDAH';
      default:
        return 'NORMAL';
    }
  }
}
