import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:image_picker/image_picker.dart';

import '../../../data/services/api_service.dart';

class PermitController extends GetxController {
  final apiService = Get.find<ApiService>();

  final permits = <Map>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;

  // ── Detail state ────────────────────────────────────────
  final detail = Rxn<Map>();
  final isDetailLoading = false.obs;

  // ── Form fields ─────────────────────────────────────────
  // Default 'leave' per multi-type spec (was 'sick' before).
  final type = 'leave'.obs;
  final descriptionController = TextEditingController();
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  // Type-specific fields. Only the relevant fields per type are read at
  // submit time; the rest are ignored so reusing the same controller for
  // different categories doesn't bleed data.
  final overtimeHoursController = TextEditingController();
  final amountController = TextEditingController(); // reimburse + loan (IDR)
  final tenorMonthsController = TextEditingController(); // loan
  final receiptImage = Rxn<File>();
  final eventDate = Rxn<DateTime>(); // overtime + reimburse single-date

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
      return 'Remaining leave $remaining days, requested $requested working days';
    }
    return null;
  }

  /// Open detail view for a permit by id. Clears prior state + navigates
  /// immediately so the view renders a skeleton instead of stale data.
  Future<void> openDetail(String id) async {
    detail.value = null;
    isDetailLoading.value = true;
    Get.toNamed('/permit/detail', arguments: id);
    try {
      final res = await apiService.fetchPermitDetail(id);
      if (res.statusCode == 200) {
        detail.value = Map<String, dynamic>.from(res.data['data'] as Map);
      }
    } on DioException catch (e) {
      Get.snackbar('Error', dioErrorMessage(e, 'Failed to load permit'));
    } finally {
      isDetailLoading.value = false;
    }
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
      Get.snackbar('Error', dioErrorMessage(e, 'Failed to fetch requests'));
    } finally {
      isLoading.value = false;
    }
  }

  /// True when the active type uses a date range (start + end).
  bool get _usesDateRange =>
      type.value == 'leave' || type.value == 'sick' || type.value == 'permit';

  /// True when the active type uses a single event date.
  bool get _usesSingleDate =>
      type.value == 'overtime' || type.value == 'reimburse';

  Future<void> submitPermit() async {
    final desc = descriptionController.text.trim();
    if (desc.isEmpty) {
      Get.snackbar('Error', 'Please fill in the description');
      return;
    }
    if (desc.length < 10) {
      Get.snackbar('Error', 'Description must be at least 10 characters');
      return;
    }

    // Per-type validation.
    if (_usesDateRange) {
      if (startDate.value == null || endDate.value == null) {
        Get.snackbar('Error', 'Please pick both start and end dates');
        return;
      }
    } else if (_usesSingleDate) {
      if (eventDate.value == null) {
        Get.snackbar('Error', 'Please pick a date');
        return;
      }
    }

    if (type.value == 'overtime') {
      final hours = double.tryParse(overtimeHoursController.text.trim());
      if (hours == null || hours <= 0) {
        Get.snackbar('Error', 'Please enter overtime hours');
        return;
      }
    }
    if (type.value == 'reimburse') {
      final amount = _parseAmount(amountController.text);
      if (amount == null || amount <= 0) {
        Get.snackbar('Error', 'Please enter the reimbursement amount');
        return;
      }
    }
    if (type.value == 'loan') {
      final amount = _parseAmount(amountController.text);
      if (amount == null || amount <= 0) {
        Get.snackbar('Error', 'Please enter the loan amount');
        return;
      }
      final tenor = int.tryParse(tenorMonthsController.text.trim());
      if (tenor == null || tenor <= 0) {
        Get.snackbar('Error', 'Please enter the loan tenor (months)');
        return;
      }
    }

    final balanceError = validateLeaveBalance();
    if (balanceError != null) {
      Get.snackbar('Insufficient leave balance', balanceError);
      return;
    }

    isSubmitting.value = true;
    try {
      // BE has two columns: legacy `type` (sick/leave/permit) and the newer
      // `category` (adds overtime/reimburse/loan). For the new categories
      // we send type='permit' as the legacy placeholder and put the real
      // value in `category`. Field names must match the BE Zod schema.
      const legacyTypes = {'leave', 'sick', 'permit'};
      final isLegacy = legacyTypes.contains(type.value);
      final body = <String, dynamic>{
        'type': isLegacy ? type.value : 'permit',
        'category': type.value,
        'description': desc,
      };

      // BE requires startDate + endDate for every category. For single-date
      // types we send the same date twice; loan has no date in the UI so we
      // fall back to today.
      if (_usesDateRange) {
        body['startDate'] = startDate.value!.toIso8601String();
        body['endDate'] = endDate.value!.toIso8601String();
      } else if (_usesSingleDate) {
        final iso = eventDate.value!.toIso8601String();
        body['startDate'] = iso;
        body['endDate'] = iso;
      } else {
        final iso = DateTime.now().toIso8601String();
        body['startDate'] = iso;
        body['endDate'] = iso;
      }

      if (type.value == 'overtime') {
        body['overtimeHours'] =
            double.tryParse(overtimeHoursController.text.trim()) ?? 0;
      }
      if (type.value == 'reimburse') {
        body['reimburseAmount'] = _parseAmount(amountController.text) ?? 0;
      }
      if (type.value == 'loan') {
        body['loanAmount'] = _parseAmount(amountController.text) ?? 0;
        body['loanTenorMonths'] =
            int.tryParse(tenorMonthsController.text.trim()) ?? 0;
      }

      Response response;
      final receipt = receiptImage.value;
      if (type.value == 'reimburse' && receipt != null) {
        // Receipt photo upload → multipart.
        final form = FormData.fromMap({
          ...body,
          'receipt': await MultipartFile.fromFile(
            receipt.path,
            filename: receipt.path.split('/').last,
          ),
        });
        response = await apiService.submitPermit(form);
      } else {
        response = await apiService.submitPermit(body);
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final msg = response.data['message'] ?? 'Request submitted';
        // Close the bottom sheet FIRST. Two reasons:
        //  1. _resetForm() flips `type` back to 'leave', which would otherwise
        //     rebuild the visible form into the wrong category for a frame.
        //  2. Showing the snackbar before Get.back() can cause Get.back to
        //     dismiss the snackbar overlay instead of the sheet on some
        //     GetX configurations.
        if (Get.isBottomSheetOpen ?? false) Get.back();
        Get.snackbar('Success', msg);
        _resetForm();
        fetchMyPermits();
        // Server may have charged the balance; refresh to reflect new used_days.
        loadLeaveBalance();
      }
    } on DioException catch (e) {
      Get.snackbar('Error', dioErrorMessage(e, 'Failed to submit request'));
    } finally {
      isSubmitting.value = false;
    }
  }

  void _resetForm() {
    descriptionController.clear();
    startDate.value = null;
    endDate.value = null;
    eventDate.value = null;
    overtimeHoursController.clear();
    amountController.clear();
    tenorMonthsController.clear();
    receiptImage.value = null;
    type.value = 'leave';
  }

  /// Accept "Rp 1.000.000", "1,000,000", "1000000" — strip non-digits.
  double? _parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  Future<void> pickReceiptFromCamera() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        imageQuality: 85,
      );
      if (picked != null) receiptImage.value = File(picked.path);
    } catch (e) {
      Get.snackbar('Error', 'Failed to open camera: $e');
    }
  }

  Future<void> pickReceiptFromGallery() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 85,
      );
      if (picked != null) receiptImage.value = File(picked.path);
    } catch (e) {
      Get.snackbar('Error', 'Failed to open gallery: $e');
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

  void selectEventDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      // Overtime + reimburse are typically backdated, allow last 90 days.
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) eventDate.value = picked;
  }

  @override
  void onClose() {
    descriptionController.dispose();
    overtimeHoursController.dispose();
    amountController.dispose();
    tenorMonthsController.dispose();
    super.onClose();
  }
}
