import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../controllers/attendance_history_controller.dart';

class AttendanceHistoryView extends StatefulWidget {
  const AttendanceHistoryView({super.key});

  @override
  State<AttendanceHistoryView> createState() => _AttendanceHistoryViewState();
}

class _AttendanceHistoryViewState extends State<AttendanceHistoryView> {
  final AttendanceHistoryController controller =
      Get.find<AttendanceHistoryController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (controller.hasMore.value && !controller.isLoadingMore.value) {
        controller.fetchMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Riwayat Presensi'),
        backgroundColor: AppTheme.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          final isInitialLoading =
              controller.isLoading.value && controller.items.isEmpty;

          if (!isInitialLoading && controller.items.isEmpty) {
            return LayoutBuilder(
              builder: (ctx, bc) => RefreshIndicator(
                onRefresh: () => controller.fetch(reset: true),
                color: AppTheme.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: bc.maxHeight),
                    child: const Center(child: _Empty()),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.fetch(reset: true),
            color: AppTheme.primary,
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                if (isInitialLoading)
                  ...List.generate(3, (_) => const _Skeleton())
                else ...[
                  ...controller.items.map(_tile),
                  if (controller.isLoadingMore.value)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Memuat lebih banyak…',
                              style: TextStyle(
                                color: AppTheme.textHint,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (!controller.hasMore.value)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Tidak ada riwayat lagi',
                          style: TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _tile(Map item) {
    final type = item['type']?.toString() ?? '';
    final time =
        DateTime.tryParse(item['serverTime']?.toString() ?? '')?.toLocal();
    final loc = item['locationName']?.toString();
    final isIn = type == 'check_in';
    final inZone = item['isWithinZone'] == true;
    final iconColor = isIn ? AppTheme.success : AppTheme.danger;

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
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIn ? Icons.login : Icons.logout,
              color: iconColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isIn ? 'Check-in' : 'Check-out',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _zonePill(inZone),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (time != null) ...[
                      const Icon(Icons.schedule,
                          size: 12, color: AppTheme.textHint),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('dd MMM • HH:mm').format(time),
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                if (loc != null && loc.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 12, color: AppTheme.textHint),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          loc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _zonePill(bool inZone) {
    final c = inZone ? AppTheme.success : AppTheme.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        inZone ? 'Dalam zona' : 'Luar zona',
        style: TextStyle(
          color: c,
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
            child: const Icon(Icons.inbox_outlined,
                color: AppTheme.primary, size: 24),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada presensi',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Check-in lewat tab Camera untuk memulai',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textHint, fontSize: 12),
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
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 160,
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
