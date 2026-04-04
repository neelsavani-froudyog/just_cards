import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/contact_detail_model.dart';
import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/create_contact_service.dart';
import '../../../core/services/toast_service.dart';

class EditContactController extends GetxController {
  late final ApiService _apiService;

  String? _contactId;
  String _source = 'manual';
  String? _organizationId;
  String? _eventId;
  String? _cardImgUrl;
  List<String> _tags = [];
  bool _allowShareOrganization = false;

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final email1Ctrl = TextEditingController();
  final email2Ctrl = TextEditingController();
  final phone1Ctrl = TextEditingController();
  final phone2Ctrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final designationCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final websiteCtrl = TextEditingController();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorText = RxnString();

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _contactId = _readContactId();
    if (_contactId == null || _contactId!.isEmpty) {
      isLoading.value = false;
      errorText.value = 'Missing contact id';
      return;
    }
    fetchContact();
  }

  String? _readContactId() {
    final args = Get.arguments;
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map) {
      final id = args['contactId'] ?? args['id'];
      final s = id?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return null;
  }

  static List<String> _parseTags(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  Future<void> fetchContact() async {
    final id = _contactId!.trim();
    isLoading.value = true;
    errorText.value = null;

    await _apiService.postRequest(
      url: ApiUrl.contactDetail,
      data: <String, dynamic>{'p_contact_id': id},
      showSuccessToast: false,
      showErrorToast: false,
      onSuccess: (payload) {
        final raw = payload['response'];
        if (raw is! Map<String, dynamic>) {
          errorText.value = 'Invalid response';
          return;
        }
        if (raw['ok'] != true) {
          errorText.value =
              raw['message']?.toString().trim().isNotEmpty == true
                  ? raw['message'].toString()
                  : 'Could not load contact';
          return;
        }
        final data = raw['data'];
        if (data is! Map<String, dynamic>) {
          errorText.value = 'Invalid contact data';
          return;
        }
        final d = ContactDetail.fromJson(data);
        _source = d.source.trim().isNotEmpty ? d.source : 'manual';
        _organizationId = d.organizationId;
        _eventId = d.eventId;
        _cardImgUrl = d.cardImgUrl;
        _tags = _parseTags(data['tags']);
        _allowShareOrganization = d.organizationId?.trim().isNotEmpty ?? false;

        firstNameCtrl.text = d.firstName;
        lastNameCtrl.text = d.lastName;
        email1Ctrl.text = d.email1 ?? '';
        email2Ctrl.text = d.email2 ?? '';
        phone1Ctrl.text = d.phone1 ?? '';
        phone2Ctrl.text = d.phone2 ?? '';
        addressCtrl.text = d.address;
        designationCtrl.text = d.designation;
        companyCtrl.text = d.companyName;
        websiteCtrl.text = d.website ?? '';
        errorText.value = null;
      },
      onError: (message) {
        final m = message.trim();
        errorText.value = m.isNotEmpty ? m : 'Could not load contact';
      },
    );

    isLoading.value = false;
  }

  Future<void> save() async {
    final id = _contactId?.trim() ?? '';
    if (id.isEmpty) {
      ToastService.error('Contact not available');
      return;
    }

    final first = firstNameCtrl.text.trim();
    final last = lastNameCtrl.text.trim();
    final email1 = email1Ctrl.text.trim();
    final email2 = email2Ctrl.text.trim();
    final phone1 = phone1Ctrl.text.trim();
    final phone2 = phone2Ctrl.text.trim();
    final address = addressCtrl.text.trim();
    final designation = designationCtrl.text.trim();
    final companyName = companyCtrl.text.trim();
    final website = websiteCtrl.text.trim();

    if (first.isEmpty) {
      ToastService.error('First name is required');
      return;
    }
    if (last.isEmpty) {
      ToastService.error('Last name is required');
      return;
    }
    if (companyName.isEmpty) {
      ToastService.error('Company name is required');
      return;
    }
    if (email1.isEmpty) {
      ToastService.error('Email 1 is required');
      return;
    }
    if (!email1.contains('@')) {
      ToastService.error('Please enter a valid email for Email 1');
      return;
    }
    if (phone1.isEmpty) {
      ToastService.error('Phone 1 is required');
      return;
    }

    if (isSaving.value) return;
    isSaving.value = true;
    try {
      final contactService = Get.find<CreateContactService>();
      final userId = await contactService.fetchProfileUserId();
      if (userId == null || userId.isEmpty) {
        ToastService.error('Could not load your user id');
        return;
      }

      final fullName = '$first $last'.trim().isEmpty
          ? 'Unnamed contact'
          : '$first $last'.trim();

      final updateResult = await contactService.updateContact(
        contactId: id,
        ownerUserId: userId,
        createdBy: userId,
        fullName: fullName,
        source: _source,
        organizationId: _organizationId,
        eventId: _eventId,
        allowShareOrganization: _allowShareOrganization,
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
        cardImgUrl: _cardImgUrl,
        tags: List<String>.from(_tags),
        profilePhotoUrl: null,
      );

      if (!updateResult.success) {
        ToastService.error(updateResult.message ?? 'Failed to update contact');
        return;
      }

      ToastService.success(updateResult.message ?? 'Contact updated');
      Get.back(result: true, closeOverlays: false);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    email1Ctrl.dispose();
    email2Ctrl.dispose();
    phone1Ctrl.dispose();
    phone2Ctrl.dispose();
    addressCtrl.dispose();
    designationCtrl.dispose();
    companyCtrl.dispose();
    websiteCtrl.dispose();
    super.onClose();
  }
}
