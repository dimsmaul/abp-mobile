import 'package:get/get.dart';

import '../../home/controllers/home_controller.dart';
import '../../presence/controllers/presence_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<PresenceController>(() => PresenceController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
