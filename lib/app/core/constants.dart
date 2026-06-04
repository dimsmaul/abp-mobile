import 'package:flutter/material.dart';
import 'theme.dart';

// ── Report Categories ───────────────────────────────────────
const List<String> kReportCategories = [
  'weather',
  'technical',
  'progress',
  'other',
];

// ── Report Statuses ─────────────────────────────────────────
const List<String> kReportStatuses = [
  'pending',
  'approved',
  'rejected',
  'need_revision',
];

// ── Permit Types ────────────────────────────────────────────
// 6 categories supported by the mobile pengajuan flow. Backend permits
// endpoint accepts all of these; UI branches on the value to render the
// matching form fields.
const List<String> kPermitTypes = [
  'leave',
  'sick',
  'permit',
  'overtime',
  'reimburse',
  'loan',
];

// ── English Labels ──────────────────────────────────────────
String reportCategoryLabel(String s) {
  switch (s) {
    case 'weather':
      return 'Weather';
    case 'technical':
      return 'Technical';
    case 'progress':
      return 'Progress';
    case 'other':
      return 'Other';
    default:
      return s;
  }
}

String reportStatusLabel(String s) {
  switch (s) {
    case 'pending':
      return 'Pending';
    case 'approved':
      return 'Approved';
    case 'rejected':
      return 'Rejected';
    case 'need_revision':
      return 'Needs Revision';
    default:
      return s;
  }
}

Color reportStatusColor(String s) {
  switch (s) {
    case 'pending':
      return AppTheme.warning;
    case 'approved':
      return AppTheme.success;
    case 'rejected':
      return AppTheme.danger;
    case 'need_revision':
      return Colors.orange;
    default:
      return AppTheme.textHint;
  }
}

String permitStatusLabel(String s) {
  switch (s) {
    case 'pending':
      return 'Pending';
    case 'approved':
      return 'Approved';
    case 'rejected':
      return 'Rejected';
    default:
      return s;
  }
}

Color permitStatusColor(String s) {
  switch (s) {
    case 'approved':
      return AppTheme.success;
    case 'rejected':
      return AppTheme.danger;
    case 'pending':
      return AppTheme.warning;
    default:
      return AppTheme.warning;
  }
}

String permitTypeLabel(String s) {
  switch (s) {
    case 'sick':
      return 'Sick Leave';
    case 'leave':
      return 'Annual Leave';
    case 'permit':
      return 'Personal Leave';
    case 'overtime':
      return 'Overtime';
    case 'reimburse':
      return 'Reimbursement';
    case 'loan':
      return 'Loan Request';
    default:
      return s;
  }
}

IconData permitTypeIcon(String s) {
  switch (s) {
    case 'sick':
      return Icons.favorite_outline;
    case 'leave':
      return Icons.beach_access_outlined;
    case 'permit':
      return Icons.event_note_outlined;
    case 'overtime':
      return Icons.timer_outlined;
    case 'reimburse':
      return Icons.receipt_long_outlined;
    case 'loan':
      return Icons.account_balance_wallet_outlined;
    default:
      return Icons.assignment_outlined;
  }
}

Color permitTypeColor(String s) {
  switch (s) {
    case 'sick':
      return AppTheme.danger;
    case 'leave':
      return AppTheme.primary;
    case 'permit':
      return AppTheme.warning;
    case 'overtime':
      return const Color(0xFF8B5CF6); // purple
    case 'reimburse':
      return AppTheme.success;
    case 'loan':
      return const Color(0xFF0EA5E9); // sky
    default:
      return AppTheme.textHint;
  }
}
