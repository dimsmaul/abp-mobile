import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import '../../../data/controllers/auth_controller.dart';

class LoginController extends GetxController {
  final auth = Get.find<AuthController>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;
  final obscurePassword = true.obs;

  void toggleObscure() => obscurePassword.value = !obscurePassword.value;

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Please fill all fields",
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
      await auth.signIn(email: email, password: password);
      if (auth.isAuthenticated.value) {
        Get.offAllNamed('/dashboard');
      } else {
        Get.snackbar("Login Error",
            "Token not returned. Please try again.",
            snackPosition: SnackPosition.BOTTOM);
      }
    } on DioException catch (e) {
      String message = "Login failed";
      if (e.response?.data != null) {
        message = e.response?.data['message'] ??
            e.response?.data['error']?['message'] ??
            message;
      }
      Get.snackbar("Login Error", message,
          snackPosition: SnackPosition.BOTTOM);
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
