import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';

class CreateOrganizationController extends GetxController {
  final organizationNameController = TextEditingController();
  final roleController = TextEditingController(text: 'Owner');

  final selectedIndustry = RxnString();
  final isPrivateByDefault = true.obs;
  final isExportAllowed = false.obs;
  final isAdminApprovalRequired = true.obs;

  final errorText = RxnString();
  final isSubmitting = false.obs;

  final industries = const <String>[
    'Electronics',
    'Software',
    'Manufacturing',
    'Healthcare',
    'Finance',
    'Education',
    'Retail',
    'Other',
  ];

  @override
  void onClose() {
    organizationNameController.dispose();
    roleController.dispose();
    super.onClose();
  }

  void setIndustry(String? v) => selectedIndustry.value = v;

  Future<void> submit() async {
    errorText.value = null;
    final name = organizationNameController.text.trim();
    if (name.isEmpty) {
      errorText.value = 'Organisation name is required';
      return;
    }
    if (isSubmitting.value) return;
    isSubmitting.value = true;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 800));
      Get.snackbar('Organisation', 'Created successfully');
      Get.toNamed(Routes.inviteMembers);
    } finally {
      isSubmitting.value = false;
    }
  }
}

