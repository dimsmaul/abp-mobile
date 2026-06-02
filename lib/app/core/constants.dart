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
const List<String> kPermitTypes = ['sick', 'leave', 'permit'];

// ── Indonesian Labels ───────────────────────────────────────
String reportCategoryLabel(String s) {
  switch (s) {
    case 'weather':
      return 'Cuaca';
    case 'technical':
      return 'Teknis';
    case 'progress':
      return 'Progres';
    case 'other':
      return 'Lainnya';
    default:
      return s;
  }
}

String reportStatusLabel(String s) {
  switch (s) {
    case 'pending':
      return 'Menunggu';
    case 'approved':
      return 'Disetujui';
    case 'rejected':
      return 'Ditolak';
    case 'need_revision':
      return 'Perlu Revisi';
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
      return 'Menunggu';
    case 'approved':
      return 'Disetujui';
    case 'rejected':
      return 'Ditolak';
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
      return 'Sakit';
    case 'leave':
      return 'Cuti';
    case 'permit':
      return 'Izin';
    default:
      return s;
  }
}
