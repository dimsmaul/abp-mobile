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
                onTap: () => _showAvatarSheet(context),
                child: Obx(() {
                  final user = controller.auth.user.value;
                  final imageUrl = user?['image']?.toString();
                  final name = user?['name']?.toString() ?? 'User';
                  final initial =
                      name.isNotEmpty ? name.characters.first.toUpperCase() : '?';
                  final hasImage = imageUrl != null && imageUrl.isNotEmpty;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppTheme.primaryLight,
                        backgroundImage:
                            hasImage ? NetworkImage(imageUrl) : null,
                        child: hasImage
                            ? null
                            : Text(
                                initial,
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                      if (controller.isUploadingAvatar.value)
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
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
                        title: "Edit Profile",
                        onTap: () => _showEditProfileDialog(context)),
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

  void _showAvatarSheet(BuildContext context) {
    if (controller.isUploadingAvatar.value) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppTheme.primary),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.of(ctx).pop();
                controller.pickAndUploadProfilePicture();
              },
            ),
            const Divider(height: 1, color: AppTheme.cardBorder),
            ListTile(
              leading: const Icon(Icons.close, color: AppTheme.textHint),
              title: const Text('Batal'),
              onTap: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final user = controller.auth.user.value;
    final nameCtl =
        TextEditingController(text: user?['name']?.toString() ?? '');
    final deptCtl =
        TextEditingController(text: user?['department']?.toString() ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deptCtl,
              decoration: const InputDecoration(
                labelText: 'Departemen',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          Obx(() => ElevatedButton(
                onPressed: controller.isSavingProfile.value
                    ? null
                    : () async {
                        final current = controller.auth.user.value;
                        final origName = current?['name']?.toString() ?? '';
                        final origDept =
                            current?['department']?.toString() ?? '';
                        final newName = nameCtl.text.trim();
                        final newDept = deptCtl.text.trim();

                        final namePayload =
                            newName != origName && newName.isNotEmpty
                                ? newName
                                : null;
                        final deptPayload =
                            newDept != origDept ? newDept : null;

                        if (namePayload == null && deptPayload == null) {
                          Navigator.of(ctx).pop();
                          return;
                        }

                        final ok = await controller.saveProfile(
                          name: namePayload,
                          department: deptPayload,
                        );
                        if (ok && ctx.mounted) Navigator.of(ctx).pop();
                      },
                child: controller.isSavingProfile.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan'),
              )),
        ],
      ),
    );
  }
}
