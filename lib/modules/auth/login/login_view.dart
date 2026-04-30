import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/custom_text_field.dart';
import '../auth_shell.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 420;

    return AuthShell(useCard: false, child: _LoginBody(isCompact: isCompact));
  }
}

class _LoginBody extends StatelessWidget {
  const _LoginBody({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoginController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  top: isCompact ? 6 : 12,
                  bottom:
                      (isCompact ? 360 : 380) +
                      MediaQuery.of(context).padding.bottom,
                ),
                child: const _TopLogo(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _LoginBottomSheet(isCompact: isCompact, controller: c),
            ),
          ],
        );
      },
    );
  }
}

// (removed unused brand header widget)

class _TopLogo extends StatelessWidget {
  const _TopLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'JustCards',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 35),
        const _ScanIllustration(),
      ],
    );
  }
}

class _LoginBottomSheet extends StatelessWidget {
  const _LoginBottomSheet({required this.isCompact, required this.controller});

  final bool isCompact;
  final LoginController controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final maxWidth = width > 720 ? 520.0 : width;

    return SafeArea(
      top: false,
      bottom: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, isCompact ? 18 : 22, 20, 18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Enter your email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We’ll send a one-time code to verify.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.60),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _EmailField(isCompact: isCompact),
              const SizedBox(height: 12),
              _PrimaryButton(label: 'Send OTP', onPressed: controller.sendOtp),
              const SizedBox(height: 12),
              _TermsRow(),
              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }
}

// (removed illustration widgets to keep design minimal)

class _EmailField extends StatelessWidget {
  const _EmailField({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoginController>();

    return Obx(() {
      return CustomTextField(
        controller: c.emailController,
        label: 'Email',
        hint: 'name@company.com',
        inputType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: AppColors.ink,
          size: 20,
        ),
        errorText: c.emailErrorText.value,
        onSubmitted: (_) => c.sendOtp(),
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isCompact ? 12 : 14,
        ),
      );
    });
  }
}

class _ScanIllustration extends StatelessWidget {
  const _ScanIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.78,
      height: MediaQuery.of(context).size.height * 0.34,
      child: Lottie.asset(
        'assets/animation/splash_screen_animation.json',
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: AppColors.ink.withValues(alpha: 0.50),
      fontWeight: FontWeight.w600,
    );

    final linkStyle = style?.copyWith(
      fontWeight: FontWeight.w800,
      decoration: TextDecoration.underline,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        children: [
          Text('By continuing you agree to our', style: style),
          GestureDetector(
            onTap: () => Get.toNamed(Routes.termsConditions),
            child: Text('Terms', style: linkStyle),
          ),
          Text('&', style: style),
          GestureDetector(
            onTap: () => Get.toNamed(Routes.privacyPolicy),
            child: Text('Privacy Policy', style: linkStyle),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<LoginController>();
    return Obx(() {
      final busy = c.isSending.value;
      return _GradientButton(
        enabled: !busy,
        onPressed: onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child:
              busy
                  ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                  : Row(
                    key: const ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
        ),
      );
    });
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.enabled,
    required this.onPressed,
    required this.child,
  });

  final bool enabled;
  final Future<void> Function() onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                enabled
                    ? const [
                      AppColors.primary,
                      AppColors.primary,
                      AppColors.primary,
                    ]
                    : [
                      AppColors.primary.withValues(alpha: 0.35),
                      AppColors.primary.withValues(alpha: 0.35),
                      AppColors.primary.withValues(alpha: 0.35),
                    ],
          ),
          boxShadow:
              enabled
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : const [],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: DefaultTextStyle(
                style: const TextStyle(color: AppColors.white),
                child: IconTheme(
                  data: const IconThemeData(color: AppColors.white),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
