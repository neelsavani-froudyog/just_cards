import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_colors.dart';

class ConfirmDialog {
  const ConfirmDialog._();

  static Future<bool> show({
    String title = 'Confirm',
    String message = 'Are you sure?',
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
    bool destructive = true,
    IconData? icon,
  }) async {
    final result = await Get.dialog<bool>(
      _ConfirmDialogBody(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        destructive: destructive,
        icon: icon ?? (destructive ? Icons.delete_outline_rounded : Icons.help_outline_rounded),
      ),
      barrierDismissible: true,
    );

    return result ?? false;
  }
}

class _ConfirmDialogBody extends StatelessWidget {
  const _ConfirmDialogBody({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.destructive,
    required this.icon,
  });

  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool destructive;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use brand color for consistent theme (no red).
    final accent = AppColors.primary;
    final accentSoft = AppColors.primaryLight.withValues(alpha: 0.55);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentSoft,
                      AppColors.primary.withValues(alpha: 0.20),
                    ],
                  ),
                ),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(icon, color: AppColors.primaryDark, size: 26),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink.withValues(alpha: 0.78),
                        side: BorderSide(color: AppColors.ink.withValues(alpha: 0.10)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        cancelText,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Get.back(result: true),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        confirmText,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

