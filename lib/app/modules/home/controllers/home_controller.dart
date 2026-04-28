import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class HomeController extends GetxController {
  final storage = GetStorage();
  final user = Rxn<dynamic>();

  @override
  void onInit() {
    super.onInit();
    user.value = storage.read('user');
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
