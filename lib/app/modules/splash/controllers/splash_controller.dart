import 'package:get/get.dart';
import '../../../data/controllers/auth_controller.dart';
import '../../../data/services/api_service.dart';

class SplashController extends GetxController {
  final auth = Get.find<AuthController>();
  final api = Get.find<ApiService>();

  @override
  void onReady() {
    super.onReady();
    _decideRoute();
  }

  void _decideRoute() {
    if (api.isLoggedIn) {
      // Optimistic: trust cached token, navigate immediately.
      Get.offAllNamed('/dashboard');
      // Validate in background; 401 interceptor bounces to login if invalid.
      auth.bootstrap();
    } else {
      Get.offAllNamed('/login');
    }
  }
}
