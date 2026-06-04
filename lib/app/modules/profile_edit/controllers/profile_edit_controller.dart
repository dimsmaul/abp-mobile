import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class ProfileEditController extends GetxController {
  final auth = Get.find<AuthController>();
  late final ProfileController _profile = Get.find<ProfileController>();

  late final TextEditingController nameCtl;
  late final TextEditingController deptCtl;

  String _origName = '';
  String _origDept = '';

  RxBool get isSaving => _profile.isSavingProfile;

  bool get isDirty {
    return nameCtl.text.trim() != _origName ||
        deptCtl.text.trim() != _origDept;
  }

  @override
  void onInit() {
    super.onInit();
    final user = auth.user.value;
    _origName = user?['name']?.toString() ?? '';
    _origDept = user?['department']?.toString() ?? '';
    nameCtl = TextEditingController(text: _origName);
    deptCtl = TextEditingController(text: _origDept);
  }

  @override
  void onClose() {
    nameCtl.dispose();
    deptCtl.dispose();
    super.onClose();
  }

  Future<void> save() async {
    final newName = nameCtl.text.trim();
    final newDept = deptCtl.text.trim();

    if (newName.isEmpty) {
      Get.snackbar('Error', 'Name cannot be empty');
      return;
    }

    final namePayload =
        newName != _origName ? newName : null;
    final deptPayload = newDept != _origDept ? newDept : null;

    if (namePayload == null && deptPayload == null) {
      Get.back();
      return;
    }

    final ok = await _profile.saveProfile(
      name: namePayload,
      department: deptPayload,
    );
    if (ok) Get.back();
  }
}
