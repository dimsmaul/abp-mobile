import 'package:get/get.dart';

class DashboardController extends GetxController {
  final currentIndex = 0.obs;

  void changePage(int index) {
    if (index == 1) {
      // The center button is for Camera/Attendance, don't change the tab index
      Get.toNamed('/camera');
    } else {
      currentIndex.value = index;
    }
  }
}
