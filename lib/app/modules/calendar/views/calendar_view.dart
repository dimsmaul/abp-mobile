import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../controllers/calendar_controller.dart';

/// Attendance calendar — month grid with per-day status dots:
///  - green  (success)  : present
///  - yellow (warning)  : late
///  - red    (danger)   : absent
///  - none              : holiday / weekend / future date
class CalendarView extends GetView<CalendarController> {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.fetchMonth,
          color: AppTheme.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 20),
                _monthSwitcher(),
                const SizedBox(height: 16),
                _weekdayHeader(),
                const SizedBox(height: 8),
                // Touch BOTH observables inside the Obx scope so the grid
                // rebuilds when the month switches OR the fetched data
                // lands. `entryFor` reads `daysByDate` from inside an
                // itemBuilder which runs outside Obx tracking — without
                // this explicit read, dots never appeared after the
                // network response arrived.
                Obx(() {
                  controller.visibleMonth.value;
                  controller.daysByDate.length;
                  return _grid(context);
                }),
                const SizedBox(height: 20),
                _legend(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attendance Calendar',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Tap a date to see the day details',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _monthSwitcher() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left,
                  color: AppTheme.textPrimary),
              onPressed: controller.goToPreviousMonth,
              tooltip: 'Previous month',
            ),
            Expanded(
              child: Center(
                child: Text(
                  controller.monthLabel,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right,
                  color: AppTheme.textPrimary),
              onPressed: controller.goToNextMonth,
              tooltip: 'Next month',
            ),
          ],
        ),
      );
    });
  }

  Widget _weekdayHeader() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: labels
          .map(
            (l) => Expanded(
              child: Center(
                child: Text(
                  l,
                  style: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _grid(BuildContext context) {
    final month = controller.visibleMonth.value;
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday = 1, Sunday = 7. Convert so the column index 0 = Monday.
    final leadingBlanks = (firstDay.weekday - 1) % 7;
    final totalCells = leadingBlanks + daysInMonth;
    // Round up to multiples of 7 so the grid is rectangular.
    final paddedCount = ((totalCells + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.85,
      ),
      itemCount: paddedCount,
      itemBuilder: (_, i) {
        if (i < leadingBlanks || i >= leadingBlanks + daysInMonth) {
          return const SizedBox.shrink();
        }
        final dayNum = i - leadingBlanks + 1;
        final date = DateTime(month.year, month.month, dayNum);
        return _DayCell(
          date: date,
          entry: controller.entryFor(date),
          onTap: () => _showDayDetails(context, date),
        );
      },
    );
  }

  Widget _legend() {
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: const [
        _LegendDot(color: AppTheme.success, label: 'Present'),
        _LegendDot(color: AppTheme.warning, label: 'Late'),
        _LegendDot(color: AppTheme.danger, label: 'Absent'),
      ],
    );
  }

  void _showDayDetails(BuildContext context, DateTime date) {
    final entry = controller.entryFor(date);
    Get.bottomSheet(
      _DayDetailsSheet(date: date, entry: entry),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final Map? entry;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));
    final status = entry?['status']?.toString();
    final dotColor = _dotColor(status, isFuture);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? AppTheme.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday ? AppTheme.primary : AppTheme.cardBorder,
            width: isToday ? 1.5 : 1,
          ),
        ),
        // Stack so the status dot floats in the top-right corner instead
        // of pushing the day number down.
        child: Stack(
          children: [
            Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: isToday ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (dotColor != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color? _dotColor(String? status, bool isFuture) {
    if (isFuture) return null;
    switch (status) {
      case 'present':
        return AppTheme.success;
      case 'late':
        return AppTheme.warning;
      case 'absent':
        return AppTheme.danger;
      default:
        // holiday / weekend / unknown — render no dot
        return null;
    }
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DayDetailsSheet extends StatelessWidget {
  final DateTime date;
  final Map? entry;

  const _DayDetailsSheet({required this.date, required this.entry});

  @override
  Widget build(BuildContext context) {
    final status = entry?['status']?.toString();
    final checkIn =
        DateTime.tryParse(entry?['checkIn']?.toString() ?? '')?.toLocal();
    final checkOut =
        DateTime.tryParse(entry?['checkOut']?.toString() ?? '')?.toLocal();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            DateFormat('EEEE, dd MMM yyyy').format(date),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _StatusBadge(status: status),
          const SizedBox(height: 20),
          _row(
            icon: Icons.login,
            label: 'Check-in',
            value: checkIn != null
                ? DateFormat('HH:mm').format(checkIn)
                : '—',
          ),
          const SizedBox(height: 10),
          _row(
            icon: Icons.logout,
            label: 'Check-out',
            value: checkOut != null
                ? DateFormat('HH:mm').format(checkOut)
                : '—',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Get.back(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.access_time,
              color: AppTheme.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.textHint, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String? status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'present':
        color = AppTheme.success;
        label = 'Present';
        break;
      case 'late':
        color = AppTheme.warning;
        label = 'Late';
        break;
      case 'absent':
        color = AppTheme.danger;
        label = 'Absent';
        break;
      case 'holiday':
        color = AppTheme.primary;
        label = 'Holiday';
        break;
      default:
        color = AppTheme.textHint;
        label = 'No record';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
