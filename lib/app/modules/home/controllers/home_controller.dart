import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:intl/intl.dart';
import '../../../data/controllers/auth_controller.dart';
import '../../../data/services/api_service.dart';
import '../../dashboard/controllers/dashboard_controller.dart';

class HomeController extends GetxController {
  final api = Get.find<ApiService>();
  final auth = Get.find<AuthController>();

  final isLoading = false.obs;
  final checkInTime = Rxn<DateTime>();
  final checkOutTime = Rxn<DateTime>();
  final lastLocation = Rxn<String>();
  final recent = <Map>[].obs;
  final announcements = <Map>[].obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  Map? get user => auth.user.value;

  Future<void> refresh() async {
    isLoading.value = true;
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final res = await api.fetchAttendances(from: today, to: today, limit: 10);
      if (res.statusCode == 200) {
        final raw = res.data['data']?['items'] ?? res.data['data'] ?? [];
        final items = List<Map>.from(raw as List);
        _populateToday(items);
      }

      // Recent (last 5 across all dates)
      final recentRes = await api.fetchAttendances(limit: 5);
      if (recentRes.statusCode == 200) {
        final raw =
            recentRes.data['data']?['items'] ?? recentRes.data['data'] ?? [];
        recent.assignAll(List<Map>.from(raw as List));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) {
        Get.snackbar("Error", dioErrorMessage(e, 'Failed to load attendance'));
      }
    } finally {
      isLoading.value = false;
    }

    // Announcements load separately so a failure here doesn't break the
    // attendance card that users actually need to clock in.
    try {
      final res = await api.fetchAnnouncements(limit: 3);
      if (res.statusCode == 200) {
        final raw = res.data['data']?['items'] ?? res.data['data'] ?? [];
        announcements.assignAll(List<Map>.from(raw as List));
      }
    } on DioException catch (_) {
      // Silent on dashboard — announcements are non-critical.
    }
  }

  void _populateToday(List<Map> items) {
    checkInTime.value = null;
    checkOutTime.value = null;
    for (final it in items) {
      final type = it['type']?.toString();
      // Server returns UTC ISO ("...Z"); convert to device-local before
      // surfacing so the HH:mm formatter shows wall-clock time, not UTC.
      final t = DateTime.tryParse(it['serverTime']?.toString() ?? '')?.toLocal();
      if (t == null) continue;
      if (type == 'check_in') checkInTime.value = t;
      if (type == 'check_out') checkOutTime.value = t;
      lastLocation.value = it['locationName']?.toString() ?? lastLocation.value;
    }
  }

  void goToReports() => Get.toNamed('/reports');
  void goToHistory() => Get.toNamed('/attendance-history');
  void goToProfile() {
    // If embedded in DashboardView with bottom nav, switch the tab instead
    // of pushing a new route. Falls back to plain navigation otherwise.
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().changePage(4);
      return;
    }
    Get.toNamed('/profile');
  }
  void goToPermit() {
    // Pengajuan / Requests is now a dashboard tab. Switch instead of push.
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().changePage(3);
      return;
    }
    Get.toNamed('/permit');
  }
  void goToAnnouncements() => Get.toNamed('/announcements');
  void openAnnouncementDetail(String id) =>
      Get.toNamed('/announcements/detail', arguments: id);
}
