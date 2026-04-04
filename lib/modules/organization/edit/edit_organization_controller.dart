import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../manage/manage_organization_controller.dart';

class EditOrganizationArgs {
  const EditOrganizationArgs({
    required this.organizationId,
    required this.name,
    this.industry,
    this.role,
    this.isActive = true,
  });

  final String organizationId;
  final String name;
  final String? industry;
  final String? role;
  final bool isActive;

  factory EditOrganizationArgs.from(dynamic args) {
    if (args is EditOrganizationArgs) return args;
    if (args is Map) {
      return EditOrganizationArgs(
        organizationId: args['organizationId']?.toString() ?? '',
        name: args['name']?.toString() ?? '',
        industry: args['industry']?.toString(),
        role: args['role']?.toString(),
        isActive: args['isActive'] != false,
      );
    }
    return const EditOrganizationArgs(organizationId: '', name: '');
  }
}

class EditOrganizationController extends GetxController {
  late final EditOrganizationArgs args;
  late final ApiService _apiService;

  final organizationNameController = TextEditingController();
  final otherIndustryController = TextEditingController();
  final roleController = TextEditingController();

  final selectedIndustry = RxnString();
  final isActive = true.obs;
  final isPrivateByDefault = true.obs;
  final isExportAllowed = true.obs;
  final isAdminApprovalRequired = true.obs;
  final allowEditorsCreateEvents = true.obs;
  final allowEditorsMoveContacts = true.obs;
  final allowMembersViewAllContacts = true.obs;

  final errorText = RxnString();
  final isSubmitting = false.obs;

  /// Same list as [CreateOrganizationController.industries].
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
    args = EditOrganizationArgs.from(Get.arguments);
    organizationNameController.text = args.name.trim();
    roleController.text =
        'Owner';
    isActive.value = args.isActive;
    _applyInitialIndustry(args.industry);
  }


  void _applyInitialIndustry(String? industry) {
    final raw = industry?.trim() ?? '';
    if (raw.isEmpty) {
      selectedIndustry.value = null;
      return;
    }
    if (industries.contains(raw)) {
      selectedIndustry.value = raw;
      return;
    }
    selectedIndustry.value = 'Other';
    otherIndustryController.text = raw;
  }

  void setIndustry(String? v) {
    selectedIndustry.value = v;
    if (v != 'Other') {
      otherIndustryController.clear();
    }
  }

  @override
  void onClose() {
    organizationNameController.dispose();
    otherIndustryController.dispose();
    roleController.dispose();
    super.onClose();
  }

  void _refreshOrganizationsList() {
    if (Get.isRegistered<ManageOrganizationController>()) {
      Get.find<ManageOrganizationController>().fetchOrganizations();
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
      final industry = selected == 'Other' ? customIndustry : (selected ?? '');
      final industryTrimmed = industry.trim();
      final payload = <String, dynamic>{
        'p_org_id': args.organizationId,
        'p_name': name,
        'p_industry': industryTrimmed,
        'p_is_active': true,
        'p_private_by_default': isPrivateByDefault.value,
        'p_export_allowed': isExportAllowed.value,
        'p_admin_approval_required': isAdminApprovalRequired.value,
        'p_allow_editors_create_events': null,
        'p_allow_editors_move_contacts': null,
        'p_allow_members_view_all_contacts': true,
      };

      await _apiService.patchRequest(
        url: ApiUrl.profileUpdateOrganization,
        data: payload,
        showSuccessToast: true,
        successToastMessage: 'Organization updated',
        showErrorToast: true,
        onSuccess: (_) {
          _refreshOrganizationsList();
          Get.back(result: <String, dynamic>{
            'name': name,
            'industry': industryTrimmed,
          });
        },
        onError: (message) {
          errorText.value = (message != null && message.isNotEmpty)
              ? message
              : 'Failed to update organization';
        },
      );
    } finally {
      isSubmitting.value = false;
    }
  }
}
