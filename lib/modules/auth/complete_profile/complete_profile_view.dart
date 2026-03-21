import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_field.dart';
import '../auth_shell.dart';
import 'complete_profile_controller.dart';

class CompleteProfileView extends GetView<CompleteProfileController> {
  const CompleteProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 420;

    return AuthShell(
      showBack: true,
      onBack: () => Get.back(),
      useCard: false,
      child: _CompleteProfileBody(isCompact: isCompact),
    );
  }
}

class _CompleteProfileBody extends StatelessWidget {
  const _CompleteProfileBody({required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CompleteProfileController>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.only(top: isCompact ? 10 : 20, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: isCompact ? 24 : 34),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      22,
                      isCompact ? 24 : 30,
                      22,
                      22,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.ink.withValues(alpha: 0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi,',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your good name',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                        ),
                        SizedBox(height: isCompact ? 26 : 30),
                        CustomTextField(
                          controller: c.nameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          prefixIcon: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.person_outline_rounded,
                              color: AppColors.ink,
                              size: 20,
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => c.continueToApp(),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: isCompact ? 14 : 16,
                          ),
                          fillColor: AppColors.fieldFill.withValues(
                            alpha: 0.70,
                          ),
                          borderRadius: 20,
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          final error = c.errorText.value;
                          if (error == null) return const SizedBox.shrink();
                          return Text(
                            error,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                ),
                          );
                        }),
                        SizedBox(height: isCompact ? 24 : 28),
                        _ContinueButton(onPressed: c.continueToApp),
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

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CompleteProfileController>();
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Obx(() {
        final busy = c.isSaving.value;
        return FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
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
                      color: AppColors.white,
                    ),
                  )
                : const Text(
                    'Continue',
                    key: ValueKey('label'),
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
          ),
        );
      }),
    );
  }
}
