import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:intl/intl.dart';

import '../../../data/services/api_service.dart';

/// Per-day entry returned by `/mobile/attendances/calendar`. Backend may
/// omit any field — controller normalises into a Map keyed by 'YYYY-MM-DD'.
class CalendarController extends GetxController {
  final api = Get.find<ApiService>();

  /// First day of the currently viewed month (always `DateTime(year, month, 1)`).
  final visibleMonth = DateTime.now().obs;

  final isLoading = false.obs;

  /// Map of 'YYYY-MM-DD' → entry. Entry shape (any fields may be missing):
  /// `{ date, status, checkIn, checkOut }`.
  final daysByDate = <String, Map>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Snap to first-of-month so all month arithmetic is stable.
    final now = DateTime.now();
    visibleMonth.value = DateTime(now.year, now.month, 1);
    fetchMonth();
  }

  String get monthParam =>
      DateFormat('yyyy-MM').format(visibleMonth.value);

  String get monthLabel =>
      DateFormat('MMMM yyyy').format(visibleMonth.value);

  Future<void> fetchMonth() async {
    isLoading.value = true;
    try {
      final res = await api.fetchCalendar(month: monthParam);
      if (res.statusCode == 200) {
        final data = res.data['data'];
        final list = data is List ? data : (data is Map ? data['items'] : null);
        final map = <String, Map>{};
        if (list is List) {
          for (final raw in list) {
            if (raw is! Map) continue;
            final dateStr = raw['date']?.toString();
            if (dateStr == null || dateStr.isEmpty) continue;
            // Normalise to YYYY-MM-DD regardless of whether BE returns full
            // ISO timestamp or already-trimmed date string.
            final dt = DateTime.tryParse(dateStr);
            final key = dt != null
                ? DateFormat('yyyy-MM-dd').format(dt)
                : dateStr.substring(0, dateStr.length > 10 ? 10 : dateStr.length);
            map[key] = Map<String, dynamic>.from(raw);
          }
        }
        daysByDate.assignAll(map);
      }
    } on DioException catch (e) {
      Get.snackbar('Error', dioErrorMessage(e, 'Failed to load calendar'));
    } finally {
      isLoading.value = false;
    }
  }

  void goToPreviousMonth() {
    final v = visibleMonth.value;
    visibleMonth.value = DateTime(v.year, v.month - 1, 1);
    fetchMonth();
  }

  void goToNextMonth() {
    final v = visibleMonth.value;
    visibleMonth.value = DateTime(v.year, v.month + 1, 1);
    fetchMonth();
  }

  /// Lookup helper. Returns null when there's no entry for [date].
  Map? entryFor(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return daysByDate[key];
  }
}
