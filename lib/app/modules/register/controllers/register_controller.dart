import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import '../../../data/services/api_service.dart';

class RegisterController extends GetxController {
  final apiService = Get.find<ApiService>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs;

  Future<void> register() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar("Error", "Please fill all fields");
      return;
    }

    isLoading.value = true;
    try {
      final response = await apiService.dio.post('/auth/register', data: {
        'name': nameController.text,
        'email': emailController.text,
        'password': passwordController.text,
      });

      if (response.statusCode == 201) {
        Get.snackbar("Success", "Account created successfully! Please login.");
        Get.offNamed('/login');
      }
    } on DioException catch (e) {
      String message = "Registration failed";
      if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
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
