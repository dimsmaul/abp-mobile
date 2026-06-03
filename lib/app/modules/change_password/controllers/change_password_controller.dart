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
      Get.snackbar('Error', 'Semua field wajib diisi');
      return;
    }
    if (next.length < 8) {
      Get.snackbar('Error', 'Password baru minimal 8 karakter');
      return;
    }
    if (next != confirm) {
      Get.snackbar('Error', 'Konfirmasi password tidak cocok');
      return;
    }
    if (next == current) {
      Get.snackbar('Error', 'Password baru harus berbeda dari yang lama');
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
        Get.snackbar('Berhasil', 'Password berhasil diperbarui');
      } else {
        Get.snackbar('Error', 'Gagal memperbarui password');
      }
    } on dio_pkg.DioException catch (e) {
      Get.snackbar('Error', dioErrorMessage(e, 'Gagal memperbarui password'));
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isSubmitting.value = false;
    }
  }
}
