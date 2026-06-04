import 'package:get/get.dart';

import '../../presence/controllers/presence_controller.dart';

class DashboardController extends GetxController {
  /// Tab indices:
  /// 0 = Home, 1 = Calendar, 2 = Presence (center FAB),
  /// 3 = Requests (Permit), 4 = Profile
  final currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
    // Presence (FAB) tab re-runs the gate check (permissions, GPS, polygon)
    // every entry so a stale "you're outside" state can clear once the user
    // walks into the office area.
    if (index == 2 && Get.isRegistered<PresenceController>()) {
      Get.find<PresenceController>().start();
    }
  }
}
