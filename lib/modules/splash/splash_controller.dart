import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:get/get.dart';

import '../../core/services/auth_session_service.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> scanLine;
  late final Animation<double> glow;

  final appName = 'JustCards'.obs;
  final tagline = 'Business Card Scanner'.obs;
  late final AuthSessionService _session;

  @override
  void onInit() {
    super.onInit();
    _session = Get.find<AuthSessionService>();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    scanLine = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOutCubic,
    );

    glow = Tween<double>(begin: 0.25, end: 1).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void onReady() {
    super.onReady();
    animationController.repeat(reverse: true);
    Timer(const Duration(milliseconds: 2400), () {
      if (!isClosed) {
        final hasToken = _session.accessToken.value.trim().isNotEmpty;
        if (hasToken) {
          Get.offAllNamed(Routes.bottomNavigation);
        } else {
          Get.offAllNamed(Routes.login);
        }
      }
    });
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }

  List<Color> get backgroundGradient => const [...AppColors.splashGradient];
}
