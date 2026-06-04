import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:geolocator/geolocator.dart';
import '../../../core/image_utils.dart';
import '../../../core/theme.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/attendance_queue_service.dart';
import '../../home/controllers/home_controller.dart';

class AttendanceController extends GetxController {
  final apiService = Get.find<ApiService>();
  final attendanceQueueService = Get.find<AttendanceQueueService>();

  final isLoading = false.obs;
  final currentPosition = Rxn<Position>();
  final image = Rxn<File>();
  final faceEmbedding = Rxn<List<double>>();

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
    // Selfie attendance — liveness challenge + face embedding generated in
    // camera screen. Result shape: { path: String, embedding: List<double>? }.
    final result = await Get.toNamed('/camera', arguments: {'requireFace': true});
    if (result is Map) {
      final path = result['path'];
      if (path is String && path.isNotEmpty) {
        image.value = File(path);
      }
      final emb = result['embedding'];
      if (emb is List) {
        faceEmbedding.value = emb.map((e) => (e as num).toDouble()).toList();
      } else {
        faceEmbedding.value = null;
      }
    }
  }

  Future<void> submitAttendance(String type) async {
    if (image.value == null) {
      _showResultDialog(
        success: false,
        title: 'Belum Ada Foto',
        message: 'Ambil selfie terlebih dahulu sebelum submit.',
      );
      return;
    }

    if (currentPosition.value == null) {
      _showLoadingDialog('Mengambil lokasi…');
      await _getCurrentLocation();
      _closeLoadingDialog();
      if (currentPosition.value == null) {
        _showResultDialog(
          success: false,
          title: 'Lokasi Belum Siap',
          message: 'Pastikan GPS aktif dan coba lagi.',
        );
        return;
      }
    }

    isLoading.value = true;
    _showLoadingDialog('Memverifikasi & mengirim…');
    try {
      // Selfie: 1280px max, JPEG q80 — still readable for watermark + face.
      final sanitized = await stripExif(File(image.value!.path),
          maxDimension: 1280, quality: 80);
      String fileName = sanitized.path.split('/').last;
      final embedding = faceEmbedding.value;
      dio_pkg.FormData formData = dio_pkg.FormData.fromMap({
        "photo": await dio_pkg.MultipartFile.fromFile(sanitized.path,
            filename: fileName),
        "latitude": currentPosition.value!.latitude,
        "longitude": currentPosition.value!.longitude,
        if (embedding != null) "faceEmbedding": jsonEncode(embedding),
      });

      final response = await apiService.dio.post(
        type == 'check_in'
            ? '/mobile/attendances/check-in'
            : '/mobile/attendances/check-out',
        data: formData,
      );

      _closeLoadingDialog();

      if (response.statusCode == 201 || response.statusCode == 200) {
        final body = response.data;
        final payload =
            body is Map && body['data'] is Map ? body['data'] as Map : null;
        final isWithinZone = payload?['isWithinZone'] == true;
        final score = (payload?['faceScore'] as num?)?.toDouble();
        final baseMsg = (body is Map ? body['message'] : null) ??
            'Presensi berhasil dikirim';
        final lines = <String>[
          baseMsg,
          isWithinZone ? '✓ Dalam zona kantor' : '⚠ Di luar zona kantor',
          if (score != null)
            '✓ Wajah cocok (skor ${score.toStringAsFixed(3)})',
        ];
        await _showResultDialog(
          success: true,
          title: type == 'check_in' ? 'Check-in Berhasil' : 'Check-out Berhasil',
          message: lines.join('\n'),
        );
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().refresh();
        }
        Get.offAllNamed('/dashboard');
      }
    } on dio_pkg.DioException catch (e) {
      _closeLoadingDialog();
      if (_isNetworkError(e)) {
        await attendanceQueueService.enqueue(
          type: type,
          photoPath: image.value!.path,
          lat: currentPosition.value!.latitude,
          lng: currentPosition.value!.longitude,
          embedding: faceEmbedding.value,
        );
        await _showResultDialog(
          success: true,
          title: 'Tersimpan Offline',
          message: 'Tidak ada koneksi. Presensi akan dikirim otomatis '
              'saat koneksi pulih.',
        );
        Get.offAllNamed('/dashboard');
      } else {
        final data = e.response?.data;
        final msg = (data is Map ? data['message'] : null) ??
            'Gagal mengirim presensi';
        final errBlock = data is Map && data['error'] is Map
            ? data['error'] as Map
            : null;
        final code = errBlock?['code']?.toString();
        final details = errBlock?['details'];
        final score = details is Map
            ? (details['score'] as num?)?.toDouble()
            : null;
        final threshold = details is Map
            ? (details['threshold'] as num?)?.toDouble()
            : null;
        final extra = <String>[];
        if (code != null) extra.add('Kode: $code');
        if (score != null && threshold != null) {
          extra.add(
            'Skor wajah ${score.toStringAsFixed(3)} (minimum ${threshold.toStringAsFixed(2)})',
          );
        }
        await _showResultDialog(
          success: false,
          title: 'Presensi Gagal',
          message: [msg, ...extra].join('\n'),
        );
      }
    } catch (e) {
      _closeLoadingDialog();
      await _showResultDialog(
        success: false,
        title: 'Error',
        message: e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _showLoadingDialog(String message) {
    if (Get.isDialogOpen ?? false) return;
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 2.5,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _closeLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  Future<void> _showResultDialog({
    required bool success,
    required String title,
    required String message,
  }) {
    return Get.dialog(
      Dialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    success ? Icons.check_circle : Icons.error_outline,
                    color: success ? AppTheme.success : AppTheme.danger,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    if (Get.isDialogOpen ?? false) Get.back();
                  },
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  bool _isNetworkError(dio_pkg.DioException e) {
    return e.type == dio_pkg.DioExceptionType.connectionError ||
        e.type == dio_pkg.DioExceptionType.connectionTimeout ||
        e.type == dio_pkg.DioExceptionType.receiveTimeout ||
        e.type == dio_pkg.DioExceptionType.sendTimeout ||
        (e.error is SocketException);
  }
}
