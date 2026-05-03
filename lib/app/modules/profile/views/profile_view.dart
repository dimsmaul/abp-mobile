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
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Center(
              child: GestureDetector(
                onTap: controller.pickAndUploadProfilePicture,
                child: Obx(() => CircleAvatar(
                      radius: 52,
                      backgroundColor: AppTheme.primaryLight,
                      child: controller.isUploading.value
                          ? const CircularProgressIndicator(
                              color: AppTheme.primary)
                          : const Icon(Icons.person,
                              size: 56, color: AppTheme.primary),
                    )),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => Text(
                  controller.auth.user.value?['name']?.toString() ?? "User",
                  style: textTheme.titleLarge,
                )),
            const SizedBox(height: 4),
            Obx(() => Text(
                  controller.auth.user.value?['email']?.toString() ?? "",
                  style: textTheme.bodyMedium,
                )),
            const SizedBox(height: 4),
            Obx(() {
              final role =
                  controller.auth.user.value?['role']?.toString() ?? '';
              if (role.isEmpty) return const SizedBox.shrink();
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(role.toUpperCase(),
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              );
            }),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _menu(
                        icon: Icons.person_outline,
                        title: "Update Profile",
                        onTap: () {}),
                    const Divider(height: 1, color: AppTheme.cardBorder),
                    _menu(
                        icon: Icons.lock_outline,
                        title: "Change Password",
                        onTap: () {}),
                    const Divider(height: 1, color: AppTheme.cardBorder),
                    _menu(
                        icon: Icons.assignment_outlined,
                        title: "My Reports",
                        onTap: () => Get.toNamed('/reports')),
                    const Divider(height: 1, color: AppTheme.cardBorder),
                    _menu(
                        icon: Icons.history,
                        title: "Attendance History",
                        onTap: () => Get.toNamed('/attendance-history')),
                    const Divider(height: 1, color: AppTheme.cardBorder),
                    _menu(
                      icon: Icons.logout,
                      title: "Sign Out",
                      textColor: AppTheme.danger,
                      iconColor: AppTheme.danger,
                      onTap: controller.logout,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menu({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = AppTheme.textPrimary,
    Color iconColor = AppTheme.primary,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title,
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.w500, fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textHint),
      onTap: onTap,
    );
  }
}
