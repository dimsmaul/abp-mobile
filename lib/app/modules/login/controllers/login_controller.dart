import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import '../../../data/services/api_service.dart';

class LoginController extends GetxController {
  final apiService = Get.find<ApiService>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Error", "Please fill all fields");
      return;
    }

    isLoading.value = true;
    try {
      final response = await apiService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (response.statusCode == 200) {
        // better-auth response: { user: {...}, session: { token: "..." } }
        apiService.saveAuthData(response.data);
        Get.offAllNamed('/home');
      }
    } on DioException catch (e) {
      String message = "Login failed";
      if (e.response?.data != null) {
        // better-auth error: { message: "..." } or { error: { message: "..." } }
        message = e.response?.data['message'] ??
            e.response?.data['error']?['message'] ??
            message;
      }
      Get.snackbar("Login Error", message, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
