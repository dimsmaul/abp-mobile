import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../../data/services/api_service.dart';

class AttendanceHistoryController extends GetxController {
  final api = Get.find<ApiService>();

  static const int _limit = 20;

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final page = 1.obs;
  final items = <Map>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  Future<void> fetch({bool reset = true}) async {
    if (reset) {
      page.value = 1;
      hasMore.value = true;
      isLoading.value = true;
    } else {
      if (!hasMore.value || isLoadingMore.value) return;
      page.value += 1;
      isLoadingMore.value = true;
    }
    try {
      final res = await api.fetchAttendances(page: page.value, limit: _limit);
      if (res.statusCode == 200) {
        final dataMap = res.data['data'];
        final raw = dataMap is Map
            ? (dataMap['items'] ?? [])
            : (dataMap ?? []);
        final newItems = List<Map>.from(raw as List);
        if (reset) {
          items.assignAll(newItems);
        } else {
          items.addAll(newItems);
        }

        final meta = dataMap is Map ? dataMap['meta'] : null;
        if (meta is Map && meta['totalPages'] != null) {
          final totalPages = (meta['totalPages'] as num).toInt();
          hasMore.value = page.value < totalPages;
        } else {
          // Fallback: if returned less than limit, no more pages.
          hasMore.value = newItems.length >= _limit;
        }
      }
    } on DioException catch (e) {
      // Revert page increment on failure for non-reset fetch.
      if (!reset) page.value -= 1;
      if (e.response?.statusCode != 401) {
        Get.snackbar("Error", dioErrorMessage(e, 'Failed to load history'));
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchMore() => fetch(reset: false);
}
