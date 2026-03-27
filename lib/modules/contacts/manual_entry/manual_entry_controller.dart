import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
    isSaving.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      Get.snackbar('Contact', 'Saved');
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
