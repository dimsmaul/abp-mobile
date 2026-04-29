import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
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
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // better-auth uses session token as Bearer token
        final token = box.get('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          box.delete('token');
          box.delete('user');
          Get.offAllNamed('/login');
        }
        return handler.next(e);
      },
    ));
  }

  /// Sign in via better-auth
  /// POST /auth/sign-in/email
  /// Returns { user, session: { token } }
  Future<Response> signIn({
    required String email,
    required String password,
  }) async {
    return await _dio.post('/auth/sign-in/email', data: {
      'email': email,
      'password': password,
    });
  }

  /// Sign up via better-auth
  /// POST /auth/sign-up/email
  /// Returns { user, session: { token } }
  Future<Response> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    return await _dio.post('/auth/sign-up/email', data: {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  /// Get current session info
  /// GET /auth/get-session
  Future<Response> getSession() async {
    return await _dio.get('/auth/get-session');
  }

  /// Persist auth data from better-auth response
  void saveAuthData(Map<String, dynamic> data) {
    final token = data['session']?['token'];
    final user = data['user'];

    if (token != null) {
      box.put('token', token);
    }
    if (user != null) {
      // Convert nested maps if needed, or save directly as dynamic map
      // Convert map entries to a Map<String, dynamic> using Map.from just in case.
      box.put('user', Map<String, dynamic>.from(user));
    }
  }

  /// Clear stored auth data
  void clearAuthData() {
    box.delete('token');
    box.delete('user');
  }

  /// Check if user is logged in
  bool get isLoggedIn => box.get('token') != null;
}

