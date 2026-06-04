import 'package:get/get.dart';

import '../../presence/controllers/presence_controller.dart';

class DashboardController extends GetxController {
  final currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
    if (index == 1 && Get.isRegistered<PresenceController>()) {
      // Every entry into the presence tab re-runs the gate check (permission,
      // GPS, polygon hit-test) so a stale "you're outside" state can clear
      // once the user walks into the office.
      Get.find<PresenceController>().start();
    }
  }
}
