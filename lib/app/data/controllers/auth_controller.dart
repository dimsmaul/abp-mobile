import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../services/api_service.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find();

  final api = Get.find<ApiService>();

  final user = Rxn<Map>();
  final isAuthenticated = false.obs;

  @override
  void onInit() {
    super.onInit();
    final cached = api.currentUser;
    if (cached != null) {
      user.value = cached;
      isAuthenticated.value = api.isLoggedIn;
    }
  }

  /// Validate stored token against `/auth/get-session`.
  /// Returns true if session is valid.
  Future<bool> bootstrap() async {
    if (!api.isLoggedIn) return false;
    try {
      final res = await api.getSession();
      if (res.statusCode == 200 && res.data != null) {
        final body = res.data;
        final root = body is Map && body['data'] is Map ? body['data'] : body;
        if (root is Map && root['user'] != null) {
          user.value = Map<String, dynamic>.from(root['user'] as Map);
          api.box.put('user', user.value);
          isAuthenticated.value = true;
          return true;
        }
      }
      await _signOutLocal();
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _signOutLocal();
        return false;
      }
      // Network errors: fall back to cached session so user can keep working.
      isAuthenticated.value = api.isLoggedIn;
      return isAuthenticated.value;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final res = await api.signIn(email: email, password: password);
    if (res.statusCode != 200 || res.data == null) {
      throw Exception('Login failed: unexpected status ${res.statusCode}');
    }
    _persistAuthFromResponse(res);
    if (!api.isLoggedIn) {
      throw Exception('Login failed: no auth token in response');
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await api.signUp(name: name, email: email, password: password);
    if ((res.statusCode != 200 && res.statusCode != 201) || res.data == null) {
      throw Exception('Sign-up failed: unexpected status ${res.statusCode}');
    }
    _persistAuthFromResponse(res);
    if (!api.isLoggedIn) {
      throw Exception('Sign-up failed: no auth token in response');
    }
  }

  void _persistAuthFromResponse(Response res) {
    // Save user payload from body.
    api.saveAuthData(res.data);

    // Bearer plugin exposes signed token via `set-auth-token` header.
    // Body `token` is raw session id — won't authenticate as Bearer.
    final headerToken = res.headers.value('set-auth-token');
    if (headerToken != null && headerToken.isNotEmpty) {
      api.box.put('token', headerToken);
    }

    user.value = api.currentUser;
    isAuthenticated.value = api.isLoggedIn;
  }

  Future<void> signOut() async {
    try {
      await api.signOut();
    } catch (_) {}
    await _signOutLocal();
  }

  Future<void> _signOutLocal() async {
    api.clearAuthData();
    user.value = null;
    isAuthenticated.value = false;
  }
}
