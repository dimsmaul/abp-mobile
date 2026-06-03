import 'dart:io';

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

/// Some Android trust stores fail to validate Cloudflare's intermediate cert
/// when serving R2's `*.r2.dev` and `*.r2.cloudflarestorage.com` hosts,
/// surfacing as `CERTIFICATE_VERIFY_FAILED: unable to get local issuer
/// certificate`. Whitelist those hosts only — every other origin still goes
/// through the system trust chain.
class _R2TrustOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return host.endsWith('.r2.dev') ||
            host.endsWith('.r2.cloudflarestorage.com');
      };
  }
}

void main() async {
  HttpOverrides.global = _R2TrustOverride();
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
