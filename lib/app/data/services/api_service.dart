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
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
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
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          clearAuthData();
          if (Get.currentRoute != '/login' && Get.currentRoute != '/splash') {
            Get.offAllNamed('/login');
          }
        }
        return handler.next(e);
      },
    ));
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
    return _dio.get('/permits/me', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
    });
  }

  Future<Response> submitPermit(Map<String, dynamic> body) =>
      _dio.post('/permits', data: body);

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
String dioErrorMessage(DioException e, [String fallback = 'Request failed']) {
  final data = e.response?.data;
  if (data is Map) {
    final m = data['message'];
    if (m is String && m.isNotEmpty) return m;
    final err = data['error'];
    if (err is Map && err['message'] is String) return err['message'] as String;
  }
  if (data is String && data.isNotEmpty) return data;
  return e.message ?? fallback;
}
