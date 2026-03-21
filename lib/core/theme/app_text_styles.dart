import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static TextTheme textTheme() {
    // Higher contrast + slightly larger sizes for readability.
    const base = TextTheme();
    return base.copyWith(
      displaySmall: const TextStyle(
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w700,
        color: AppColors.darkGrey,
        letterSpacing: -0.6,
      ),
      headlineMedium: const TextStyle(
        fontSize: 26,
        height: 1.18,
        fontWeight: FontWeight.w700,
        color: AppColors.darkGrey,
        letterSpacing: -0.4,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: AppColors.darkGrey,
        letterSpacing: -0.25,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: AppColors.darkGrey,
      ),
      titleSmall: const TextStyle(
        fontSize: 15,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: AppColors.darkGrey,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: AppColors.darkGrey,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: AppColors.darkGrey,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: AppColors.darkGrey.withValues(alpha: 0.84),
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        height: 1.1,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGrey.withValues(alpha: 0.84),
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.1,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGrey.withValues(alpha: 0.82),
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.1,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGrey.withValues(alpha: 0.80),
      ),
    );
  }

  // Handy “tokens” for common UI usage.
  static TextStyle sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w800);

  static TextStyle sectionSubtitle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
        color: AppColors.darkGrey.withValues(alpha: 0.72),
        fontWeight: FontWeight.w500,
      );

  static TextStyle caption(BuildContext context) =>
      Theme.of(context).textTheme.labelMedium!.copyWith(color: AppColors.darkGrey.withValues(alpha: 0.72));
}

