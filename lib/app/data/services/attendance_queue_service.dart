import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:hive_flutter/hive_flutter.dart';
import 'api_service.dart';

/// Queues attendance check-in / check-out submissions while offline and
/// flushes them automatically once connectivity is restored.
class AttendanceQueueService extends GetxService {
  static const String boxName = 'attendance_queue';
  static const String rejectedBoxName = 'attendance_queue_rejected';

  late final Box _box;
  late final Box _rejectedBox;

  final RxInt pendingCount = 0.obs;
  final _isFlushing = false.obs;

  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void onInit() {
    super.onInit();
    _box = Hive.box(boxName);
    _rejectedBox = Hive.box(rejectedBoxName);
    pendingCount.value = _box.length;

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final hasNet = results.any((r) => r != ConnectivityResult.none);
      if (hasNet && pendingCount.value > 0) {
        // Fire-and-forget; flush is idempotent guarded.
        flush();
      }
    });
  }

  @override
  void onClose() {
    _connSub?.cancel();
    super.onClose();
  }

  Future<void> enqueue({
    required String type,
    required String photoPath,
    required double lat,
    required double lng,
    List<double>? embedding,
  }) async {
    final item = <String, dynamic>{
      'type': type,
      'photoPath': photoPath,
      'latitude': lat,
      'longitude': lng,
      'queuedAt': DateTime.now().toIso8601String(),
      if (embedding != null) 'embedding': embedding,
    };
    await _box.add(item);
    pendingCount.value = _box.length;
  }

  /// Iterate items, attempt to submit each. Successful items are removed;
  /// network failures stay queued; 4xx are moved to rejected box.
  Future<void> flush() async {
    if (_isFlushing.value) return;
    if (_box.isEmpty) {
      pendingCount.value = 0;
      return;
    }
    if (!Get.isRegistered<ApiService>()) return;

    _isFlushing.value = true;
    try {
      final api = Get.find<ApiService>();
      // Copy keys so we can mutate the box during iteration.
      final keys = _box.keys.toList();
      for (final key in keys) {
        final raw = _box.get(key);
        if (raw is! Map) {
          await _box.delete(key);
          continue;
        }
        final item = Map<String, dynamic>.from(raw);
        final photoPath = item['photoPath']?.toString();
        final type = item['type']?.toString();
        if (photoPath == null || type == null) {
          await _box.delete(key);
          continue;
        }

        final file = File(photoPath);
        if (!file.existsSync()) {
          // Photo gone — silently drop.
          await _box.delete(key);
          continue;
        }

        try {
          final fileName = photoPath.split('/').last;
          final rawEmb = item['embedding'];
          final embedding = rawEmb is List
              ? rawEmb.map((e) => (e as num).toDouble()).toList()
              : null;
          final form = dio_pkg.FormData.fromMap({
            'photo': await dio_pkg.MultipartFile.fromFile(
              photoPath,
              filename: fileName,
            ),
            'latitude': item['latitude'],
            'longitude': item['longitude'],
            if (embedding != null) 'faceEmbedding': jsonEncode(embedding),
          });
          final res = type == 'check_in'
              ? await api.checkIn(form)
              : await api.checkOut(form);
          if (res.statusCode == 200 || res.statusCode == 201) {
            await _box.delete(key);
          }
        } on dio_pkg.DioException catch (e) {
          if (_isNetworkError(e)) {
            // Leave queued; stop iterating — likely all will fail.
            break;
          }
          final status = e.response?.statusCode ?? 0;
          if (status >= 400 && status < 500) {
            final reason = dioErrorMessage(e, 'Ditolak server');
            await _rejectedBox.add({
              ...item,
              'rejectedAt': DateTime.now().toIso8601String(),
              'reason': reason,
            });
            await _box.delete(key);
            Get.snackbar(
              'Presensi ditolak',
              reason,
              duration: const Duration(seconds: 4),
            );
          }
          // 5xx → leave queued, try again next time.
        } catch (e) {
          // Unknown error — leave queued.
          debugPrint('[AttendanceQueue] flush item error: $e');
        }
      }
    } finally {
      pendingCount.value = _box.length;
      _isFlushing.value = false;
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
