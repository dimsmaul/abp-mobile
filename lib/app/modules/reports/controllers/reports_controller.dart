import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart' hide Response;
import '../../../data/services/api_service.dart';

class ReportsController extends GetxController {
  final api = Get.find<ApiService>();

  // List state
  final isLoading = false.obs;
  final reports = <Map>[].obs;
  final filterStatus = Rxn<String>();

  // Detail state
  final isDetailLoading = false.obs;
  final detail = Rxn<Map>();

  // Form state
  final isSubmitting = false.obs;
  final category = 'technical'.obs;
  final descriptionController = TextEditingController();
  final image = Rxn<File>();
  final position = Rxn<Position>();

  static const categories = ['weather', 'technical', 'progress', 'other'];

  @override
  void onInit() {
    super.onInit();
    fetchMyReports();
  }

  // ── List ────────────────────────────────────────
  Future<void> fetchMyReports() async {
    isLoading.value = true;
    try {
      final res = await api.fetchMyReports(status: filterStatus.value);
      if (res.statusCode == 200) {
        final raw = res.data['data']?['items'] ?? res.data['data'] ?? [];
        reports.assignAll(List<Map>.from(raw as List));
      }
    } on dio_pkg.DioException catch (e) {
      Get.snackbar("Error", dioErrorMessage(e, 'Failed to load reports'));
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String? status) {
    filterStatus.value = status;
    fetchMyReports();
  }

  // ── Detail ──────────────────────────────────────
  Future<void> openDetail(String id) async {
    detail.value = null;
    Get.toNamed('/reports/detail', arguments: id);
    isDetailLoading.value = true;
    try {
      final res = await api.fetchReportDetail(id);
      if (res.statusCode == 200) {
        detail.value = Map<String, dynamic>.from(res.data['data'] as Map);
      }
    } on dio_pkg.DioException catch (e) {
      Get.snackbar("Error", dioErrorMessage(e, 'Failed to load report'));
    } finally {
      isDetailLoading.value = false;
    }
  }

  // ── Create ──────────────────────────────────────
  Future<void> pickPhoto() async {
    final result = await Get.toNamed('/camera');
    if (result is String) image.value = File(result);
  }

  Future<bool> _ensureLocation() async {
    if (position.value != null) return true;
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      Get.snackbar("Error", "Location services are disabled");
      return false;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      Get.snackbar("Error", "Location permission denied");
      return false;
    }
    position.value = await Geolocator.getCurrentPosition();
    return true;
  }

  Future<void> submit() async {
    if (image.value == null) {
      Get.snackbar("Error", "Please attach a photo");
      return;
    }
    if (descriptionController.text.trim().length < 10) {
      Get.snackbar("Error", "Description must be at least 10 characters");
      return;
    }
    if (!await _ensureLocation()) return;

    isSubmitting.value = true;
    try {
      final fileName = image.value!.path.split('/').last;
      final form = dio_pkg.FormData.fromMap({
        "photo": await dio_pkg.MultipartFile.fromFile(image.value!.path,
            filename: fileName),
        "category": category.value,
        "description": descriptionController.text.trim(),
        "latitude": position.value!.latitude,
        "longitude": position.value!.longitude,
      });

      final res = await api.createReport(form);
      if (res.statusCode == 201) {
        Get.snackbar("Success",
            res.data['message'] ?? "Report submitted");
        _resetForm();
        Get.back();
        fetchMyReports();
      }
    } on dio_pkg.DioException catch (e) {
      Get.snackbar("Error", dioErrorMessage(e, 'Failed to submit report'));
    } finally {
      isSubmitting.value = false;
    }
  }

  void _resetForm() {
    descriptionController.clear();
    image.value = null;
    position.value = null;
    category.value = 'technical';
  }

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }
}
