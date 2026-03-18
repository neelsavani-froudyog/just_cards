import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final isSending = false.obs;
  final errorText = RxnString();

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

    if (!_isValidEmail(email)) {
      errorText.value = 'Enter a valid email address';
      return;
    }

    if (isSending.value) return;
    isSending.value = true;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 850));
      Get.toNamed(
        Routes.otp,
        arguments: <String, dynamic>{'email': email},
      );
    } finally {
      isSending.value = false;
    }
  }
}

