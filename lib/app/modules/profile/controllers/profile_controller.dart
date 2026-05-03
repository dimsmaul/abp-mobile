import 'package:dio/dio.dart' as dio_pkg;
import 'package:get/get.dart';
import '../../../data/controllers/auth_controller.dart';
import '../../../data/services/api_service.dart';

class ProfileController extends GetxController {
  final api = Get.find<ApiService>();
  final auth = Get.find<AuthController>();

  final isUploading = false.obs;

  Map? get user => auth.user.value;

  Future<void> pickAndUploadProfilePicture() async {
    final result = await Get.toNamed('/camera');
    if (result is String) await _uploadPhoto(result);
  }

  Future<void> _uploadPhoto(String imagePath) async {
    isUploading.value = true;
    try {
      final fileName = imagePath.split('/').last;
      final form = dio_pkg.FormData.fromMap({
        "photo": await dio_pkg.MultipartFile.fromFile(imagePath,
            filename: fileName),
      });
      final res =
          await api.dio.post('/user/profile-picture', data: form);
      if (res.statusCode == 200 || res.statusCode == 201) {
        Get.snackbar("Success", "Profile picture updated");
      }
    } catch (_) {
      Get.snackbar("Notice", "Picture captured. Endpoint not ready.");
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> logout() async {
    await auth.signOut();
    Get.offAllNamed('/login');
  }
}
