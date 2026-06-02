import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart';
import 'app/core/theme.dart';
import 'app/data/controllers/auth_controller.dart';
import 'app/data/services/api_service.dart';
import 'app/data/services/attendance_queue_service.dart';
import 'app/routes/app_pages.dart';

List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('auth');
  await Hive.openBox('attendance_queue');
  await Hive.openBox('attendance_queue_rejected');

  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Camera init error: $e');
  }

  Get.put<ApiService>(ApiService(), permanent: true);
  Get.put<AuthController>(AuthController(), permanent: true);
  Get.put<AttendanceQueueService>(AttendanceQueueService(), permanent: true);

  // Best-effort initial flush in case queued items remain from a previous run.
  // ignore: discarded_futures
  Get.find<AttendanceQueueService>().flush().catchError((_) {});

  runApp(
    GetMaterialApp(
      title: "FieldTrack",
      theme: AppTheme.lightTheme,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    ),
  );
}
