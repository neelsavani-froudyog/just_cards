import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../create/event_organizations_model.dart';

class EditEventArgs {
  const EditEventArgs({
    required this.eventId,
    required this.title,
    required this.location,
    this.eventDateIso = '',
    this.notes = '',
    this.organizationId,
  });

  final String eventId;
  final String title;
  final String location;
  final String eventDateIso;
  final String notes;
  final String? organizationId;

  factory EditEventArgs.from(dynamic args) {
    if (args is EditEventArgs) return args;
    if (args is Map) {
      return EditEventArgs(
        eventId: args['eventId']?.toString() ?? '',
        title: args['title']?.toString() ?? '',
        location: args['location']?.toString() ?? '',
        eventDateIso:
            (args['eventDate'] ?? args['event_date'] ?? '').toString(),
        notes: args['notes']?.toString() ?? '',
        organizationId: args['organizationId']?.toString() ??
            args['organization_id']?.toString(),
      );
    }
    return const EditEventArgs(eventId: '', title: '', location: '');
  }
}

class EditEventController extends GetxController {
  static const String noneOrganization = 'None';

  late final EditEventArgs args;
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

  final _organizationOptions = <EventOrganizationOption>[];

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    args = EditEventArgs.from(Get.arguments);
    nameController.text = args.title.trim();
    locationController.text = args.location.trim();
    notesController.text = args.notes.trim();

    final parsed = _parseIsoDate(args.eventDateIso);
    if (parsed != null) {
      selectedDate.value = parsed;
    }
    dateController.text = dateLabel;

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

  DateTime? _parseIsoDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final p = s.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: AppColors.white,
            surfaceTintColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            headerBackgroundColor: AppColors.primary,
            headerForegroundColor: AppColors.white,
            todayBorder: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.55),
            ),
            todayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return AppColors.surface;
              return AppColors.primary;
            }),
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
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

  void _syncOrganizationSelectionFromArgs() {
    final id = args.organizationId?.trim();
    if (id == null || id.isEmpty) {
      selectedOrganization.value = noneOrganization;
      selectedOrganizationId.value = null;
      return;
    }
    for (final item in _organizationOptions) {
      if (item.id == id) {
        selectedOrganization.value = item.name;
        selectedOrganizationId.value = item.id;
        return;
      }
    }
    selectedOrganization.value = noneOrganization;
    selectedOrganizationId.value = null;
  }

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
          _syncOrganizationSelectionFromArgs();
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
        'p_event_id': args.eventId,
        'p_name': name,
        'p_event_date': eventDate,
        'p_location_text': location,
        'p_organization_id': selectedOrganizationId.value,
        'p_notes': notes,
      };

      await _apiService.patchRequest(
        url: ApiUrl.events,
        data: payload,
        showSuccessToast: true,
        successToastMessage: 'Event updated',
        showErrorToast: true,
        onSuccess: (_) {
          Get.back(result: <String, dynamic>{
            'title': name.isNotEmpty ? name : null,
            'location': location.isNotEmpty ? location : null,
            'eventDate': eventDate.isNotEmpty ? eventDate : null,
            'notes': notes.isNotEmpty ? notes : null,
            'organizationId': selectedOrganizationId.value?.trim().isNotEmpty == true ? selectedOrganizationId.value : null,
          });
        },
        onError: (message) {
          errorText.value = (message != null && message.isNotEmpty)
              ? message
              : 'Failed to update event';
        },
      );
    } finally {
      isSaving.value = false;
    }
  }
}
