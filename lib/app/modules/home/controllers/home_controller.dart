import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeController extends GetxController {
  final box = Hive.box('auth');
  final user = Rxn<dynamic>();

  @override
  void onInit() {
    super.onInit();
    user.value = box.get('user');
    print('[HomeController] Initialized');
  }

  void goToAttendance(String type) {
    Get.toNamed('/attendance', arguments: type);
  }

  void goToPermit() {
    Get.toNamed('/permit');
  }

  void goToProfile() {
    Get.toNamed('/profile');
  }
}
