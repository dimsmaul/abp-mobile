import 'package:get/get.dart';

import '../../calendar/controllers/calendar_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../permit/controllers/permit_controller.dart';
import '../../presence/controllers/presence_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(() => DashboardController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<CalendarController>(() => CalendarController());
    Get.lazyPut<PresenceController>(() => PresenceController());
    Get.lazyPut<PermitController>(() => PermitController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
