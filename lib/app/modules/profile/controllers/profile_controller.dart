import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../data/services/api_service.dart';

class ProfileController extends GetxController {
  final apiService = Get.find<ApiService>();
  final box = Hive.box('auth');
  final user = Rxn<dynamic>();

  @override
  void onInit() {
    super.onInit();
    user.value = box.get('user');
    print('[ProfileController] Initialized');
  }

  void logout() {
    apiService.clearAuthData();
    Get.offAllNamed('/login');
  }
}
