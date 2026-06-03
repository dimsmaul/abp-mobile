import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/avatar_bubble.dart';
import '../../../core/theme.dart';
import '../../../routes/app_pages.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header(controller: controller)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _SectionLabel('Akun'),
                _Card(
                  children: [
                    _Tile(
                      icon: Icons.person_outline,
                      title: 'Edit Profil',
                      subtitle: 'Ubah nama dan departemen',
                      onTap: () => Get.toNamed(Routes.PROFILE_EDIT),
                    ),
                    const _DividerInset(),
                    _Tile(
                      icon: Icons.lock_outline,
                      title: 'Ganti Password',
                      subtitle: 'Update kata sandi akun',
                      onTap: () => Get.toNamed(Routes.CHANGE_PASSWORD),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionLabel('Aktivitas'),
                _Card(
                  children: [
                    _Tile(
                      icon: Icons.assignment_outlined,
                      title: 'Laporan Saya',
                      subtitle: 'Lihat laporan lapangan yang dikirim',
                      onTap: () => Get.toNamed(Routes.REPORTS),
                    ),
                    const _DividerInset(),
                    _Tile(
                      icon: Icons.event_note_outlined,
                      title: 'Pengajuan Saya',
                      subtitle: 'Cuti, izin, sakit, dinas',
                      onTap: () => Get.toNamed(Routes.PERMIT),
                    ),
                    const _DividerInset(),
                    _Tile(
                      icon: Icons.history,
                      title: 'Riwayat Presensi',
                      subtitle: 'Check-in & check-out terdahulu',
                      onTap: () => Get.toNamed(Routes.ATTENDANCE_HISTORY),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionLabel('Lainnya'),
                _Card(
                  children: [
                    _Tile(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      subtitle: 'Keluar dari akun',
                      iconColor: AppTheme.danger,
                      titleColor: AppTheme.danger,
                      onTap: controller.logout,
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ProfileController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
      child: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _showAvatarSheet(context),
              child: Obx(() {
                final user = controller.auth.user.value;
                final imageUrl = user?['image']?.toString();
                final name = user?['name']?.toString() ?? 'User';

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: AvatarBubble(
                        imageUrl: imageUrl,
                        name: name,
                        radius: 48,
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primary,
                        fontSize: 36,
                      ),
                    ),
                    if (controller.isUploadingAvatar.value)
                      Container(
                        width: 102,
                        height: 102,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      )
                    else
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: AppTheme.primary,
                            size: 14,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 14),
          Obx(() => Text(
                controller.auth.user.value?['name']?.toString() ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              )),
          const SizedBox(height: 4),
          Obx(() => Text(
                controller.auth.user.value?['email']?.toString() ?? '',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
              )),
          const SizedBox(height: 10),
          Obx(() {
            final role =
                controller.auth.user.value?['role']?.toString() ?? '';
            final dept =
                controller.auth.user.value?['department']?.toString();
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                if (role.isNotEmpty)
                  _MiniChip(
                    icon: Icons.verified_user_outlined,
                    label: role.toUpperCase(),
                  ),
                if (dept != null && dept.isNotEmpty)
                  _MiniChip(
                    icon: Icons.business_outlined,
                    label: dept,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  void _showAvatarSheet(BuildContext context) {
    if (controller.isUploadingAvatar.value) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppTheme.primary),
              title: const Text('Ambil Foto'),
              subtitle: const Text('Buka kamera untuk foto baru'),
              onTap: () {
                Navigator.of(ctx).pop();
                controller.pickAndUploadProfilePicture();
              },
            ),
            const Divider(height: 1, color: AppTheme.cardBorder),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.primary),
              title: const Text('Pilih dari Galeri'),
              subtitle: const Text('Pilih foto dari penyimpanan'),
              onTap: () {
                Navigator.of(ctx).pop();
                controller.pickFromGalleryAndUpload();
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
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
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
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _DividerInset extends StatelessWidget {
  const _DividerInset();
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppTheme.cardBorder,
      indent: 60,
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  final Color titleColor;
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.iconColor = AppTheme.primary,
    this.titleColor = AppTheme.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textHint, size: 18),
          ],
        ),
      ),
    );
  }
}
