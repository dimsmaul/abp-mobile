import 'package:get/get.dart';

import '../controllers/permit_controller.dart';

class PermitBinding extends Bindings {
  @override
  void dependencies() {
    // `fenix: true` so the controller is re-created on demand after a route
    // exit cleans it up. Without this, navigating back from /leave (or any
    // of the category-locked shortcuts) deletes the controller and the
    // dashboard's Requests tab — which depends on the same controller —
    // then throws "PermitController not found" on the next access.
    Get.lazyPut<PermitController>(
      () => PermitController(),
      fenix: true,
    );
  }
}
