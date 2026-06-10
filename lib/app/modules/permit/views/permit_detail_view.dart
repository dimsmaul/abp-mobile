import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants.dart';
import '../../../core/theme.dart';
import '../controllers/permit_controller.dart';

class PermitDetailView extends GetView<PermitController> {
  const PermitDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: AppTheme.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isDetailLoading.value && controller.detail.value == null) {
          return const _DetailSkeleton();
        }
        final d = controller.detail.value;
        if (d == null) return const SizedBox.shrink();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _headerCard(d),
              const SizedBox(height: 12),
              _datesCard(d),
              const SizedBox(height: 12),
              _descriptionCard(d),
              const SizedBox(height: 12),
              _categorySection(d),
              const SizedBox(height: 12),
              _validationCard(d),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  // ── Header (category + status) ────────────────────────────────
  Widget _headerCard(Map d) {
    final category = _categoryOf(d);
    final status = d['status']?.toString() ?? 'pending';
    final color = permitTypeColor(category);
    final icon = permitTypeIcon(category);
    final label = permitTypeLabel(category);
    final createdAt = d['createdAt']?.toString();
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Submitted ${_dateTimeStr(createdAt)}',
                  style: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _statusBadge(status),
        ],
      ),
    );
  }

  // ── Date(s) ──────────────────────────────────────────────────
  Widget _datesCard(Map d) {
    final category = _categoryOf(d);
    final start = DateTime.tryParse(d['startDate']?.toString() ?? '');
    final end = DateTime.tryParse(d['endDate']?.toString() ?? '');

    // Loan has no real date in the UI flow — BE stores start == end == today
    // as a placeholder. Hide the section for loan to avoid a misleading line.
    if (category == 'loan') return const SizedBox.shrink();

    String label;
    String value;
    if (category == 'overtime' || category == 'reimburse') {
      label = category == 'overtime' ? 'Overtime Date' : 'Receipt Date';
      value = start != null ? DateFormat('EEEE, dd MMMM yyyy').format(start) : '-';
    } else {
      label = 'Period';
      if (start != null && end != null) {
        if (start.isAtSameMomentAs(end)) {
          value = DateFormat('EEEE, dd MMMM yyyy').format(start);
        } else {
          value =
              '${DateFormat('dd MMM yyyy').format(start)}  →  ${DateFormat('dd MMM yyyy').format(end)}';
        }
      } else {
        value = '-';
      }
    }

    final daysUsed = d['daysUsed'];
    return _section(
      title: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppTheme.textHint),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          if (category == 'leave' && daysUsed != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_busy_outlined,
                    size: 14, color: AppTheme.textHint),
                const SizedBox(width: 6),
                Text(
                  '${_numStr(daysUsed)} working day(s)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Description ──────────────────────────────────────────────
  Widget _descriptionCard(Map d) {
    final desc = d['description']?.toString() ?? '-';
    return _section(
      title: 'Description',
      child: Text(
        desc,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  // ── Category-specific extras ─────────────────────────────────
  Widget _categorySection(Map d) {
    final cat = _categoryOf(d);
    switch (cat) {
      case 'overtime':
        return _overtimeCard(d);
      case 'reimburse':
        return _reimburseCard(d);
      case 'loan':
        return _loanCard(d);
      case 'sick':
      case 'permit':
        return _attachmentCard(d);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _overtimeCard(Map d) {
    final hours = d['overtimeHours'];
    return _section(
      title: 'Overtime',
      child: _kv('Hours', hours == null ? '-' : '${_numStr(hours)} hour(s)'),
    );
  }

  Widget _reimburseCard(Map d) {
    final amount = d['reimburseAmount'];
    final receiptUrl = d['reimburseReceiptUrl']?.toString();
    return _section(
      title: 'Reimbursement',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Amount', _idr(amount)),
          if (receiptUrl != null && receiptUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Receipt',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  receiptUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.cardBorder,
                    child: const Icon(Icons.broken_image,
                        color: AppTheme.textHint, size: 40),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _loanCard(Map d) {
    final amount = d['loanAmount'];
    final tenor = d['loanTenorMonths'];
    // Postgres `numeric` comes through as a String over JSON, so don't cast —
    // parse via _toDouble/_toInt which handle num, String, and null.
    final amt = _toDouble(amount);
    final tn = _toInt(tenor);
    final monthly = (amt != null && tn != null && tn > 0) ? amt / tn : null;
    return _section(
      title: 'Loan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv('Amount', _idr(amount)),
          const SizedBox(height: 8),
          _kv('Tenor', tn == null ? '-' : '$tn month(s)'),
          if (monthly != null) ...[
            const SizedBox(height: 8),
            _kv('Estimated monthly', _idr(monthly)),
          ],
        ],
      ),
    );
  }

  Widget _attachmentCard(Map d) {
    final url = d['attachmentUrl']?.toString();
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return _section(
      title: 'Attachment',
      child: Row(
        children: [
          const Icon(Icons.attach_file, size: 16, color: AppTheme.textHint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              url,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Validation / notes ───────────────────────────────────────
  Widget _validationCard(Map d) {
    final status = d['status']?.toString() ?? 'pending';
    final notes = d['notes']?.toString();
    final updatedAt = d['updatedAt']?.toString();
    if (status == 'pending') {
      return _section(
        title: 'Validation',
        child: const Text(
          'Awaiting manager review',
          style: TextStyle(color: AppTheme.textHint, fontSize: 13),
        ),
      );
    }
    return _section(
      title: 'Validation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                status == 'approved'
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                color: permitStatusColor(status),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                permitStatusLabel(status),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: permitStatusColor(status),
                ),
              ),
              const Spacer(),
              if (updatedAt != null)
                Text(
                  _dateTimeStr(updatedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textHint,
                  ),
                ),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notes,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Shared primitives ────────────────────────────────────────
  Widget _section({required String title, required Widget child}) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textHint,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: child,
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            k,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textHint,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final color = permitStatusColor(status);
    final label = permitStatusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  String _categoryOf(Map d) {
    final cat = d['category']?.toString();
    if (cat != null && cat.isNotEmpty) return cat;
    return d['type']?.toString() ?? '';
  }

  String _dateTimeStr(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd MMM yyyy • HH:mm').format(dt.toLocal());
  }

  String _numStr(dynamic v) {
    if (v == null) return '-';
    final n = (v is num) ? v : num.tryParse(v.toString());
    if (n == null) return v.toString();
    // Trim trailing .0 so "8.0 hour(s)" reads as "8".
    if (n == n.truncate()) return n.toInt().toString();
    return n.toString();
  }

  String _idr(dynamic v) {
    if (v == null) return '-';
    final n = _toDouble(v);
    if (n == null) return v.toString();
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return fmt.format(n);
  }

  // Numeric helpers — BE sends `numeric` Postgres columns as Strings, so
  // never `as num` directly.
  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.toInt();
  }
}

// ── Loading Skeleton ─────────────────────────────────────────
class _DetailSkeleton extends StatefulWidget {
  const _DetailSkeleton();

  @override
  State<_DetailSkeleton> createState() => _DetailSkeletonState();
}

class _DetailSkeletonState extends State<_DetailSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final opacity = 0.4 + (_ctrl.value * 0.4);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _card(opacity, [
                _box(opacity, height: 18, widthFactor: 0.5),
                const SizedBox(height: 8),
                _box(opacity, height: 12, widthFactor: 0.4),
              ]),
              const SizedBox(height: 12),
              _card(opacity, [
                _box(opacity, height: 12, widthFactor: 0.3),
                const SizedBox(height: 10),
                _box(opacity, height: 14, widthFactor: 0.8),
              ]),
              const SizedBox(height: 12),
              _card(opacity, [
                _box(opacity, height: 12, widthFactor: 0.3),
                const SizedBox(height: 10),
                _box(opacity, height: 12, widthFactor: 0.95),
                const SizedBox(height: 6),
                _box(opacity, height: 12, widthFactor: 0.85),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _box(double opacity,
      {required double height, double widthFactor = 1.0, double radius = 8}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.cardBorder.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _card(double opacity, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
