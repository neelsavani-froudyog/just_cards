import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class CustomSearchDropdown<T> extends StatefulWidget {
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
    this.dropdownMaxHeight = 200,
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
  final double dropdownMaxHeight;
  final bool showShadow;

  @override
  State<CustomSearchDropdown<T>> createState() =>
      _CustomSearchDropdownState<T>();
}

class _CustomSearchDropdownState<T> extends State<CustomSearchDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  late final ValueNotifier<T?> _valueNotifier;

  @override
  void initState() {
    super.initState();
    _valueNotifier = ValueNotifier<T?>(widget.selectedItem);
  }

  @override
  void dispose() {
    _valueNotifier.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final theme = Theme.of(context);

    final selected = items.contains(widget.selectedItem)
        ? widget.selectedItem
        : null;

    _valueNotifier.value = selected;

    final margin = widget.margin ?? EdgeInsets.zero;

    final container = Container(
      padding:
          widget.padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: widget.bgColor ?? AppColors.white,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: widget.borderColor ?? AppColors.ink.withValues(alpha: 0.08),
        ),
        boxShadow: widget.showShadow
            ? [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.025),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<T>(
          isExpanded: true,
          valueListenable: _valueNotifier,
          items: items
              .map(
                (item) => DropdownItem<T>(
                  value: item,
                  child: Text(
                    widget.itemAsString(item),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.90),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: widget.enabled
              ? (value) {
                  _valueNotifier.value = value;
                  widget.onChanged(value);
                }
              : null,
          hint: Text(
            widget.hintText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.45),
              fontWeight: FontWeight.w500,
            ),
          ),
          iconStyleData: IconStyleData(
            icon: Container(
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
            openMenuIcon: Container(
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
          dropdownStyleData: DropdownStyleData(
            maxHeight: widget.dropdownMaxHeight, // makes menu scrollable when many items
            isOverButton: false,
            useRootNavigator: true,
            offset: const Offset(0, 6),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          dropdownSearchData: widget.showSearchBox
              ? DropdownSearchData(
                  searchController: _searchController,
                  searchMatchFn: (item, searchValue) {
                    final text =
                        widget.itemAsString(item.value as T).toLowerCase();
                    return text.contains(searchValue.toLowerCase());
                  },
                )
              : null,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: margin,
            child: Text(
              widget.label!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.70),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: margin,
          child: container,
        ),
      ],
    );
  }
}

