import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../controllers/attendance_history_controller.dart';

class AttendanceHistoryView extends StatefulWidget {
  const AttendanceHistoryView({super.key});

  @override
  State<AttendanceHistoryView> createState() => _AttendanceHistoryViewState();
}

class _AttendanceHistoryViewState extends State<AttendanceHistoryView> {
  final AttendanceHistoryController controller =
      Get.find<AttendanceHistoryController>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (controller.hasMore.value && !controller.isLoadingMore.value) {
        controller.fetchMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(title: const Text("Attendance History")),
      body: Obx(() {
        if (controller.isLoading.value && controller.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.items.isEmpty) {
          return _empty();
        }
        // Group by date.
        final grouped = <String, List<Map>>{};
        for (final it in controller.items) {
          final t = DateTime.tryParse(it['serverTime']?.toString() ?? '');
          if (t == null) continue;
          final key = DateFormat('yyyy-MM-dd').format(t);
          grouped.putIfAbsent(key, () => []).add(it);
        }
        final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
        final showLoader = controller.isLoadingMore.value;
        return RefreshIndicator(
          onRefresh: () => controller.fetch(reset: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: keys.length + 1,
            itemBuilder: (_, i) {
              if (i == keys.length) {
                if (showLoader) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!controller.hasMore.value) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        "No more records",
                        style: TextStyle(color: AppTheme.textHint, fontSize: 12),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }
              final date = keys[i];
              final entries = grouped[date]!;
              return _dateGroup(date, entries);
            },
          ),
        );
      }),
    );
  }

  Widget _dateGroup(String date, List<Map> entries) {
    final d = DateTime.parse(date);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == date;
    final label = isToday
        ? "Today, ${DateFormat('dd MMM yyyy').format(d)}"
        : DateFormat('EEEE, dd MMM yyyy').format(d);

    DateTime? cIn, cOut;
    for (final e in entries) {
      final t = DateTime.tryParse(e['serverTime']?.toString() ?? '');
      if (t == null) continue;
      if (e['type'] == 'check_in') cIn = t;
      if (e['type'] == 'check_out') cOut = t;
    }
    String duration = '-';
    if (cIn != null && cOut != null) {
      final mins = cOut.difference(cIn).inMinutes;
      duration = '${mins ~/ 60}h ${mins % 60}m';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              if (cIn != null && cOut != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(duration,
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _slot('Check In', cIn, true, entries)),
              Expanded(child: _slot('Check Out', cOut, false, entries)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slot(String label, DateTime? time, bool isIn, List<Map> entries) {
    final entry = entries.firstWhere(
      (e) => e['type'] == (isIn ? 'check_in' : 'check_out'),
      orElse: () => {},
    );
    final loc = entry['locationName']?.toString();
    final inZone = entry['isWithinZone'] == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(isIn ? Icons.login : Icons.logout,
                size: 14,
                color: time == null ? AppTheme.textHint : AppTheme.primary),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textHint, fontSize: 12)),
            if (time != null && inZone) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified,
                  color: AppTheme.success, size: 12),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(time != null ? DateFormat('HH:mm').format(time) : '--:--',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700)),
        if (loc != null && loc.isNotEmpty)
          Text(loc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTheme.textHint, fontSize: 11)),
      ],
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.history, size: 56, color: AppTheme.textHint),
          SizedBox(height: 12),
          Text("No attendance records yet",
              style: TextStyle(color: AppTheme.textHint)),
        ],
      ),
    );
  }
}
