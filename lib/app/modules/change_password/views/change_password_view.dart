import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme.dart';
import '../controllers/change_password_controller.dart';

class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Change Password'),
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      color: AppTheme.primary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'New password must be at least 8 characters. Other active sessions will be signed out for security.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const _SectionLabel('Current Password'),
            const SizedBox(height: 8),
            Obx(() => TextField(
                  controller: controller.currentCtl,
                  obscureText: controller.obscureCurrent.value,
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(controller.obscureCurrent.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => controller.obscureCurrent.toggle(),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                )),

            const SizedBox(height: 16),
            const _SectionLabel('New Password'),
            const SizedBox(height: 8),
            Obx(() => TextField(
                  controller: controller.newCtl,
                  obscureText: controller.obscureNew.value,
                  decoration: InputDecoration(
                    hintText: 'At least 8 characters',
                    prefixIcon: const Icon(Icons.lock_reset, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(controller.obscureNew.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => controller.obscureNew.toggle(),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                )),

            const SizedBox(height: 16),
            const _SectionLabel('Confirm New Password'),
            const SizedBox(height: 8),
            Obx(() => TextField(
                  controller: controller.confirmCtl,
                  obscureText: controller.obscureConfirm.value,
                  decoration: InputDecoration(
                    hintText: 'Repeat the new password',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(controller.obscureConfirm.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => controller.obscureConfirm.toggle(),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                )),

            const SizedBox(height: 20),
            Obx(() => SwitchListTile.adaptive(
                  value: controller.revokeOtherSessions.value,
                  onChanged: (v) => controller.revokeOtherSessions.value = v,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Sign out from other sessions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    'Recommended for security.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                )),

            const SizedBox(height: 28),
            Obx(() => SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : controller.submit,
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Change Password',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
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
