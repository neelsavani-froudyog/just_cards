import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_field.dart';
import '../auth_shell.dart';
import 'otp_controller.dart';

class OtpView extends GetView<OtpController> {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 420;

    return AuthShell(
      showBack: true,
      onBack: () => Get.back(),
      useCard: false,
      child: _OtpBody(isCompact: isCompact),
    );
  }
}

class _OtpBody extends StatelessWidget {
  const _OtpBody({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OtpController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.only(top: isCompact ? 12 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _OtpHeader(),
                  SizedBox(height: isCompact ? 18 : 26),
                  Text(
                    'Enter OTP',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: -0.3,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit code to',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.62),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.email.isEmpty ? 'your email' : c.email,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  SizedBox(height: isCompact ? 18 : 22),
                  _OtpCodeField(isCompact: isCompact),
                  const SizedBox(height: 10),
                  Obx(() {
                    final err = c.errorText.value;
                    if (err == null) return const SizedBox.shrink();
                    return Text(
                      err,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                    );
                  }),
                  SizedBox(height: isCompact ? 14 : 16),
                  _VerifyButton(onPressed: c.verify),
                  const SizedBox(height: 16),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Didn’t receive it?',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.58),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 6),
                        Obx(() {
                          final s = c.secondsRemaining.value;
                          final enabled = s == 0;
                          return TextButton(
                            onPressed: enabled ? c.resend : null,
                            child: Text(enabled ? 'Resend' : 'Resend in ${s}s'),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OtpHeader extends StatelessWidget {
  const _OtpHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.primary,
          ),
          child: const Icon(Icons.shield_moon_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Secure sign in',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
              ),
              Text(
                'Verify email to continue',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.55),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerifyButton extends StatelessWidget {
  const _VerifyButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OtpController>();
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Obx(() {
        final busy = c.isVerifying.value;
        return FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: busy
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Verify OTP',
                    key: ValueKey('label'),
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        );
      }),
    );
  }
}

class _OtpCodeField extends StatefulWidget {
  const _OtpCodeField({required this.isCompact});

  final bool isCompact;

  @override
  State<_OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<_OtpCodeField> {
  final focusNode = FocusNode();
  int _lastDigitsLen = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OtpController>();
    final boxSize = widget.isCompact ? 46.0 : 52.0;
    final gap = widget.isCompact ? 10.0 : 12.0;

    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: c.codeController,
        builder: (context, value, _) {
          final digits = value.text.replaceAll(RegExp(r'\\D'), '');
          final shown = digits.padRight(6);
          final activeIndex = digits.length.clamp(0, 5);
          if (digits.length == 6 && _lastDigitsLen != 6) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) c.verify();
            });
          }
          _lastDigitsLen = digits.length;

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Wrap(
                spacing: gap,
                children: List.generate(6, (index) {
                  final ch = shown[index];
                  final selected = focusNode.hasFocus && activeIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    width: boxSize,
                    height: boxSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? AppColors.accentTeal
                            : AppColors.ink.withValues(alpha: 0.10),
                        width: selected ? 1.8 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: selected ? 0.08 : 0.06),
                          blurRadius: selected ? 22 : 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          ch.trim().isEmpty ? ' ' : ch,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                        ),
                        if (selected && ch.trim().isEmpty)
                          Positioned(
                            bottom: 12,
                            child: Container(
                              width: 18,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppColors.accentTeal,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ),
              Opacity(
                opacity: 0,
                child: SizedBox(
                  width: (boxSize * 6) + (gap * 5),
                  child: CustomTextField(
                    decorated: false,
                    focusNode: focusNode,
                    controller: c.codeController,
                    inputType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => c.verify(),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    maxLength: 6,
                    decoration: const InputDecoration(counterText: ''),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
