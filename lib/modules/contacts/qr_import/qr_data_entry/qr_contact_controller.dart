import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/create_contact_service.dart';
import '../../../../core/services/api.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/document_scanner_service.dart';
import '../../../../core/services/http_sender_io.dart';
import '../../../../core/services/toast_service.dart';
import 'qr_add_tag_dialog.dart';
import 'qr_organization_simple_model.dart';
import '../../../home/home_events_model.dart';

class QrContactController extends GetxController {
  final isSaving = false.obs;
  late final ApiService _apiService;

  /// Set when opened from QR import (`__appBarTitle` in route arguments).
  String qrImportTitle = 'Contact from QR';

  Map<String, dynamic>? _qrPrefill;
  String? _pendingQrOrganizationName;
  bool _qrBasicApplied = false;

  final cardImagePath = RxnString();

  final salutations = <String>['Mr.', 'Ms.', 'Mrs.', 'Dr.'];
  final salutation = 'Mr.'.obs;

  final fullNameCtrl = TextEditingController();
  final jobTitleCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final primaryEmailCtrl = TextEditingController();
  final secondaryEmailCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  static const String noneOrganization = 'Select organization';

  // Names only (for dropdown UI). We keep the full options list to map back to IDs if needed.
  final organizations = <String>[noneOrganization].obs;
  final selectedOrganization = noneOrganization.obs;
  final selectedOrganizationId = RxnString();

  final _organizationOptions = <OrganizationOption>[];
  final isOrganizationsLoading = false.obs;

  static const String noneEvent = 'Select event';

  // Names only (for dropdown UI).
  final events = <String>[noneEvent].obs;
  final selectedEvent = noneEvent.obs;
  final selectedEventId = RxnString();

  final _eventOptions = <HomeEventItem>[];
  final isEventsLoading = false.obs;

  final selectedTags = <String>['Lead', 'Follow-up'].obs;
  final suggestedTags = <String>['Priority', 'VIP', 'Prospect'].obs;

  final shareWithOrganization = false.obs;
  final phone1CountryIso = 'IN'.obs;
  final phone2CountryIso = 'IN'.obs;

  /// Replace with real IDs from your events API when available.
  static const Map<String, String> _eventIdByLabel = <String, String>{
    'Electronica 2026': '0495f860-b490-4901-bf65-4ea7ad7f1b97',
    'PlastIndia 2026': '0495f860-b490-4901-bf65-4ea7ad7f1b97',
    'Aahar Expo': '0495f860-b490-4901-bf65-4ea7ad7f1b97',
    'Smart Tech': '0495f860-b490-4901-bf65-4ea7ad7f1b97',
    'Other': '0495f860-b490-4901-bf65-4ea7ad7f1b97',
  };

  void setPhone1Country(Country country) {
    phone1CountryIso.value = country.countryCode;
  }

  void setPhone2Country(Country country) {
    phone2CountryIso.value = country.countryCode;
  }

  static String composeInternationalPhone(
    String iso3166alpha2,
    String nationalRaw,
  ) {
    final c = Country.tryParse(iso3166alpha2);
    final pc = (c?.phoneCode ?? '91').trim();
    final codeDigits = pc.replaceAll(RegExp(r'\D'), '');
    final digits = nationalRaw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    return '+$codeDigits$digits';
  }

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _readQrPrefillArgs();
    _applyQrBasicFields();
    fetchOrganizations();
    fetchAllEvents();
  }

  void _readQrPrefillArgs() {
    final args = Get.arguments;
    if (args is! Map) return;
    final m = Map<String, dynamic>.from(args);
    final title = m.remove('__appBarTitle')?.toString().trim();
    if (title != null && title.isNotEmpty) {
      qrImportTitle = title;
    }
    if (m.isEmpty) return;
    _qrPrefill = m;
    final org = _qrPrefill!['organization']?.toString().trim();
    if (org != null && org.isNotEmpty) {
      _pendingQrOrganizationName = org;
    }
  }

  void _applyQrBasicFields() {
    if (_qrPrefill == null || _qrBasicApplied) return;
    _qrBasicApplied = true;

    final qrFirst = _qrPrefill!['firstName']?.toString().trim() ?? '';
    final qrLast = _qrPrefill!['lastName']?.toString().trim() ?? '';
    final qrFullName = _qrPrefill!['fullName']?.toString().trim() ?? '';

    final combinedName = qrFullName.isNotEmpty
        ? qrFullName
        : '$qrFirst $qrLast'.trim();
    if (combinedName.isNotEmpty) {
      fullNameCtrl.text = combinedName;
    }

    final qrOrganization = _qrPrefill!['organization']?.toString().trim() ?? '';
    final qrJobTitle = _qrPrefill!['jobTitle']?.toString().trim() ?? '';
    final qrWebsite = _qrPrefill!['website']?.toString().trim() ?? '';
    final qrAddress = _qrPrefill!['address']?.toString().trim() ?? '';

    if (qrOrganization.isNotEmpty) companyCtrl.text = qrOrganization;
    if (qrJobTitle.isNotEmpty) jobTitleCtrl.text = qrJobTitle;
    if (qrWebsite.isNotEmpty) websiteCtrl.text = qrWebsite;
    if (qrAddress.isNotEmpty) addressCtrl.text = qrAddress;

    final qrPhonesRaw = _qrPrefill!['phones'];
    final qrEmailsRaw = _qrPrefill!['emails'];

    final qrPhones = qrPhonesRaw is List
        ? qrPhonesRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    final qrEmails = qrEmailsRaw is List
        ? qrEmailsRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    if (qrPhones.isNotEmpty) mobileCtrl.text = qrPhones.first;
    if (qrPhones.length > 1) phoneCtrl.text = qrPhones[1];

    if (qrEmails.isNotEmpty) primaryEmailCtrl.text = qrEmails.first;
    if (qrEmails.length > 1) secondaryEmailCtrl.text = qrEmails[1];
  }

  void setOrganization(String? v) {
    FocusScope.of(Get.context!).unfocus();
    if (v == null) return;
    selectedOrganization.value = v;

    if (v == noneOrganization) {
      selectedOrganizationId.value = null;
      shareWithOrganization.value = false;
      // No organization selected => show all events
      unawaited(fetchAllEvents());
      return;
    }

    OrganizationOption? selected;
    for (final item in _organizationOptions) {
      if (item.name == v) {
        selected = item;
        break;
      }
    }
    selectedOrganizationId.value = selected?.id;
    shareWithOrganization.value = true;

    unawaited(fetchEventsByOrganization(selectedOrganizationId.value));
  }

  void setEvent(String? v) {
    FocusScope.of(Get.context!).unfocus();
    if (v == null) return;
    selectedEvent.value = v;

    if (v == noneEvent) {
      selectedEventId.value = null;
      return;
    }

    HomeEventItem? selected;
    for (final item in _eventOptions) {
      if (item.title == v) {
        selected = item;
        break;
      }
    }
    selectedEventId.value = selected?.id;
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

          final parsed = OrganizationsSimpleResponse.fromJson(raw);
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
          shareWithOrganization.value = false;

          final pendingOrg = _pendingQrOrganizationName;
          _pendingQrOrganizationName = null;
          if (pendingOrg != null &&
              pendingOrg.trim().isNotEmpty &&
              _organizationOptions.any((o) => o.name == pendingOrg.trim())) {
            setOrganization(pendingOrg.trim());
          }
        },
        onError: (_) {},
      );
    } finally {
      isOrganizationsLoading.value = false;
    }
  }

  Future<void> fetchAllEvents() async {
    if (isEventsLoading.value) return;
    isEventsLoading.value = true;
    try {
      await _apiService.getRequest(
        url: ApiUrl.events,
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) return;

          final parsed = HomeEventsResponse.fromJson(raw);
          if (!parsed.ok) return;

          _eventOptions
            ..clear()
            ..addAll(parsed.data);

          final names = <String>[
            noneEvent,
            ..._eventOptions
                .map((e) => e.title.trim())
                .where((t) => t.isNotEmpty),
          ];

          events.assignAll(names);
          selectedEvent.value = noneEvent;
          selectedEventId.value = null;
        },
        onError: (_) {},
      );
    } finally {
      isEventsLoading.value = false;
    }
  }

  Future<void> fetchEventsByOrganization(String? organizationId) async {
    final orgId = organizationId?.trim();
    if (orgId == null || orgId.isEmpty) {
      // No organization selected => show all events
      await fetchAllEvents();
      return;
    }

    if (isEventsLoading.value) return;
    isEventsLoading.value = true;
    try {
      await _apiService.postRequest(
        url: ApiUrl.eventsByOrganization,
        data: <String, dynamic>{
          'p_organization_id': orgId,
        },
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) return;

          final parsed = HomeEventsResponse.fromJson(raw);
          if (!parsed.ok) return;

          _eventOptions
            ..clear()
            ..addAll(parsed.data);

          final names = <String>[
            noneEvent,
            ..._eventOptions
                .map((e) => e.title.trim())
                .where((t) => t.isNotEmpty),
          ];

          events.assignAll(names);
          selectedEvent.value = noneEvent;
          selectedEventId.value = null;
        },
        onError: (_) {},
      );
    } finally {
      isEventsLoading.value = false;
    }
  }

  Future<void> pickCardImage() async {
    final images = await DocumentScannerService.scan(allowMultiple: false);
    if (images.isEmpty) return;
    cardImagePath.value = images.first;
  }

  bool get hasCardImage {
    final path = cardImagePath.value;
    return path != null && path.isNotEmpty;
  }

  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }
  }

  void addSuggestedTag() {
    final remaining = suggestedTags.where((t) => !selectedTags.contains(t));
    if (remaining.isEmpty) {
      ToastService.error('No more suggested tags');
      return;
    }
    selectedTags.add(remaining.first);
  }

  Future<void> openAddTagDialog() async {
    await Get.dialog<void>(
      QrAddTagDialog(selectedTags: selectedTags),
      barrierDismissible: true,
    );
  }

  Future<void> saveContact() async {
    if (isSaving.value) return;

    // Trim & validate required fields before doing any network calls.
    final fullNameRaw = fullNameCtrl.text.trim();
    final nameParts = fullNameRaw
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    final first = nameParts.isNotEmpty ? nameParts.first : '';
    final last =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final designation = jobTitleCtrl.text.trim();
    final companyName = companyCtrl.text.trim();
    final website = websiteCtrl.text.trim();
    final email1 = primaryEmailCtrl.text.trim();
    final email2 = secondaryEmailCtrl.text.trim();
    final national1 = mobileCtrl.text.trim();
    final national2 = phoneCtrl.text.trim();
    final phone1 = composeInternationalPhone(
      phone1CountryIso.value,
      national1,
    );
    final phone2 = national2.isEmpty
        ? ''
        : composeInternationalPhone(phone2CountryIso.value, national2);
    final address = addressCtrl.text.trim();

    if (first.isEmpty) {
      ToastService.error('Full name is required');
      return;
    }
    if (companyName.isEmpty) {
      ToastService.error('Company name is required');
      return;
    }
    if (email1.isEmpty) {
      ToastService.error('Primary email is required');
      return;
    }
    if (!email1.contains('@')) {
      ToastService.error('Please enter a valid email address');
      return;
    }
    if (phone1.isEmpty || national1.replaceAll(RegExp(r'\D'), '').isEmpty) {
      ToastService.error('Mobile number is required');
      return;
    }

    isSaving.value = true;
    try {
      // 1) Upload image first.
      final session = Get.find<AuthSessionService>();
      final token = session.accessToken.value.trim();
      if (token.isEmpty) {
        ToastService.error('Please sign in again');
        return;
      }

      final contactService = Get.find<CreateContactService>();
      final userId = await contactService.fetchProfileUserId();
      if (userId == null || userId.isEmpty) {
        ToastService.error('Could not load your user id');
        return;
      }

      final fullName = '$first $last'.trim().isEmpty
          ? 'Unnamed contact'
          : '$first $last'.trim();

      final createResult = await contactService.createContact(
        ownerUserId: userId,
        organizationId: selectedOrganizationId.value == null || selectedOrganizationId.value == noneOrganization ? null : selectedOrganizationId.value as String,
        createdBy: userId,
        fullName: fullName,
        source: 'manual',
        eventId: selectedEventId.value == null || selectedEventId.value == noneEvent ? null : selectedEventId.value as String,
        allowShareOrganization: shareWithOrganization.value,
        firstName: first,
        lastName: last,
        designation: designation,
        companyName: companyName,
        email1: email1,
        email2: email2.isEmpty ? null : email2,
        phone1: phone1,
        phone2: phone2.isEmpty ? null : phone2,
        address: address,
        website: website,
        cardImgUrl: null,
        tags: List<String>.from(selectedTags),
        profilePhotoUrl: null,
      );

      if (!createResult.success) {
        ToastService.error(createResult.message ?? 'Failed to save contact');
        return;
      }

      ToastService.success(createResult.message ?? 'Saved');
      Get.back(result: true, closeOverlays: false);
      return;
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    fullNameCtrl.dispose();
    jobTitleCtrl.dispose();
    companyCtrl.dispose();
    mobileCtrl.dispose();
    phoneCtrl.dispose();
    primaryEmailCtrl.dispose();
    secondaryEmailCtrl.dispose();
    websiteCtrl.dispose();
    addressCtrl.dispose();
    super.onClose();
  }
}
