import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.subLabel,
    this.hint,
    this.margin,
    this.padding,
    this.fillColor,
    this.filled = true,
    this.isShowBorder = true,
    this.hintStyle,
    this.labelStyle,
    this.subLabelStyle,
    this.textStyle,
    this.inputType = TextInputType.text,
    this.isPassword = false,
    this.readOnly = false,
    this.enabled = true,
    this.suffixIcon,
    this.prefixIcon,
    this.onTap,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.borderRadius = 16,
    this.cursorColor,
    this.borderColor,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.textInputAction,
    this.focusNode,
    this.decoration,
    this.decorated = true,
  });

  final TextEditingController? controller;
  final String? label;
  final String? subLabel;
  final String? hint;

  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  final Color? fillColor;
  final bool filled;
  final bool isShowBorder;

  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final TextStyle? subLabelStyle;
  final TextStyle? textStyle;

  final TextInputType inputType;
  final bool isPassword;
  final bool readOnly;
  final bool enabled;

  final Widget? suffixIcon;
  final Widget? prefixIcon;

  final VoidCallback? onTap;

  final int? minLines;
  final int? maxLines;
  final int? maxLength;

  final double borderRadius;
  final Color? cursorColor;
  final Color? borderColor;

  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  /// If provided, used as the `TextField` decoration.
  /// Useful for special layouts (e.g. invisible OTP input).
  final InputDecoration? decoration;

  /// If false, returns a plain `TextField` without wrapper UI.
  final bool decorated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final baseTextField = TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: inputType,
      textInputAction: textInputAction,
      obscureText: isPassword,
      readOnly: readOnly,
      enabled: enabled,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      cursorColor: cursorColor ?? AppColors.ink.withValues(alpha: 0.55),
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: textStyle ??
          theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.92),
            fontWeight: FontWeight.w600,
          ),
      decoration: decoration ??
          InputDecoration(
            hintText: hint,
            hintStyle: hintStyle ??
                AppTextStyles.sectionSubtitle(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink.withValues(alpha: 0.42),
                ),
            border: InputBorder.none,
            isDense: true,
            counterText: '',
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
    );

    if (!decorated) return baseTextField;

    final containerPadding = padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: margin ?? EdgeInsets.zero,
            child: subLabel == null
                ? Text(
                    label!,
                    style: labelStyle ??
                        theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.70),
                          fontWeight: FontWeight.w800,
                        ),
                  )
                : RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: label!,
                          style: labelStyle ??
                              theme.textTheme.labelLarge?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.70),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        TextSpan(
                          text: ' ($subLabel)',
                          style: subLabelStyle ??
                              theme.textTheme.labelMedium?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: margin ?? EdgeInsets.zero,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: containerPadding,
              decoration: BoxDecoration(
                color: filled ? (fillColor ?? AppColors.fieldFill) : null,
                borderRadius: BorderRadius.circular(borderRadius),
                border: isShowBorder
                    ? Border.all(
                        color: (borderColor ?? AppColors.ink.withValues(alpha: 0.10)),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  if (prefixIcon != null) ...[
                    prefixIcon!,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: inputType,
                      textInputAction: textInputAction,
                      obscureText: isPassword,
                      readOnly: readOnly,
                      enabled: enabled,
                      minLines: minLines,
                      maxLines: maxLines,
                      maxLength: maxLength,
                      autofillHints: autofillHints,
                      inputFormatters: inputFormatters,
                      cursorColor: cursorColor ?? AppColors.ink.withValues(alpha: 0.55),
                      onTap: onTap,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      style: textStyle ??
                          theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.92),
                            fontWeight: FontWeight.w600,
                          ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        counterText: '',
                        hintText: hint,
                        hintStyle: hintStyle ??
                            AppTextStyles.sectionSubtitle(context).copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink.withValues(alpha: 0.42),
                            ),
                        suffixIcon: suffixIcon,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

