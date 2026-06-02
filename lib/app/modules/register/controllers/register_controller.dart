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
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar("Error", "Please fill all fields");
      return;
    }
    if (passwordController.text.length < 8) {
      Get.snackbar("Error", "Password minimum 8 characters");
      return;
    }

    isLoading.value = true;
    try {
      await auth.signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      Get.snackbar("Success", "Account created successfully!");
      Get.offAllNamed(auth.isAuthenticated.value ? '/dashboard' : '/login');
    } on DioException catch (e) {
      Get.snackbar(
        "Error",
        dioErrorMessage(e, 'Registration failed'),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
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
