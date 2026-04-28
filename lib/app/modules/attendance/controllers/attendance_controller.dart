import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:get/get.dart' hide Response;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/services/api_service.dart';

class AttendanceController extends GetxController {
  final apiService = Get.find<ApiService>();
  
  final isLoading = false.obs;
  final currentPosition = Rxn<Position>();
  final image = Rxn<File>();

  @override
  void onInit() {
    super.onInit();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
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
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );

    if (pickedFile != null) {
      image.value = File(pickedFile.path);
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
        "photo": await dio_pkg.MultipartFile.fromFile(image.value!.path, filename: fileName),
        "latitude": currentPosition.value!.latitude,
        "longitude": currentPosition.value!.longitude,
      });

      final response = await apiService.dio.post(
        type == 'check_in' ? '/mobile/attendances/check-in' : '/mobile/attendances/check-out',
        data: formData,
      );

      if (response.statusCode == 201) {
        Get.snackbar("Success", "Attendance submitted successfully!");
        Get.offAllNamed('/home');
      }
    } on dio_pkg.DioException catch (e) {
      String message = "Failed to submit attendance";
      if (e.response?.data != null && e.response?.data['error'] != null) {
        message = e.response?.data['error']['message'];
      }
      Get.snackbar("Error", message);
    } finally {
      isLoading.value = false;
    }
  }
}
