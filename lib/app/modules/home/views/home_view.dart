import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(textTheme),
              const SizedBox(height: 32),
              _buildAttendanceCard(textTheme),
              const SizedBox(height: 32),
              Text("Quick Actions", style: textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello,", style: textTheme.bodyMedium),
            Obx(() => Text(
                  controller.user.value?['name'] ?? "User",
                  style: textTheme.headlineMedium,
                )),
          ],
        ),
        GestureDetector(
          onTap: controller.goToProfile,
          child: const CircleAvatar(
            backgroundColor: AppTheme.cardBg,
            child: Icon(Icons.person, color: AppTheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Attendance Today",
              style: textTheme.bodyMedium?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Text("You haven't checked in yet.",
              style: textTheme.titleMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => controller.goToAttendance('check_in'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                  ),
                  child: const Text("Check In"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => controller.goToAttendance('check_out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: const Text("Check Out"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMenuCard(Icons.assignment_outlined, "Permit\nRequest", controller.goToPermit),
        _buildMenuCard(Icons.history_outlined, "History", () {}),
        _buildMenuCard(Icons.map_outlined, "Offices", () {}),
        _buildMenuCard(Icons.settings_outlined, "Settings", () {}),
      ],
    );
  }

  Widget _buildMenuCard(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppTheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
