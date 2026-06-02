import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:intl/intl.dart';
import '../../../data/controllers/auth_controller.dart';
import '../../../data/services/api_service.dart';

class HomeController extends GetxController {
  final api = Get.find<ApiService>();
  final auth = Get.find<AuthController>();

  final isLoading = false.obs;
  final checkInTime = Rxn<DateTime>();
  final checkOutTime = Rxn<DateTime>();
  final lastLocation = Rxn<String>();
  final recent = <Map>[].obs;

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
  }

  void _populateToday(List<Map> items) {
    checkInTime.value = null;
    checkOutTime.value = null;
    for (final it in items) {
      final type = it['type']?.toString();
      final t = DateTime.tryParse(it['serverTime']?.toString() ?? '');
      if (t == null) continue;
      if (type == 'check_in') checkInTime.value = t;
      if (type == 'check_out') checkOutTime.value = t;
      lastLocation.value = it['locationName']?.toString() ?? lastLocation.value;
    }
  }

  void goToReports() => Get.toNamed('/reports');
  void goToHistory() => Get.toNamed('/attendance-history');
  void goToProfile() => Get.toNamed('/profile');
  void goToPermit() => Get.toNamed('/permit');
}
