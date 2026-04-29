import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import '../../../data/services/api_service.dart';

class PermitController extends GetxController {
  final apiService = Get.find<ApiService>();

  final permits = <dynamic>[].obs;
  final isLoading = false.obs;

  // Form fields
  final type = 'sick'.obs;
  final descriptionController = TextEditingController();
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    print('[PermitController] Initialized');
    fetchMyPermits();
  }

  Future<void> fetchMyPermits() async {
    isLoading.value = true;
    try {
      final response = await apiService.dio.get('/permits/me');
      if (response.statusCode == 200) {
        // New shape: { message, data: [...] }
        permits.assignAll(response.data['data']);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to fetch permits';
      Get.snackbar("Error", msg);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitPermit() async {
    if (descriptionController.text.isEmpty ||
        startDate.value == null ||
        endDate.value == null) {
      Get.snackbar("Error", "Please fill all fields");
      return;
    }

    isLoading.value = true;
    try {
      final response = await apiService.dio.post('/permits', data: {
        'type': type.value,
        'description': descriptionController.text,
        'startDate': startDate.value!.toIso8601String(),
        'endDate': endDate.value!.toIso8601String(),
      });

      if (response.statusCode == 201) {
        final msg = response.data['message'] ?? 'Permit request submitted';
        Get.snackbar("Success", msg);
        fetchMyPermits();
        Get.back();
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to submit permit';
      Get.snackbar("Error", msg);
    } finally {
      isLoading.value = false;
    }
  }

  void selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) startDate.value = picked;
  }

  void selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate.value ?? DateTime.now(),
      firstDate: startDate.value ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) endDate.value = picked;
  }

  @override
  void onClose() {
    descriptionController.dispose();
    super.onClose();
  }
}
