import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.cardBg,
              child: Icon(Icons.person, size: 60, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            Obx(() => Text(
                  controller.user.value?['name'] ?? "User Name",
                  style: textTheme.headlineMedium,
                )),
            const SizedBox(height: 8),
            Obx(() => Text(
                  controller.user.value?['email'] ?? "email@example.com",
                  style: textTheme.bodyLarge
                      ?.copyWith(color: AppTheme.textSecondary),
                )),
            const SizedBox(height: 40),
            _ProfileInfoTile(
              icon: Icons.work_outline,
              label: "Department",
              value: controller.user.value?['department'] ?? "Not Assigned",
            ),
            _ProfileInfoTile(
              icon: Icons.badge_outlined,
              label: "Role",
              value: controller.user.value?['role']?.toString().toUpperCase() ??
                  "EMPLOYEE",
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: controller.logout,
              child: const Text("Sign Out"),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile Info Tile ──
class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textHint, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
