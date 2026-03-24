import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class CustomSearchDropdown<T> extends StatelessWidget {
  const CustomSearchDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    required this.itemAsString,
    required this.hintText,
    this.label,
    this.selectedItem,
    this.showSearchBox = true,
    this.enabled = true,
    this.searchHintText,
    this.margin,
    this.padding,
    this.bgColor,
    this.borderColor,
    this.borderRadius = 10,
    this.showShadow = true,
  });

  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T item) itemAsString;

  final String hintText;
  final String? label;
  final T? selectedItem;
  final bool showSearchBox;
  final bool enabled;
  final String? searchHintText;

  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? bgColor;
  final Color? borderColor;
  final double borderRadius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final container = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor ?? AppColors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? AppColors.ink.withValues(alpha: 0.08)),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: DropdownSearch<T>(
        items: (filter, _) async => items,
        selectedItem: selectedItem,
        itemAsString: itemAsString,
        enabled: enabled,
        onChanged: onChanged,
        suffixProps: DropdownSuffixProps(
          dropdownButtonProps: DropdownButtonProps(
            iconClosed: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.ink.withValues(alpha: 0.70),
              ),
            ),
            iconOpened: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        decoratorProps: DropDownDecoratorProps(
          baseStyle: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.90),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.45),
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
          ),
        ),
        popupProps: PopupProps.menu(
          showSearchBox: showSearchBox,
          fit: FlexFit.loose,
          menuProps: MenuProps(
            borderRadius: BorderRadius.circular(borderRadius),
            backgroundColor: AppColors.white,
            elevation: 6,
          ),
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: searchHintText ?? 'Search...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.10)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.10)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.55)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.ink.withValues(alpha: 0.50),
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: margin ?? EdgeInsets.zero,
            child: Text(
              label!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.70),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: margin ?? EdgeInsets.zero,
          child: container,
        ),
      ],
    );
  }
}

