import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import '../../../data/services/api_service.dart';

class PermitController extends GetxController {
  final apiService = Get.find<ApiService>();

  final permits = <Map>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;

  // Form fields
  final type = 'sick'.obs;
  final descriptionController = TextEditingController();
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  @override
  void onInit() {
    super.onInit();
    fetchMyPermits();
  }

  Future<void> fetchMyPermits() async {
    isLoading.value = true;
    try {
      final response = await apiService.fetchMyPermits();
      if (response.statusCode == 200) {
        // BE shape: { message, data: { items: [...], meta: {...} } }
        // Tolerate older { message, data: [...] } shape as fallback.
        final raw = response.data['data'];
        final list = raw is Map ? raw['items'] : raw;
        permits.assignAll(List<Map>.from((list as List?) ?? const []));
      }
    } on DioException catch (e) {
      Get.snackbar("Error", dioErrorMessage(e, 'Failed to fetch permits'));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitPermit() async {
    if (descriptionController.text.trim().isEmpty ||
        startDate.value == null ||
        endDate.value == null) {
      Get.snackbar("Error", "Please fill all fields");
      return;
    }

    if (descriptionController.text.trim().length < 10) {
      Get.snackbar("Error", "Description must be at least 10 characters");
      return;
    }

    isSubmitting.value = true;
    try {
      final response = await apiService.submitPermit({
        'type': type.value,
        'description': descriptionController.text.trim(),
        'startDate': startDate.value!.toIso8601String(),
        'endDate': endDate.value!.toIso8601String(),
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final msg = response.data['message'] ?? 'Permit request submitted';
        Get.snackbar("Success", msg);
        // Reset form
        descriptionController.clear();
        startDate.value = null;
        endDate.value = null;
        type.value = 'sick';
        fetchMyPermits();
        Get.back();
      }
    } on DioException catch (e) {
      Get.snackbar("Error", dioErrorMessage(e, 'Failed to submit permit'));
    } finally {
      isSubmitting.value = false;
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
