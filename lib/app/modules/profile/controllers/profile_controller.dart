import 'dart:io';

import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart' show Color;
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/dialogs.dart';
import '../../../core/face_embed.dart';
import '../../../core/image_utils.dart';
import '../../../core/theme.dart';
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
        Get.snackbar('Success', 'Profile updated');
        return true;
      }
      Get.snackbar('Error', 'Failed to update profile');
      return false;
    } on dio_pkg.DioException catch (e) {
      Get.snackbar('Error', dioErrorMessage(e, 'Failed to update profile'));
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
      final cropped = await _cropSquare(result);
      if (cropped != null) await _uploadPhoto(cropped);
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
      final cropped = await _cropSquare(picked.path);
      if (cropped != null) await _uploadPhoto(cropped);
    } catch (e) {
      Get.snackbar('Error', 'Failed to open gallery: $e');
    }
  }

  /// Open a square 1:1 cropper. Returns the path of the cropped file, or null
  /// if the user cancelled.
  Future<String?> _cropSquare(String sourcePath) async {
    try {
      final res = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Photo',
            toolbarColor: AppTheme.primary,
            toolbarWidgetColor: const Color(0xFFFFFFFF),
            statusBarColor: AppTheme.primaryDark,
            activeControlsWidgetColor: AppTheme.primary,
            backgroundColor: const Color(0xFF000000),
            lockAspectRatio: true,
            aspectRatioPresets: [CropAspectRatioPreset.square],
            initAspectRatio: CropAspectRatioPreset.square,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Adjust Photo',
            aspectRatioLockEnabled: true,
            aspectRatioPickerButtonHidden: true,
            resetAspectRatioEnabled: false,
            aspectRatioPresets: [CropAspectRatioPreset.square],
          ),
        ],
      );
      return res?.path;
    } catch (e) {
      Get.snackbar('Error', 'Failed to process photo: $e');
      return null;
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
          debugPrint('[profile] avatar uploaded: $imageUrl');
          _mergeUserUpdate({'image': imageUrl});
        }

        // Avatar IS the face reference — derive the embedding from the
        // same photo and enroll it. If ML Kit can't see a face in the
        // photo the user just picked, we surface a blocking dialog rather
        // than a passive snackbar so they actually notice and re-upload —
        // otherwise the attendance check-in keeps rejecting them with
        // "FACE_NOT_ENROLLED" and they have no idea why.
        final enrollOk = await _enrollFaceFrom(file.path);
        if (enrollOk) {
          Get.snackbar(
            'Success',
            'Profile photo and face verification saved',
          );
        } else {
          await showAppResultDialog(
            success: false,
            title: 'Face Not Detected',
            message:
                'Your profile photo was saved but the system could not '
                'find a face in it. Please replace it with a photo that:\n'
                '• Faces the camera (frontal)\n'
                '• Has good lighting\n'
                '• Contains only one person (yourself)\n\n'
                'Without a readable face, attendance check-in will fail.',
            okLabel: 'OK',
          );
        }
      } else {
        Get.snackbar('Error', 'Failed to upload photo');
      }
    } on dio_pkg.DioException catch (e) {
      Get.snackbar('Error', dioErrorMessage(e, 'Failed to upload photo'));
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

  /// Extract a face embedding from [imagePath] and POST it to
  /// /mobile/me/face. Returns true on success — caller surfaces a result
  /// dialog when this returns false so the user can re-upload a clearer
  /// photo before the next attendance attempt.
  Future<bool> _enrollFaceFrom(String imagePath) async {
    try {
      final embedding =
          await FaceEmbedder.instance.embedFromFile(imagePath);
      if (embedding == null) {
        debugPrint('[profile] no face detected in avatar — skip enroll');
        return false;
      }
      final res = await api.enrollFace(embedding.toList());
      if (res.statusCode == 200 || res.statusCode == 201) {
        _mergeUserUpdate({'faceRecognitionEnabled': true});
        return true;
      }
      debugPrint(
        '[profile] enrollFace HTTP ${res.statusCode} body=${res.data}',
      );
      return false;
    } catch (e) {
      debugPrint('[profile] face enroll error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await auth.signOut();
    Get.offAllNamed('/login');
  }
}
