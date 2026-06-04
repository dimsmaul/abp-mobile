import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/api_service.dart';

class ChangePasswordController extends GetxController {
  final api = Get.find<ApiService>();

  final currentCtl = TextEditingController();
  final newCtl = TextEditingController();
  final confirmCtl = TextEditingController();

  final obscureCurrent = true.obs;
  final obscureNew = true.obs;
  final obscureConfirm = true.obs;
  final isSubmitting = false.obs;
  final revokeOtherSessions = true.obs;

  @override
  void onClose() {
    currentCtl.dispose();
    newCtl.dispose();
    confirmCtl.dispose();
    super.onClose();
  }

  Future<void> submit() async {
    final current = currentCtl.text;
    final next = newCtl.text;
    final confirm = confirmCtl.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      Get.snackbar('Error', 'All fields are required');
      return;
    }
    if (next.length < 8) {
      Get.snackbar('Error', 'New password must be at least 8 characters');
      return;
    }
    if (next != confirm) {
      Get.snackbar('Error', 'Password confirmation does not match');
      return;
    }
    if (next == current) {
      Get.snackbar('Error', 'New password must differ from the current one');
      return;
    }

    isSubmitting.value = true;
    try {
      final res = await api.changePassword(
        currentPassword: current,
        newPassword: next,
        revokeOtherSessions: revokeOtherSessions.value,
      );
      if (res.statusCode == 200) {
        Get.back();
        Get.snackbar('Success', 'Password updated successfully');
      } else {
        Get.snackbar('Error', 'Failed to update password');
      }
    } on dio_pkg.DioException catch (e) {
      Get.snackbar('Error', dioErrorMessage(e, 'Failed to update password'));
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }
}
