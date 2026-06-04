import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../../data/services/api_service.dart';

class AnnouncementController extends GetxController {
  final api = Get.find<ApiService>();

  // List state
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final announcements = <Map>[].obs;
  final hasMore = true.obs;
  int _page = 1;
  static const int _limit = 20;

  // Detail state
  final isDetailLoading = false.obs;
  final detail = Rxn<Map>();

  @override
  void onInit() {
    super.onInit();
    fetchAnnouncements(reset: true);
  }

  Future<void> fetchAnnouncements({bool reset = false}) async {
    if (reset) {
      _page = 1;
      hasMore.value = true;
      isLoading.value = true;
    } else {
      if (!hasMore.value || isLoadingMore.value) return;
      isLoadingMore.value = true;
    }

    try {
      final res = await api.fetchAnnouncements(page: _page, limit: _limit);
      if (res.statusCode == 200) {
        final raw = res.data['data']?['items'] ?? res.data['data'] ?? [];
        final list = List<Map>.from(raw as List);
        if (reset) {
          announcements.assignAll(list);
        } else {
          announcements.addAll(list);
        }
        if (list.length < _limit) {
          hasMore.value = false;
        } else {
          _page += 1;
        }
      }
    } on DioException catch (e) {
      Get.snackbar('Error', dioErrorMessage(e, 'Failed to load announcements'));
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> openDetail(String id) async {
    detail.value = null;
    isDetailLoading.value = true;
    Get.toNamed('/announcements/detail', arguments: id);
    try {
      final res = await api.fetchAnnouncementDetail(id);
      if (res.statusCode == 200) {
        detail.value = Map<String, dynamic>.from(res.data['data'] as Map);
      }
    } on DioException catch (e) {
      Get.snackbar('Error', dioErrorMessage(e, 'Failed to load details'));
    } finally {
      isDetailLoading.value = false;
    }
  }
}
