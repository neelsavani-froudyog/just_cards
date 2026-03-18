import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';

class OtpController extends GetxController {
  final codeController = TextEditingController();
  final isVerifying = false.obs;
  final errorText = RxnString();
  final secondsRemaining = 59.obs;

  Timer? _timer;
  bool _didRedirect = false;

  late final String email;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    email = (args['email'] as String?) ?? '';
    _startTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    codeController.dispose();
    super.onClose();
  }

  String _digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  Future<void> verify() async {
    errorText.value = null;
    final code = _digitsOnly(codeController.text);

    if (code.length != 6) {
      errorText.value = 'Enter 6-digit OTP';
      return;
    }
    if (isVerifying.value) return;
    if (_didRedirect) return;
    isVerifying.value = true;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (_didRedirect || isClosed) return;
      _didRedirect = true;
      Get.offAllNamed(Routes.bottomNavigation);
    } finally {
      isVerifying.value = false;
    }
  }

  Future<void> resend() async {
    errorText.value = null;
    if (secondsRemaining.value > 0) return;
    secondsRemaining.value = 30;
    _startTimer();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!isClosed) {
      Get.snackbar('OTP sent', 'Check your inbox for a new code.');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = secondsRemaining.value - 1;
      secondsRemaining.value = next.clamp(0, 59);
      if (secondsRemaining.value == 0) {
        t.cancel();
      }
    });
  }
}
