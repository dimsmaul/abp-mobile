import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme.dart';
import '../controllers/profile_edit_controller.dart';

class ProfileEditView extends GetView<ProfileEditController> {
  const ProfileEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Edit Profil'),
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Perbarui informasi dasar akun Anda. Email tidak dapat diubah.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            const _SectionLabel('Nama Lengkap'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.nameCtl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Budi Santoso',
                prefixIcon: Icon(Icons.person_outline, size: 20),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),
            const _SectionLabel('Departemen'),
            const SizedBox(height: 8),
            TextField(
              controller: controller.deptCtl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Engineering',
                prefixIcon: Icon(Icons.business_outlined, size: 20),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),
            _ReadonlyTile(
              icon: Icons.alternate_email,
              label: 'Email',
              value: controller.auth.user.value?['email']?.toString() ?? '—',
            ),
            const SizedBox(height: 8),
            _ReadonlyTile(
              icon: Icons.verified_user_outlined,
              label: 'Role',
              value: (controller.auth.user.value?['role']?.toString() ?? '—')
                  .toUpperCase(),
            ),

            const SizedBox(height: 32),
            Obx(() => SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.isSaving.value ? null : controller.save,
                    child: controller.isSaving.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Simpan Perubahan',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _ReadonlyTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ReadonlyTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
