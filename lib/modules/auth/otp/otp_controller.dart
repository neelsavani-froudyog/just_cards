import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_session_service.dart';
import '../../../routes/app_routes.dart';

class OtpController extends GetxController {
  final codeController = TextEditingController();
  final isVerifying = false.obs;
  final errorText = RxnString();
  final secondsRemaining = 59.obs;

  Timer? _timer;
  bool _didRedirect = false;

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
    _startTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    codeController.dispose();
    super.onClose();
  }

  String _digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  bool? _extractEmailExistsFlag(dynamic response) {
    if (response is Map) {
      final dynamic raw = response['data'];
      if (raw is bool) return raw;
      if (raw is String) {
        final v = raw.trim().toLowerCase();
        if (v == 'true') return true;
        if (v == 'false') return false;
      }
    }
    return null;
  }

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
      bool isOtpVerified = false;

      await _apiService.postRequest(
        url: ApiUrl.verifyOtp,
        data: <String, dynamic>{
          'email': email,
          'otp': code,
        },
        showSuccessToast: true,
        successToastMessage: 'OTP verified successfully',
        showErrorToast: true,
        onSuccess: (payload) {
          isOtpVerified = true;

          // If your backend returns an access token, store it for future API calls.
          final response = payload['response'];
          if (response is Map) {
            final dynamic directToken = response['accessToken'];
            final dynamic altToken = response['token'];
            final dynamic snakeToken = response['access_token'];
            final dynamic nestedToken =
                (response['data'] is Map) ? response['data']['accessToken'] : null;
            final dynamic nestedAltToken =
                (response['data'] is Map) ? response['data']['token'] : null;
            final dynamic nestedSnakeToken =
                (response['data'] is Map) ? response['data']['access_token'] : null;

            final token = (directToken ??
                altToken ??
                snakeToken ??
                nestedToken ??
                nestedAltToken ??
                nestedSnakeToken);
            if (token is String && token.isNotEmpty) {
              _session.setAccessToken(token);
            }
          }
        },
        onError: (message) {
          errorText.value = message.isNotEmpty ? message : 'Failed to verify OTP';
        },
      );

      if (!isOtpVerified || _didRedirect || isClosed) return;

      await _apiService.postRequest(
        url: ApiUrl.emailExists,
        data: <String, dynamic>{'p_email': email},
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          if (_didRedirect || isClosed) return;

          final response = payload['response'];
          final exists = _extractEmailExistsFlag(response);
          if (exists == null) {
            errorText.value = 'Invalid email check response';
            return;
          }

          _didRedirect = true;
          if (exists) {
            Get.offAllNamed(Routes.bottomNavigation);
          } else {
            Get.offNamed(
              Routes.completeProfile,
              arguments: <String, dynamic>{'email': email},
            );
          }
        },
        onError: (message) {
          errorText.value = message.isNotEmpty ? message : 'Failed to check profile';
        },
      );
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
