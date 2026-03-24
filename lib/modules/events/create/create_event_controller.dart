import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import 'event_organizations_model.dart';

class CreateEventController extends GetxController {
  static const String noneOrganization = 'None';

  late final ApiService _apiService;
  final nameController = TextEditingController();
  final dateController = TextEditingController();
  final locationController = TextEditingController();
  final notesController = TextEditingController();

  final selectedDate = DateTime.now().obs;
  final selectedOrganization = RxnString();
  final organizations = <String>[noneOrganization].obs;
  final selectedOrganizationId = RxnString();
  final isOrganizationsLoading = false.obs;

  final isSaving = false.obs;
  final errorText = RxnString();
  final locationErrorText = RxnString();

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    dateController.text = dateLabel;
    selectedOrganization.value = noneOrganization;
    fetchOrganizations();
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

  void setOrganization(String? v) {
    selectedOrganization.value = v;
    if (v == null || v == noneOrganization) {
      selectedOrganizationId.value = null;
      return;
    }
    EventOrganizationOption? selected;
    for (final item in _organizationOptions) {
      if (item.name == v) {
        selected = item;
        break;
      }
    }
    selectedOrganizationId.value = selected?.id;
  }

  final _organizationOptions = <EventOrganizationOption>[];

  Future<void> fetchOrganizations() async {
    if (isOrganizationsLoading.value) return;
    isOrganizationsLoading.value = true;
    try {
      await _apiService.getRequest(
        url: ApiUrl.profileOrganizationsSimple,
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) return;
          final parsed = EventOrganizationsResponse.fromJson(raw);
          if (!parsed.ok) return;

          _organizationOptions
            ..clear()
            ..addAll(parsed.data);

          final names = <String>[
            noneOrganization,
            ..._organizationOptions
                .map((e) => e.name.trim())
                .where((e) => e.isNotEmpty),
          ];
          organizations.assignAll(names);
          selectedOrganization.value = noneOrganization;
          selectedOrganizationId.value = null;
        },
        onError: (_) {},
      );
    } finally {
      isOrganizationsLoading.value = false;
    }
  }

  Future<void> save() async {
    errorText.value = null;
    locationErrorText.value = null;
    final name = nameController.text.trim();
    final location = locationController.text.trim();
    final notes = notesController.text.trim();

    if (name.isEmpty) {
      errorText.value = 'Event name is required';
      return;
    }
    if (location.isEmpty) {
      locationErrorText.value = 'Location is required';
      return;
    }

    if (isSaving.value) return;
    isSaving.value = true;

    final d = selectedDate.value;
    final eventDate =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    try {
      final payload = <String, dynamic>{
        'p_name': name,
        'p_event_date': eventDate,
        'p_location_text': location,
        'p_organization_id': selectedOrganizationId.value,
      };
      if (notes.isNotEmpty) {
        payload['p_notes'] = notes;
      }

      await _apiService.postRequest(
        url: ApiUrl.events,
        data: payload,
        showSuccessToast: true,
        successToastMessage: 'Event created successfully',
        showErrorToast: true,
        onSuccess: (_) {
          Get.back(result: true, closeOverlays: false);
        },
        onError: (message) {
          errorText.value =
              message.isNotEmpty ? message : 'Failed to create event';
        },
      );
    } finally {
      isSaving.value = false;
    }
  }
}

