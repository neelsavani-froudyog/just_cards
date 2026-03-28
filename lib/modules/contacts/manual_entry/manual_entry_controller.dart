import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/business_card_upload_service.dart';
import '../../../core/services/create_contact_service.dart';
import '../../../core/services/document_scanner_service.dart';
import 'add_tag_dialog.dart';

class ManualEntryController extends GetxController {
  final isSaving = false.obs;

  final cardImagePath = RxnString();

  final salutations = <String>['Mr.', 'Ms.', 'Mrs.', 'Dr.'];
  final salutation = 'Mr.'.obs;

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final jobTitleCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final primaryEmailCtrl = TextEditingController();
  final secondaryEmailCtrl = TextEditingController();

  final organizations = const <String>[
    'Select organization',
    'Galaxy Infotect Limited',
    'Ombyte Systems LLP',
    'Other',
  ];
  final selectedOrganization = 'Select organization'.obs;

  final events = const <String>[
    'Select event',
    'Electronica 2026',
    'PlastIndia 2026',
    'Aahar Expo',
    'Smart Tech',
    'Other',
  ];
  final selectedEvent = 'Select event'.obs;

  final selectedTags = <String>['Lead', 'Follow-up'].obs;
  final suggestedTags = <String>['Priority', 'VIP', 'Prospect'].obs;

  final shareWithOrganization = true.obs;

  /// Replace with real IDs from your events API when available.
  static const Map<String, String> _eventIdByLabel = <String, String>{
    'Electronica 2026': '0495f860-b490-4901-bf65-4ea7ad7f1b97',
    'PlastIndia 2026': '0495f860-b490-4901-bf65-4ea7ad7f1b97',
    'Aahar Expo': '0495f860-b490-4901-bf65-4ea7ad7f1b97',
    'Smart Tech': '0495f860-b490-4901-bf65-4ea7ad7f1b97',
    'Other': '0495f860-b490-4901-bf65-4ea7ad7f1b97',
  };

  void setOrganization(String? v) {
    if (v != null) selectedOrganization.value = v;
  }

  void setEvent(String? v) {
    if (v != null) selectedEvent.value = v;
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
      Get.snackbar('Tags', 'No more suggested tags');
      return;
    }
    selectedTags.add(remaining.first);
  }

  Future<void> openAddTagDialog() async {
    await Get.dialog<void>(
      AddTagDialog(selectedTags: selectedTags),
      barrierDismissible: true,
    );
  }

  Future<void> saveContact() async {
    if (isSaving.value) return;

    final path = cardImagePath.value?.trim() ?? '';
    if (path.isEmpty) {
      Get.snackbar('Card image', 'Add a business card image at the top first');
      return;
    }

    final eventLabel = selectedEvent.value.trim();
    if (eventLabel.isEmpty || eventLabel == 'Select event') {
      Get.snackbar('Event', 'Select an event for this upload');
      return;
    }

    final file = File(path);
    if (!await file.exists()) {
      Get.snackbar('Card image', 'Image file is missing. Scan again.');
      return;
    }

    isSaving.value = true;
    try {
      final result = await Get.find<BusinessCardUploadService>().upload(
        eventName: eventLabel,
        imageFile: file,
      );

      if (!result.success) {
        Get.snackbar(
          'Upload failed',
          result.message ?? 'Unknown error',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      final publicUrl = result.publicUrl;
      if (publicUrl == null || publicUrl.isEmpty) {
        Get.snackbar('Upload', 'No image URL returned');
        return;
      }

      final contactService = Get.find<CreateContactService>();
      final userId = await contactService.fetchProfileUserId();
      if (userId == null || userId.isEmpty) {
        Get.snackbar('Profile', 'Could not load your user id');
        return;
      }

      final first = firstNameCtrl.text.trim();
      final last = lastNameCtrl.text.trim();
      final fullName = '$first $last'.trim().isEmpty
          ? 'Unnamed contact'
          : '$first $last'.trim();

      final eventId = _eventIdByLabel[eventLabel] ?? '0495f860-b490-4901-bf65-4ea7ad7f1b97';

      final createResult = await contactService.createContact(
        ownerUserId: userId,
        createdBy: userId,
        fullName: fullName,
        source: 'manual',
        eventId: eventId,
        allowShareOrganization: shareWithOrganization.value,
        firstName: first,
        lastName: last,
        designation: jobTitleCtrl.text.trim(),
        companyName: companyCtrl.text.trim(),
        email1: primaryEmailCtrl.text.trim(),
        email2: secondaryEmailCtrl.text.trim(),
        phone1: mobileCtrl.text.trim(),
        phone2: phoneCtrl.text.trim(),
        address: '',
        website: '',
        cardImgUrl: publicUrl,
        tags: List<String>.from(selectedTags),
        profilePhotoUrl: null,
      );

      if (!createResult.success) {
        Get.snackbar(
          'Contact',
          createResult.message ?? 'Failed to save contact',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      Get.snackbar(
        'Contact',
        createResult.message ?? 'Saved',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back();
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    jobTitleCtrl.dispose();
    companyCtrl.dispose();
    mobileCtrl.dispose();
    phoneCtrl.dispose();
    primaryEmailCtrl.dispose();
    secondaryEmailCtrl.dispose();
    super.onClose();
  }
}
