import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart';
import 'app/core/theme.dart';
import 'app/data/services/api_service.dart';
import 'app/routes/app_pages.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('auth');

  try {
    cameras = await availableCameras();
  } catch (e) {
    print('Error initializing cameras: $e');
  }

  final apiService = Get.put(ApiService());

  // Determine initial route based on stored session
  final initialRoute = apiService.isLoggedIn ? '/home' : '/login';

  runApp(
    GetMaterialApp(
      title: "FieldTrack",
      theme: AppTheme.darkTheme,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    ),
  );
}
