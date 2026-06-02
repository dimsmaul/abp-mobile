import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.location_on,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "FieldTrack",
                        style: textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 36,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Presence & Field Reporting",
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Log in", style: textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text("Welcome back, please sign in to continue",
                        style: textTheme.bodyMedium),
                    const SizedBox(height: 32),
                    TextField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(() => TextField(
                          controller: controller.passwordController,
                          obscureText: controller.obscurePassword.value,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            suffixIcon: IconButton(
                              icon: Icon(controller.obscurePassword.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined),
                              onPressed: controller.toggleObscure,
                            ),
                          ),
                        )),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Get.toNamed('/forget-password'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "Lupa Password?",
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(() => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.login,
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text("Log in"),
                        )),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => Get.toNamed('/register'),
                        child: Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: textTheme.bodyMedium,
                            children: const [
                              TextSpan(
                                text: "Register",
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
