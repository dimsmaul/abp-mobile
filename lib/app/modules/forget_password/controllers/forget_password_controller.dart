import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import '../../../data/services/api_service.dart';

class ForgetPasswordController extends GetxController {
  final apiService = Get.find<ApiService>();

  final emailController = TextEditingController();
  final isLoading = false.obs;

  Future<void> submit() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar("Error", "Please enter your email",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (!GetUtils.isEmail(email)) {
      Get.snackbar("Error", "Invalid email format",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    try {
      await apiService.forgetPassword(email);
      Get.snackbar(
        "Success",
        "Cek email Anda untuk tautan reset",
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } on DioException catch (e) {
      Get.snackbar(
        "Error",
        dioErrorMessage(e, 'Failed to send reset email'),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
