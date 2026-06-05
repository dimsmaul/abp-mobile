import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:hive_flutter/hive_flutter.dart';
import '../env/env.dart';

class ApiService extends GetxService {
  late Dio _dio;
  final box = Hive.box('auth');

  static const String baseUrl = Env.baseUrl;

  Dio get dio => _dio;

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      // Multipart uploads (avatar / report photo) need a generous receive
      // window on mobile networks. R2 PUT round-trips can take 20-30s on 3G.
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = box.get('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          options.headers['Cookie'] =
              'better-auth.session_token=$token; __Secure-better-auth.session_token=$token';
        }
        // Don't override multipart Content-Type set by Dio
        if (options.data is! FormData) {
          options.headers['Content-Type'] = 'application/json';
        }
        // Timing probe — fires on every request to expose slow round-trips.
        // Stash the start timestamp on the request's `extra` map so the
        // response/error interceptors below can measure duration.
        options.extra['_startMs'] = DateTime.now().millisecondsSinceEpoch;
        // ignore: avoid_print
        print('[dio] → ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final start = response.requestOptions.extra['_startMs'];
        if (start is int) {
          final ms = DateTime.now().millisecondsSinceEpoch - start;
          // ignore: avoid_print
          print(
              '[dio] ← ${response.statusCode} ${response.requestOptions.uri} ${ms}ms');
        }
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        final start = e.requestOptions.extra['_startMs'];
        if (start is int) {
          final ms = DateTime.now().millisecondsSinceEpoch - start;
          // ignore: avoid_print
          print(
              '[dio] ✕ ${e.response?.statusCode ?? e.type.name} ${e.requestOptions.uri} ${ms}ms');
        }
        if (e.response?.statusCode == 401) {
          _handleSessionExpired();
        }
        return handler.next(e);
      },
    ));
  }

  /// Centralized expired-session handler. Called from the 401 interceptor.
  /// Wipes local auth and bounces the user to /login, skipping if already
  /// on a public route or mid-bootstrap.
  void _handleSessionExpired() {
    clearAuthData();
    final route = Get.currentRoute;
    const publicRoutes = {
      '/login',
      '/register',
      '/splash',
      '/forget-password',
    };
    if (!publicRoutes.contains(route)) {
      Get.offAllNamed('/login');
      // Defer the snackbar so it shows after the navigation animation.
      Future.delayed(const Duration(milliseconds: 250), () {
        Get.snackbar(
          'Session Expired',
          'Please sign in again to continue.',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
    }
  }

  // ── Auth ─────────────────────────────────────────
  Future<Response> signIn({required String email, required String password}) {
    return _dio.post('/auth/sign-in/email',
        data: {'email': email, 'password': password});
  }

  Future<Response> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _dio.post('/auth/sign-up/email',
        data: {'name': name, 'email': email, 'password': password});
  }

  Future<Response> getSession() => _dio.get('/auth/get-session');

  Future<Response> signOut() => _dio.post('/auth/sign-out');

  Future<Response> forgetPassword(String email) =>
      _dio.post('/auth/forget-password', data: {'email': email});

  Future<Response> resetPassword({required String token, required String newPassword}) =>
      _dio.post('/auth/reset-password', data: {'token': token, 'newPassword': newPassword});

  // ── Attendance ───────────────────────────────────
  Future<Response> checkIn(FormData data) =>
      _dio.post('/mobile/attendances/check-in', data: data);

  Future<Response> checkOut(FormData data) =>
      _dio.post('/mobile/attendances/check-out', data: data);

  Future<Response> fetchAttendances({
    int page = 1,
    int limit = 20,
    String? from,
    String? to,
  }) {
    return _dio.get('/mobile/attendances', queryParameters: {
      'page': page,
      'limit': limit,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    });
  }

  /// Calendar summary for a given month. [month] is a "YYYY-MM" string.
  /// Response shape: `{ data: [{ date, status, checkIn, checkOut }] }`
  Future<Response> fetchCalendar({required String month}) {
    return _dio.get('/mobile/attendances/calendar', queryParameters: {
      'month': month,
    });
  }

  // ── Reports ──────────────────────────────────────
  // Mobile uses /mobile/reports* (employee scope, ownership-checked on BE).
  Future<Response> createReport(FormData data) =>
      _dio.post('/mobile/reports', data: data);

  Future<Response> fetchMyReports({int page = 1, int limit = 20, String? status}) {
    return _dio.get('/mobile/reports', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
    });
  }

  Future<Response> fetchReportDetail(String id) =>
      _dio.get('/mobile/reports/$id');

  // ── Permits ──────────────────────────────────────
  Future<Response> fetchMyPermits({int page = 1, int limit = 20, String? status}) {
    return _dio.get('/mobile/permits/me', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
    });
  }

  /// Permit submission. [body] is either a plain `Map<String, dynamic>` for
  /// types without an attachment, or a `FormData` for types that include a
  /// receipt photo (e.g. reimbursement). The Dio interceptor leaves the
  /// `Content-Type` alone when the payload is `FormData`.
  Future<Response> submitPermit(dynamic body) =>
      _dio.post('/mobile/permits', data: body);

  // ── Leave Balance ────────────────────────────────
  Future<Response> fetchMyLeaveBalance() =>
      _dio.get('/mobile/me/leave-balance');

  // ── Announcements ────────────────────────────────
  Future<Response> fetchAnnouncements({int page = 1, int limit = 20}) {
    return _dio.get('/mobile/announcements', queryParameters: {
      'page': page,
      'limit': limit,
    });
  }

  Future<Response> fetchAnnouncementDetail(String id) =>
      _dio.get('/mobile/announcements/$id');

  // ── Profile ──────────────────────────────────────
  Future<Response> updateProfile({String? name, String? department}) {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (department != null) body['department'] = department;
    return _dio.patch('/mobile/me', data: body);
  }

  Future<Response> uploadAvatar(FormData data) =>
      _dio.post('/mobile/me/avatar', data: data);

  Future<Response> enrollFace(List<double> embedding) =>
      _dio.post('/mobile/me/face', data: {'embedding': embedding});

  Future<Response> fetchOffices({String? regency, int page = 1, int limit = 50}) {
    return _dio.get('/mobile/offices', queryParameters: {
      'page': page,
      'limit': limit,
      if (regency != null && regency.isNotEmpty) 'regency': regency,
    });
  }

  /// Register an FCM device token so the BE can target this device for
  /// push notifications. Best-effort — caller swallows errors.
  Future<Response> registerDevice({
    required String fcmToken,
    String platform = 'android',
  }) =>
      _dio.post('/mobile/me/device', data: {
        'fcmToken': fcmToken,
        'platform': platform,
      });

  Future<Response> changePassword({
    required String currentPassword,
    required String newPassword,
    bool revokeOtherSessions = false,
  }) =>
      _dio.post('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'revokeOtherSessions': revokeOtherSessions,
      });

  // ── Auth persistence ─────────────────────────────
  /// Accept any of these shapes from better-auth or wrapped envelope:
  /// { token, user }
  /// { session: { token }, user }
  /// { data: { ... } }
  void saveAuthData(dynamic raw) {
    if (raw is! Map) return;
    final root = raw['data'] is Map ? raw['data'] as Map : raw;

    final token = root['token'] ??
        (root['session'] is Map ? (root['session'] as Map)['token'] : null);
    final user = root['user'];

    if (token != null) box.put('token', token);
    if (user != null) {
      box.put('user', Map<String, dynamic>.from(user as Map));
    }
  }

  void clearAuthData() {
    box.delete('token');
    box.delete('user');
  }

  bool get isLoggedIn => box.get('token') != null;
  Map? get currentUser => box.get('user') as Map?;
  String? get currentToken => box.get('token') as String?;
}

/// Safely extract error message from a DioException response of any shape.
/// Falls back to a network-friendly note for timeouts / no-connection so
/// users get something more useful than the raw RequestOptions exception.
String dioErrorMessage(DioException e, [String fallback = 'Request failed']) {
  // Network-level errors first — these don't have e.response.
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Connection timed out. Check your network and try again.';
    case DioExceptionType.connectionError:
      return 'Cannot connect to the server. Please check your internet connection.';
    default:
      break;
  }

  final data = e.response?.data;
  if (data is Map) {
    final m = data['message'];
    if (m is String && m.isNotEmpty) return m;
    final err = data['error'];
    if (err is Map) {
      final em = err['message'];
      if (em is String && em.isNotEmpty) return em;
      final ec = err['code'];
      if (ec is String && ec.isNotEmpty) return ec;
    }
  }
  if (data is String && data.isNotEmpty) return data;
  return e.message ?? fallback;
}
