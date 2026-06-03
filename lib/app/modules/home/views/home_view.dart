import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../data/services/attendance_queue_service.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildAttendanceCard(textTheme),
                const SizedBox(height: 24),
                _buildQuickActions(textTheme),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Aktivitas Terkini',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: controller.goToHistory,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Lihat semua',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRecent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: controller.goToProfile,
          child: Obx(() {
            final imageUrl =
                controller.auth.user.value?['image']?.toString();
            final name =
                controller.auth.user.value?['name']?.toString() ?? 'User';
            final initial =
                name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
            final hasImage = imageUrl != null && imageUrl.isNotEmpty;
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cardBorder, width: 2),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryLight,
                backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
                child: hasImage
                    ? null
                    : Text(
                        initial,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            );
          }),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Obx(
                () => Text(
                  controller.auth.user.value?['name']?.toString() ?? 'User',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildPendingBadge(),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: IconButton(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh,
                color: AppTheme.textSecondary, size: 20),
            tooltip: 'Refresh',
          ),
        ),
      ],
    );
  }

  Widget _buildPendingBadge() {
    if (!Get.isRegistered<AttendanceQueueService>()) {
      return const SizedBox.shrink();
    }
    final queue = Get.find<AttendanceQueueService>();
    return Obx(() {
      final count = queue.pendingCount.value;
      if (count <= 0) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 12, color: AppTheme.danger),
              const SizedBox(width: 4),
              Text(
                '$count pending',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.danger,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _attendanceStatusBadge() {
    return Obx(() {
      final hasIn = controller.checkInTime.value != null;
      final hasOut = controller.checkOutTime.value != null;
      String label;
      Color bg;
      IconData icon;
      if (!hasIn) {
        label = 'Belum Check-in';
        bg = Colors.white.withValues(alpha: 0.18);
        icon = Icons.access_time;
      } else if (!hasOut) {
        label = 'Sedang Bekerja';
        bg = Colors.white.withValues(alpha: 0.25);
        icon = Icons.circle;
      } else {
        label = 'Selesai Hari Ini';
        bg = Colors.white.withValues(alpha: 0.25);
        icon = Icons.check_circle_outline;
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 12),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAttendanceCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              _attendanceStatusBadge(),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _timeBlock("Check In", controller.checkInTime)),
              Container(
                width: 1,
                height: 44,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(child: _timeBlock("Check Out", controller.checkOutTime)),
            ],
          ),
          Obx(() {
            final loc = controller.lastLocation.value;
            if (loc == null || loc.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      loc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _timeBlock(String label, Rxn<DateTime> time) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            time.value != null
                ? DateFormat('HH:mm').format(time.value!)
                : '--:--',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _action(icon: Icons.assignment_outlined, onTap: controller.goToReports),
            _action(icon: Icons.history, onTap: controller.goToHistory),
            _action(
                icon: Icons.event_note_outlined, onTap: controller.goToPermit),
          ],
        ),
      ],
    );
  }

  Widget _action({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppTheme.primary, size: 26),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecent() {
    return Obx(() {
      if (controller.isLoading.value && controller.recent.isEmpty) {
        return Column(
          children: List.generate(3, (_) => const _RecentSkeleton()),
        );
      }
      if (controller.recent.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: const [
              Icon(Icons.history, size: 40, color: AppTheme.textHint),
              SizedBox(height: 8),
              Text(
                'Belum ada aktivitas',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Check-in di tab Camera untuk memulai',
                style: TextStyle(color: AppTheme.textHint, fontSize: 12),
              ),
            ],
          ),
        );
      }
      return Column(children: controller.recent.map(_recentTile).toList());
    });
  }

  Widget _recentTile(Map item) {
    final type = item['type']?.toString() ?? '';
    final time = DateTime.tryParse(item['serverTime']?.toString() ?? '');
    final loc = item['locationName']?.toString();
    final isIn = type == 'check_in';
    final inZone = item['isWithinZone'] == true;
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
              color: (isIn ? AppTheme.success : AppTheme.danger)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIn ? Icons.login : Icons.logout,
              color: isIn ? AppTheme.success : AppTheme.danger,
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (inZone ? AppTheme.success : AppTheme.warning)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        inZone ? 'Dalam zona' : 'Luar zona',
                        style: TextStyle(
                          color: inZone ? AppTheme.success : AppTheme.warning,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
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
                    if (loc != null && loc.isNotEmpty) ...[
                      const SizedBox(width: 8),
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentSkeleton extends StatelessWidget {
  const _RecentSkeleton();
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
