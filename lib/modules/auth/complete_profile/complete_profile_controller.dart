import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_session_service.dart';
import '../../../routes/app_routes.dart';

class CompleteProfileController extends GetxController {
  final nameController = TextEditingController();
  final isSaving = false.obs;
  final errorText = RxnString();

  late final String email;
  late final AuthSessionService _session;
  late final ApiService _apiService;

  @override
  void onInit() {
    super.onInit();
    final args =
        (Get.arguments as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    email = (args['email'] as String?) ?? '';
    _session = Get.find<AuthSessionService>();
    _apiService = Get.find<ApiService>();
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

    isSaving.value = true;
    try {
      await _apiService.postRequest(
        url: ApiUrl.createProfile,
        data: <String, dynamic>{
          'p_full_name': name,
          'p_email': email,
        },
        showSuccessToast: true,
        successToastMessage: 'Profile created successfully',
        showErrorToast: true,
        onSuccess: (_) {
          _session.completeProfile(name: name, emailAddress: email);
          Get.offAllNamed(Routes.bottomNavigation);
        },
        onError: (message) {
          errorText.value =
              message.isNotEmpty ? message : 'Failed to save profile';
        },
      );
    } finally {
      isSaving.value = false;
    }
  }
}
