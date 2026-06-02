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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(textTheme),
                const SizedBox(height: 24),
                _buildAttendanceCard(textTheme),
                const SizedBox(height: 28),
                _buildQuickActions(textTheme),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Recent Attendance", style: textTheme.titleMedium),
                    TextButton(
                      onPressed: controller.goToHistory,
                      child: const Text("See all"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRecent(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Row(
      children: [
        GestureDetector(
          onTap: controller.goToProfile,
          child: const CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primaryLight,
            child: Icon(Icons.person, color: AppTheme.primary, size: 28),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome back",
                style: textTheme.bodySmall?.copyWith(color: AppTheme.textHint),
              ),
              Obx(
                () => Text(
                  controller.user?['name']?.toString() ?? "User",
                  style: textTheme.titleMedium,
                ),
              ),
              _buildPendingBadge(),
            ],
          ),
        ),
        IconButton(
          onPressed: controller.refresh,
          icon: const Icon(Icons.refresh, color: AppTheme.textSecondary),
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
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, dd MMM yyyy').format(DateTime.now()),
                style: textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _timeBlock("Check In", controller.checkInTime)),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(child: _timeBlock("Check Out", controller.checkOutTime)),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            final loc = controller.lastLocation.value;
            if (loc == null || loc.isEmpty) return const SizedBox.shrink();
            return Row(
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
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
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
        Text("Quick Actions", style: textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            _action(
              icon: Icons.assignment_outlined,
              label: "Reports",
              onTap: controller.goToReports,
            ),
            _action(
              icon: Icons.history,
              label: "History",
              onTap: controller.goToHistory,
            ),
            _action(
              icon: Icons.person_outline,
              label: "Profile",
              onTap: controller.goToProfile,
            ),
          ],
        ),
      ],
    );
  }

  Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primary, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecent() {
    return Obx(() {
      if (controller.isLoading.value && controller.recent.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (controller.recent.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: const [
                Icon(Icons.history, size: 40, color: AppTheme.textHint),
                SizedBox(height: 8),
                Text(
                  "No recent activity",
                  style: TextStyle(color: AppTheme.textHint),
                ),
              ],
            ),
          ),
        );
      }
      return Column(children: controller.recent.map(_recentTile).toList());
    });
  }

  Widget _recentTile(Map item) {
    final type = item['type']?.toString() ?? '';
    final time = DateTime.tryParse(item['serverTime']?.toString() ?? '');
    final isIn = type == 'check_in';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: (isIn ? AppTheme.success : AppTheme.danger)
                .withValues(alpha: 0.12),
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
                Text(
                  isIn ? 'Check In' : 'Check Out',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (time != null)
                  Text(
                    DateFormat('dd MMM • HH:mm').format(time),
                    style: const TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (item['isWithinZone'] == true)
            const Icon(Icons.verified, color: AppTheme.success, size: 18),
        ],
      ),
    );
  }
}
