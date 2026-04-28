import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';
import '../../../data/services/api_service.dart';

class LoginController extends GetxController {
  final apiService = Get.find<ApiService>();
  final storage = GetStorage();

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
      final response = await apiService.dio.post('/auth/login', data: {
        'email': emailController.text,
        'password': passwordController.text,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final user = response.data['user'];
        
        await storage.write('token', token);
        await storage.write('user', user);
        
        Get.offAllNamed('/home');
      }
    } on DioException catch (e) {
      String message = "Login failed";
      if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
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
