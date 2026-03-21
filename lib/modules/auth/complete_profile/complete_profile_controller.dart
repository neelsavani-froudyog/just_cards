import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/auth_session_service.dart';
import '../../../routes/app_routes.dart';

class CompleteProfileController extends GetxController {
  final nameController = TextEditingController();
  final isSaving = false.obs;
  final errorText = RxnString();

  late final String email;
  late final AuthSessionService _session;

  @override
  void onInit() {
    super.onInit();
    final args =
        (Get.arguments as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    email = (args['email'] as String?) ?? '';
    _session = Get.find<AuthSessionService>();
    _session.setEmail(email);
  }

  @override
  void onClose() {
    nameController.dispose();
    super.onClose();
  }

  Future<void> continueToApp() async {
    errorText.value = null;
    final name = nameController.text.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (name.length < 2) {
      errorText.value = 'Please enter your full name';
      return;
    }
    if (isSaving.value) return;

    isSaving.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      _session.completeProfile(name: name, emailAddress: email);
      Get.offAllNamed(Routes.bottomNavigation);
    } finally {
      isSaving.value = false;
    }
  }
}
