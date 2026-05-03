import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../../data/services/api_service.dart';

class AttendanceHistoryController extends GetxController {
  final api = Get.find<ApiService>();

  final isLoading = false.obs;
  final items = <Map>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch() async {
    isLoading.value = true;
    try {
      final res = await api.fetchAttendances(limit: 50);
      if (res.statusCode == 200) {
        final raw = res.data['data']?['items'] ?? res.data['data'] ?? [];
        items.assignAll(List<Map>.from(raw as List));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) {
        Get.snackbar("Error", dioErrorMessage(e, 'Failed to load history'));
      }
    } finally {
      isLoading.value = false;
    }
  }
}
