import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ProfileController extends GetxController {
  final storage = GetStorage();
  final user = Rxn<dynamic>();

  @override
  void onInit() {
    super.onInit();
    user.value = storage.read('user');
  }

  void logout() {
    storage.remove('token');
    storage.remove('user');
    Get.offAllNamed('/login');
  }
}
