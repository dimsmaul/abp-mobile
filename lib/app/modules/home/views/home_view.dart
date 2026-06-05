import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/avatar_bubble.dart';
import '../../../core/theme.dart';
import '../../../data/services/attendance_queue_service.dart';
import '../../../data/services/notification_service.dart';
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
                _buildAnnouncementsSection(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity',
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
                        'See all',
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
    if (h < 11) return 'Good morning';
    if (h < 15) return 'Good afternoon';
    if (h < 19) return 'Good evening';
    return 'Good night';
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
            return AvatarBubble(
              imageUrl: imageUrl,
              name: name,
              radius: 24,
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: AppTheme.primary,
              fontSize: 18,
              border: Border.all(color: AppTheme.cardBorder, width: 2),
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
        _buildBellIcon(),
      ],
    );
  }

  Widget _buildBellIcon() {
    final notif = Get.isRegistered<NotificationService>()
        ? Get.find<NotificationService>()
        : null;
    final bell = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: IconButton(
        onPressed: () {
          notif?.resetUnread();
          controller.goToAnnouncements();
        },
        icon: const Icon(
          Icons.notifications_none_rounded,
          color: AppTheme.textSecondary,
          size: 20,
        ),
        tooltip: 'Announcements',
      ),
    );
    if (notif == null) return bell;
    return Obx(() {
      final hasUnread = notif.unreadCount.value > 0;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          bell,
          if (hasUnread)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
              ),
            ),
        ],
      );
    });
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
                '$count pending sync',
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
        label = 'Not Checked-in';
        bg = Colors.white.withValues(alpha: 0.18);
        icon = Icons.access_time;
      } else if (!hasOut) {
        label = 'Working';
        bg = Colors.white.withValues(alpha: 0.25);
        icon = Icons.circle;
      } else {
        label = 'Done for today';
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
    // 2×3 grid — row 1: loan / overtime / reimbursement, row 2: leave /
    // reports / history. Each request action navigates to its own
    // category-locked route so the user lands directly on the right list +
    // pre-filled form.
    return Column(
      children: [
        Row(
          children: [
            _action(
              icon: Icons.savings_outlined,
              label: 'Loan',
              tint: AppTheme.primary,
              onTap: controller.goToLoan,
            ),
            const SizedBox(width: 12),
            _action(
              icon: Icons.schedule_outlined,
              label: 'Overtime',
              tint: AppTheme.warning,
              onTap: controller.goToOvertime,
            ),
            const SizedBox(width: 12),
            _action(
              icon: Icons.receipt_long_outlined,
              label: 'Reimburse',
              tint: AppTheme.success,
              onTap: controller.goToReimbursement,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _action(
              icon: Icons.event_available_outlined,
              label: 'Leave',
              tint: AppTheme.danger,
              onTap: controller.goToLeave,
            ),
            const SizedBox(width: 12),
            _action(
              icon: Icons.assignment_outlined,
              label: 'Reports',
              tint: AppTheme.primary,
              onTap: controller.goToReports,
            ),
            const SizedBox(width: 12),
            _action(
              icon: Icons.history_rounded,
              label: 'History',
              tint: AppTheme.success,
              onTap: controller.goToHistory,
            ),
          ],
        ),
      ],
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required Color tint,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: tint, size: 22),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Announcements',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: controller.goToAnnouncements,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See all',
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
        Obx(() {
          final items = controller.announcements;
          if (items.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Column(
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 32, color: AppTheme.textHint),
                  SizedBox(height: 6),
                  Text(
                    'No announcements yet',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }
          // BE already sorts pinned-first + publishedAt desc. Slice to 3.
          final top = items.take(3).toList();
          return Column(
            children: top.map(_announcementCard).toList(),
          );
        }),
      ],
    );
  }

  Widget _announcementCard(Map item) {
    final id = item['id']?.toString() ?? '';
    final title = item['title']?.toString() ?? '';
    final body = item['body']?.toString() ?? '';
    final priority = item['priority']?.toString() ?? 'normal';
    final isPinned = item['isPinned'] == true;
    final pColor = priority == 'high'
        ? AppTheme.danger
        : priority == 'low'
            ? AppTheme.textHint
            : AppTheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => controller.openAnnouncementDetail(id),
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
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: pColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (isPinned)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.push_pin,
                          size: 14, color: AppTheme.warning),
                    ),
                ],
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
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
                'No activity yet',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Check in via the Presence tab to start',
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
    final time =
        DateTime.tryParse(item['serverTime']?.toString() ?? '')?.toLocal();
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
                        inZone ? 'In zone' : 'Out of zone',
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
