import 'dart:io';

import 'package:dio/dio.dart' as dio_pkg;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/image_utils.dart';
import '../../../data/controllers/auth_controller.dart';
import '../../../data/services/api_service.dart';

class ProfileController extends GetxController {
  final api = Get.find<ApiService>();
  final auth = Get.find<AuthController>();

  final isUploadingAvatar = false.obs;
  final isSavingProfile = false.obs;

  Map? get user => auth.user.value;

  // ── Edit name/department ──────────────────────────
  Future<bool> saveProfile({String? name, String? department}) async {
    isSavingProfile.value = true;
    try {
      final res = await api.updateProfile(name: name, department: department);
      if (res.statusCode == 200 && res.data != null) {
        final body = res.data;
        final root =
            body is Map && body['data'] is Map ? body['data'] as Map : body;
        if (root is Map) {
          _mergeUserUpdate(Map<String, dynamic>.from(root));
        }
        Get.snackbar('Success', 'Profil diperbarui');
        return true;
      }
      Get.snackbar('Error', 'Gagal memperbarui profil');
      return false;
    } on dio_pkg.DioException catch (e) {
      Get.snackbar('Error', dioErrorMessage(e, 'Gagal memperbarui profil'));
      return false;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isSavingProfile.value = false;
    }
  }

  // ── Avatar via camera ─────────────────────────────
  Future<void> pickAndUploadProfilePicture() async {
    final result = await Get.toNamed('/camera');
    if (result is String && result.isNotEmpty) {
      await _uploadPhoto(result);
    }
  }

  // ── Avatar via gallery ────────────────────────────
  // Profile avatar only — attendance + reports stay camera-only (M-03).
  Future<void> pickFromGalleryAndUpload() async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 85,
      );
      if (picked == null) return;
      await _uploadPhoto(picked.path);
    } catch (e) {
      Get.snackbar('Error', 'Gagal membuka galeri: $e');
    }
  }

  Future<void> _uploadPhoto(String imagePath) async {
    isUploadingAvatar.value = true;
    try {
      File file = File(imagePath);
      try {
        // Avatar: cap at 1080px longest side, JPEG q80 → typically <300KB.
        // Keeps BE 5MB limit comfortable and avoids upload timeouts on 3G.
        file = await stripExif(file, maxDimension: 1080, quality: 80);
      } catch (_) {
        // EXIF strip best-effort; keep original on failure.
      }

      final fileName = file.path.split('/').last;
      final form = dio_pkg.FormData.fromMap({
        'photo': await dio_pkg.MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final res = await api.uploadAvatar(form);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = res.data;
        final root =
            body is Map && body['data'] is Map ? body['data'] as Map : body;
        String? imageUrl;
        if (root is Map && root['imageUrl'] is String) {
          imageUrl = root['imageUrl'] as String;
        }
        if (imageUrl != null && imageUrl.isNotEmpty) {
          _mergeUserUpdate({'image': imageUrl});
        }
        Get.snackbar('Success', 'Foto profil diperbarui');
      } else {
        Get.snackbar('Error', 'Gagal mengunggah foto');
      }
    } on dio_pkg.DioException catch (e) {
      Get.snackbar('Error', dioErrorMessage(e, 'Gagal mengunggah foto'));
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  // Merge partial user fields into local state + Hive so UI reflects + survives reload.
  void _mergeUserUpdate(Map<String, dynamic> patch) {
    final current = Map<String, dynamic>.from(auth.user.value ?? const {});
    current.addAll(patch);
    auth.user.value = current;
    api.box.put('user', current);
  }

  Future<void> logout() async {
    await auth.signOut();
    Get.offAllNamed('/login');
  }
}
