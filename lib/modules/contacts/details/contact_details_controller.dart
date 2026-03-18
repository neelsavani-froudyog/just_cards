import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ContactDetailsTab { details, notes, attachments }

class ContactDetailsController extends GetxController {
  final tab = ContactDetailsTab.details.obs;
  final isSaving = false.obs;

  final notesCtrl = TextEditingController();

  final photos = <String>[].obs;
  final docs = <String>[].obs;

  @override
  void onClose() {
    notesCtrl.dispose();
    super.onClose();
  }

  void setTab(ContactDetailsTab t) => tab.value = t;

  Future<void> saveChanges() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      Get.snackbar('Contact', 'Changes saved');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> addAttachment() async {
    // Placeholder until file picker integration is added.
    photos.add('photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
  }
}

