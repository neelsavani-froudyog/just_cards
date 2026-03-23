import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../routes/app_routes.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final isSending = false.obs;
  final errorText = RxnString();
  late final ApiService _apiService;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  String _normalize(String input) => input.trim().toLowerCase();

  bool _isValidEmail(String input) {
    final email = _normalize(input);
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  Future<void> sendOtp() async {
    final email = _normalize(emailController.text);
    errorText.value = null;

    if (email.isEmpty) {
      errorText.value = 'Email is required';
      return;
    }

    if (!_isValidEmail(email)) {
      errorText.value = 'Enter a valid email address';
      return;
    }

    if (isSending.value) return;
    isSending.value = true;

    try {
      await _apiService.postRequest(
        url: ApiUrl.sendOtp,
        data: <String, dynamic>{'email': email},
        showSuccessToast: true,
        successToastMessage: 'OTP sent successfully',
        showErrorToast: true,
        onSuccess: (_) {
          Get.toNamed(
            Routes.otp,
            arguments: <String, dynamic>{'email': email},
          );
        },
        onError: (message) {
          errorText.value = message.isNotEmpty ? message : 'Failed to send OTP';
        },
      );
    } finally {
      isSending.value = false;
    }
  }
}

