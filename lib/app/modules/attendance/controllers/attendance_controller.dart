import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:get/get.dart' hide Response;
import 'package:geolocator/geolocator.dart';
import '../../../data/services/api_service.dart';
import '../../home/controllers/home_controller.dart';

class AttendanceController extends GetxController {
  final apiService = Get.find<ApiService>();

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
    final result = await Get.toNamed('/camera');
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
      String fileName = image.value!.path.split('/').last;
      dio_pkg.FormData formData = dio_pkg.FormData.fromMap({
        "photo": await dio_pkg.MultipartFile.fromFile(image.value!.path,
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

      if (response.statusCode == 201) {
        final msg = response.data['message'] ?? 'Attendance submitted!';
        Get.snackbar("Success", msg);
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().refresh();
        }
        Get.offAllNamed('/dashboard');
      }
    } on dio_pkg.DioException catch (e) {
      // New error shape: { message, error: { code, ... } }
      final msg = e.response?.data?['message'] ?? 'Failed to submit attendance';
      Get.snackbar("Error", msg);
    } finally {
      isLoading.value = false;
    }
  }
}
