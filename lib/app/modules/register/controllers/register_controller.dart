import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import '../../../data/controllers/auth_controller.dart';
import '../../../data/services/api_service.dart';

class RegisterController extends GetxController {
  final apiService = Get.find<ApiService>();
  final auth = Get.find<AuthController>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;

  Future<void> register() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar("Error", "Please fill all fields");
      return;
    }

    isLoading.value = true;
    try {
      final response = await apiService.signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        apiService.saveAuthData(response.data);
        auth.user.value = apiService.currentUser;
        auth.isAuthenticated.value = apiService.isLoggedIn;
        Get.snackbar("Success", "Account created successfully!");
        Get.offAllNamed(auth.isAuthenticated.value ? '/dashboard' : '/login');
      }
    } on DioException catch (e) {
      String message = "Registration failed";
      if (e.response?.data != null) {
        message = e.response?.data['message'] ??
            e.response?.data['error']?['message'] ??
            message;
      }
      Get.snackbar("Error", message, snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
