import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../routes/app_routes.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final isSending = false.obs;
  /// Backend / request error (e.g. failed to send OTP).
  final errorText = RxnString();

  /// Form validation error for the email field.
  final emailErrorText = RxnString();
  final _attemptedSubmit = false.obs;
  late final ApiService _apiService;

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    emailController.addListener(_onEmailChanged);
  }

  @override
  void onClose() {
    emailController.removeListener(_onEmailChanged);
    emailController.dispose();
    super.onClose();
  }

  String _normalize(String input) => input.trim().toLowerCase();

  bool _isValidEmail(String input) {
    final email = _normalize(input);
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  String _domainPart(String email) {
    final at = email.lastIndexOf('@');
    if (at <= 0 || at >= email.length - 1) return '';
    return email.substring(at + 1);
  }

  Future<bool> _domainResolves(String domain) async {
    if (domain.isEmpty) return false;
    try {
      final res = await InternetAddress.lookup(domain).timeout(const Duration(seconds: 2));
      return res.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String? _validateEmail(String raw) {
    final email = _normalize(raw);
    if (email.isEmpty) return 'Email is required';
    if (!_isValidEmail(email)) return 'Enter a valid email address';
    return null;
  }

  void _onEmailChanged() {
    if (!_attemptedSubmit.value) return;
    emailErrorText.value = _validateEmail(emailController.text);
  }

  Future<void> sendOtp() async {
    final email = _normalize(emailController.text);
    _attemptedSubmit.value = true;
    errorText.value = null;

    final validationMessage = _validateEmail(email);
    if (validationMessage != null) {
      emailErrorText.value = validationMessage;
      return;
    }
    emailErrorText.value = null;

    if (isSending.value) return;
    isSending.value = true;

    try {
      final domainOk = await _domainResolves(_domainPart(email));
      if (!domainOk) {
        emailErrorText.value = 'Email domain looks invalid';
        return;
      }

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

