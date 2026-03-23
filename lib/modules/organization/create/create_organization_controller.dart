import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';

class CreateOrganizationController extends GetxController {
  final organizationNameController = TextEditingController();
  final otherIndustryController = TextEditingController();
  final roleController = TextEditingController(text: 'Owner');

  final selectedIndustry = RxnString();
  final isPrivateByDefault = true.obs;
  final isExportAllowed = true.obs;
  final isAdminApprovalRequired = true.obs;

  final errorText = RxnString();
  final isSubmitting = false.obs;
  late final ApiService _apiService;

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
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
  }

  @override
  void onClose() {
    organizationNameController.dispose();
    otherIndustryController.dispose();
    roleController.dispose();
    super.onClose();
  }

  void setIndustry(String? v) {
    selectedIndustry.value = v;
    if (v != 'Other') {
      otherIndustryController.clear();
    }
  }

  Future<void> submit() async {
    errorText.value = null;
    final name = organizationNameController.text.trim();
    if (name.isEmpty) {
      errorText.value = 'Organisation name is required';
      return;
    }
    final selected = selectedIndustry.value;
    final customIndustry = otherIndustryController.text.trim();
    if (selected == 'Other' && customIndustry.isEmpty) {
      errorText.value = 'Please enter industry name';
      return;
    }
    if (isSubmitting.value) return;
    isSubmitting.value = true;

    try {
      await _apiService.postRequest(
        url: ApiUrl.profileCreateOrganizations,
        data: <String, dynamic>{
          'p_name': name,
          'p_industry': selected == 'Other'
              ? customIndustry
              : (selected ?? ''),
          'p_private_by_default': isPrivateByDefault.value,
          'p_export_allowed': isExportAllowed.value,
          'p_admin_approval_required': isAdminApprovalRequired.value,
        },
        showSuccessToast: true,
        successToastMessage: 'Organization created successfully',
        showErrorToast: true,
        onSuccess: (_) {
          Get.back(result: true);
        },
        onError: (message) {
          errorText.value = message.isNotEmpty
              ? message
              : 'Failed to create organization';
        },
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
