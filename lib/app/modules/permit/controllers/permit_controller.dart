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

  // Leave balance snapshot for the current year. Populated best-effort on
  // init so the UI can show remaining cuti and the form can preflight a
  // sufficient-balance check before hitting the network.
  final Rxn<Map> leaveBalance = Rxn<Map>();

  @override
  void onInit() {
    super.onInit();
    fetchMyPermits();
    loadLeaveBalance();
  }

  Future<void> loadLeaveBalance() async {
    try {
      final response = await apiService.fetchMyLeaveBalance();
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data is Map) leaveBalance.value = Map<String, dynamic>.from(data);
      }
    } catch (_) {
      // Swallow: balance is an enhancement, not blocking permit submission.
    }
  }

  /// Count working days (Mon-Fri) inclusive between two dates. Mirrors the
  /// backend formula so the client preflight matches server validation.
  int countWorkingDays(DateTime start, DateTime end) {
    final a = DateTime(start.year, start.month, start.day);
    final b = DateTime(end.year, end.month, end.day);
    if (b.isBefore(a)) return 0;
    var count = 0;
    var cursor = a;
    while (!cursor.isAfter(b)) {
      final wd = cursor.weekday; // 1 = Mon, 7 = Sun
      if (wd != DateTime.saturday && wd != DateTime.sunday) count++;
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }

  /// Returns an error message if cuti submission would exceed balance,
  /// or null if it's fine / not applicable.
  String? validateLeaveBalance() {
    if (type.value != 'leave') return null;
    if (startDate.value == null || endDate.value == null) return null;
    final balance = leaveBalance.value;
    if (balance == null) return null;
    final remaining = (balance['remainingDays'] as num?)?.toDouble() ?? 0;
    final requested = countWorkingDays(startDate.value!, endDate.value!);
    if (requested > remaining) {
      return 'Sisa cuti $remaining hari, butuh $requested hari kerja';
    }
    return null;
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

    final balanceError = validateLeaveBalance();
    if (balanceError != null) {
      Get.snackbar("Saldo cuti tidak cukup", balanceError);
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
        // Server may have charged the balance; refresh to reflect new used_days.
        loadLeaveBalance();
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
