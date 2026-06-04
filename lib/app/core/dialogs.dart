import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'theme.dart';

/// Themed modal loading dialog. Re-uses [AppTheme] colors so it matches the
/// rest of the UI (no platform-default AlertDialog look). Non-dismissable;
/// caller MUST close via [closeAppLoadingDialog] when work finishes.
void showAppLoadingDialog(String message) {
  if (Get.isDialogOpen ?? false) return;
  Get.dialog(
    PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 2.5,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

void closeAppLoadingDialog() {
  if (Get.isDialogOpen ?? false) Get.back();
}

/// Themed success / error result dialog. Returns when the user taps the
/// action button so callers can sequence navigation reliably.
Future<void> showAppResultDialog({
  required bool success,
  required String title,
  required String message,
  String okLabel = 'OK',
  VoidCallback? onOk,
}) {
  return Get.dialog(
    Dialog(
      backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error_outline,
                  color: success ? AppTheme.success : AppTheme.danger,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  if (Get.isDialogOpen ?? false) Get.back();
                  onOk?.call();
                },
                child: Text(okLabel),
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: false,
  );
}
