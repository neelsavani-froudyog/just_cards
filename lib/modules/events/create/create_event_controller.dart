import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';

class CreateEventController extends GetxController {
  final nameController = TextEditingController();
  final dateController = TextEditingController();
  final locationController = TextEditingController();
  final notesController = TextEditingController();

  final selectedDate = DateTime.now().obs;
  final selectedOrganization = RxnString();

  final organizations = const <String>[
    'None',
    'Electronica Expo',
    'Ombyte Systems LLP',
  ];

  final isSaving = false.obs;
  final errorText = RxnString();

  @override
  void onInit() {
    super.onInit();
    dateController.text = dateLabel;
    selectedOrganization.value = organizations.first;
  }

  @override
  void onClose() {
    nameController.dispose();
    dateController.dispose();
    locationController.dispose();
    notesController.dispose();
    super.onClose();
  }

  String get dateLabel {
    final d = selectedDate.value;
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select date',
      builder: (context, child) {
        final base = Theme.of(context);
        final scheme = base.colorScheme;
        final themed = base.copyWith(
          colorScheme: scheme.copyWith(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            secondary: AppColors.primary,
            onSecondary: AppColors.white,
            surface: AppColors.white,
            onSurface: AppColors.ink,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            headerBackgroundColor: AppColors.primary,
            headerForegroundColor: AppColors.white,
            todayBorder: BorderSide(color: AppColors.primary.withValues(alpha: 0.55)),
            todayForegroundColor: WidgetStateProperty.resolveWith((states) {
              // Use dark text on brand fill for better visibility.
              if (states.contains(WidgetState.selected)) return AppColors.surface;
              return AppColors.primary;
            }),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              // Use dark text on brand fill for better visibility.
              if (states.contains(WidgetState.selected)) return AppColors.surface;
              return AppColors.ink;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.primary;
              return Colors.transparent;
            }),
            yearForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.surface;
              return AppColors.ink;
            }),
            yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.primary;
              return Colors.transparent;
            }),
            dividerColor: AppColors.ink.withValues(alpha: 0.08),
            weekdayStyle: base.textTheme.labelMedium?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        return Theme(data: themed, child: child!);
      },
    );
    if (picked != null) {
      selectedDate.value = picked;
      dateController.text = dateLabel;
    }
  }

  void setOrganization(String? v) => selectedOrganization.value = v;

  Future<void> save() async {
    errorText.value = null;
    if (nameController.text.trim().isEmpty) {
      errorText.value = 'Event name is required';
      return;
    }
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      // Close only the current bottom sheet overlay.
      Get.back(closeOverlays: false);
      Get.snackbar('Event', 'Saved');
    } finally {
      isSaving.value = false;
    }
  }
}

