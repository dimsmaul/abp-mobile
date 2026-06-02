import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:get/get.dart' hide Response;
import 'package:geolocator/geolocator.dart';
import '../../../core/image_utils.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/attendance_queue_service.dart';
import '../../home/controllers/home_controller.dart';

class AttendanceController extends GetxController {
  final apiService = Get.find<ApiService>();
  final attendanceQueueService = Get.find<AttendanceQueueService>();

  final isLoading = false.obs;
  final currentPosition = Rxn<Position>();
  final image = Rxn<File>();

  @override
  void onInit() {
    super.onInit();
    print('[AttendanceController] Initialized');
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar("Error", "Location services are disabled.");
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar("Error", "Location permissions are denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.snackbar("Error", "Location permissions are permanently denied.");
        return;
      }

      currentPosition.value = await Geolocator.getCurrentPosition();
    } catch (e) {
      Get.snackbar("Location Error", "Could not get location: ${e.toString()}");
    }
  }

  Future<void> pickImage() async {
    // Selfie attendance — ML Kit face presence check enforced in camera screen.
    final result = await Get.toNamed('/camera', arguments: {'requireFace': true});
    if (result != null && result is String) {
      image.value = File(result);
    }
  }

  Future<void> submitAttendance(String type) async {
    if (image.value == null) {
      Get.snackbar("Error", "Please take a selfie first");
      return;
    }

    if (currentPosition.value == null) {
      await _getCurrentLocation();
      if (currentPosition.value == null) return;
    }

    isLoading.value = true;
    try {
      final sanitized = await stripExif(File(image.value!.path));
      String fileName = sanitized.path.split('/').last;
      dio_pkg.FormData formData = dio_pkg.FormData.fromMap({
        "photo": await dio_pkg.MultipartFile.fromFile(sanitized.path,
            filename: fileName),
        "latitude": currentPosition.value!.latitude,
        "longitude": currentPosition.value!.longitude,
      });

      final response = await apiService.dio.post(
        type == 'check_in'
            ? '/mobile/attendances/check-in'
            : '/mobile/attendances/check-out',
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = response.data;
        final payload = body is Map && body['data'] is Map ? body['data'] as Map : null;
        final isWithinZone = payload?['isWithinZone'] == true;
        final baseMsg = (body is Map ? body['message'] : null) ?? 'Attendance submitted!';
        final zoneNote = isWithinZone ? 'Dalam zona ✓' : 'Di luar zona ⚠';
        Get.snackbar("Success", '$baseMsg · $zoneNote');
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().refresh();
        }
        Get.offAllNamed('/dashboard');
      }
    } on dio_pkg.DioException catch (e) {
      // Network failure → queue offline & navigate as if accepted.
      if (_isNetworkError(e)) {
        await attendanceQueueService.enqueue(
          type: type,
          photoPath: image.value!.path,
          lat: currentPosition.value!.latitude,
          lng: currentPosition.value!.longitude,
        );
        Get.snackbar(
          "Tersimpan offline",
          "Akan dikirim saat koneksi pulih",
        );
        Get.offAllNamed('/dashboard');
      } else {
        // 4xx/5xx — existing error flow.
        final msg = e.response?.data?['message'] ?? 'Failed to submit attendance';
        Get.snackbar("Error", msg);
      }
    } finally {
      isLoading.value = false;
    }
  }

  bool _isNetworkError(dio_pkg.DioException e) {
    return e.type == dio_pkg.DioExceptionType.connectionError ||
        e.type == dio_pkg.DioExceptionType.connectionTimeout ||
        e.type == dio_pkg.DioExceptionType.receiveTimeout ||
        e.type == dio_pkg.DioExceptionType.sendTimeout ||
        (e.error is SocketException);
  }
}
