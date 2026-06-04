import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme.dart';
import '../controllers/presence_controller.dart';

class PresenceView extends GetView<PresenceController> {
  const PresenceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    const SizedBox(height: 20),
                    Obx(_statusCard),
                  ],
                ),
              ),
            ),
            // Bottom fixed CTA — stays above the dashboard's BottomAppBar.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Obx(_actionButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Verify your location before checking in / out',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Status card ─────────────────────────────────────────────────────────
  Widget _statusCard() {
    switch (controller.state.value) {
      case PresenceState.initial:
        return _neutralCard(
          icon: Icons.touch_app_outlined,
          title: 'Press the button below',
          subtitle: 'Start location verification for attendance',
        );
      case PresenceState.initializing:
      case PresenceState.fetching:
        return _neutralCard(
          icon: Icons.location_searching,
          title: controller.state.value == PresenceState.initializing
              ? 'Preparing…'
              : 'Reading location & offices…',
          subtitle: 'Please wait a moment',
          showSpinner: true,
        );
      case PresenceState.permissionCameraDenied:
        return _alertCard(
          color: AppTheme.danger,
          icon: Icons.no_photography_outlined,
          title: 'Camera Permission Denied',
          subtitle:
              'Open Settings and enable the camera permission to continue.',
          actionLabel: 'Open Settings',
          onAction: controller.openSettings,
        );
      case PresenceState.permissionLocationDenied:
        return _alertCard(
          color: AppTheme.danger,
          icon: Icons.location_off_outlined,
          title: 'Location Permission Denied',
          subtitle:
              'Open Settings and enable the location permission to verify your office.',
          actionLabel: 'Open Settings',
          onAction: controller.openSettings,
        );
      case PresenceState.locationServiceOff:
        return _alertCard(
          color: AppTheme.danger,
          icon: Icons.gps_off,
          title: 'GPS is Off',
          subtitle: 'Turn on Location Services on your device.',
          actionLabel: 'Open GPS Settings',
          onAction: controller.openLocationSettings,
        );
      case PresenceState.noOffices:
        return _alertCard(
          color: AppTheme.danger,
          icon: Icons.business_outlined,
          title: 'No Offices Registered',
          subtitle:
              'Contact your administrator to register an office area first.',
          actionLabel: 'Retry',
          onAction: controller.start,
        );
      case PresenceState.alreadyComplete:
        return _gradientCard(
          colors: const [AppTheme.success, Color(0xFF059669)],
          icon: Icons.check_circle,
          title: 'Attendance Complete for Today',
          subtitle:
              'You have already checked in and out. See you tomorrow!',
        );
      case PresenceState.error:
        return _alertCard(
          color: AppTheme.danger,
          icon: Icons.error_outline,
          title: 'An error occurred',
          subtitle: controller.errorMessage.value,
          actionLabel: 'Try Again',
          onAction: controller.start,
        );
      case PresenceState.inZone:
        return _gradientCard(
          colors: const [AppTheme.success, Color(0xFF059669)],
          icon: Icons.check_circle_outline,
          title: 'You are at the office',
          subtitle: controller.matchedOfficeName.value ??
              'Office location verified',
        );
      case PresenceState.outOfZone:
        return _gradientCard(
          colors: const [AppTheme.danger, Color(0xFFB91C1C)],
          icon: Icons.location_off,
          title: 'You are outside the office area',
          subtitle:
              'Attendance is only possible while inside the office area.',
        );
    }
  }

  Widget _gradientCard({
    required List<Color> colors,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _neutralCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showSpinner = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
            ),
            child: showSpinner
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : Icon(icon, color: AppTheme.primary, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color.withValues(alpha: 0.6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom action button ────────────────────────────────────────────────
  Widget _actionButton() {
    final s = controller.state.value;
    final inZone = s == PresenceState.inZone;
    final busy = s == PresenceState.initializing ||
        s == PresenceState.fetching;

    String label;
    VoidCallback? onTap;
    if (inZone) {
      label = controller.attendanceType.value == 'check_in'
          ? 'Open Camera · Check-in'
          : 'Open Camera · Check-out';
      onTap = controller.openCamera;
    } else if (s == PresenceState.initial) {
      label = 'Start Verification';
      onTap = controller.start;
    } else if (s == PresenceState.alreadyComplete) {
      label = 'Done for Today';
      onTap = null;
    } else if (busy) {
      label = 'Verifying…';
      onTap = null;
    } else {
      label = 'Verify Again';
      onTap = controller.start;
    }

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.cardBg,
          disabledForegroundColor: AppTheme.textHint,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            else
              Icon(inZone ? Icons.camera_alt_outlined : Icons.refresh,
                  size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
