import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/toast_service.dart';
import '../../../routes/app_routes.dart';
import '../manage/manage_organization_controller.dart';

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

  String? _extractCreatedOrganizationId(dynamic raw) {
    final fromRoot = _parseOrganizationIdFromMap(raw);
    if (fromRoot != null) return fromRoot;
    if (raw is Map && raw['response'] != null) {
      return _parseOrganizationIdFromMap(raw['response']);
    }
    return null;
  }

  String? _parseOrganizationIdFromMap(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);

    final data = map['data'];
    if (data is Map) {
      final inner = Map<String, dynamic>.from(data);
      final id = inner['id'] ?? inner['organization_id'];
      if (id != null && id.toString().trim().isNotEmpty) {
        return id.toString();
      }
    }
    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map) {
        final inner = Map<String, dynamic>.from(first);
        final id = inner['id'] ?? inner['organization_id'];
        if (id != null && id.toString().trim().isNotEmpty) {
          return id.toString();
        }
      }
    }

    final id = map['id'] ?? map['organization_id'];
    if (id != null && id.toString().trim().isNotEmpty) {
      return id.toString();
    }
    return null;
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
      final payload = <String, dynamic>{
        'p_name': name,
        'p_private_by_default': isPrivateByDefault.value,
        'p_export_allowed': isExportAllowed.value,
        'p_admin_approval_required': isAdminApprovalRequired.value,
      };
      if (industry.trim().isNotEmpty) {
        payload['p_industry'] = industry.trim();
      }

      await _apiService.postRequest(
        url: ApiUrl.profileCreateOrganizations,
        data: payload,
        showSuccessToast: true,
        successToastMessage: 'Organization created successfully',
        showErrorToast: true,
        onSuccess: (payload) {
          final raw = payload['response'];
          final orgId = _extractCreatedOrganizationId(raw);
          _refreshOrganizationsList();
          if (orgId != null && orgId.isNotEmpty) {
            Get.offNamed(
              Routes.inviteMembers,
              arguments: <String, dynamic>{
                'organizationId': orgId,
                'name': name,
              },
            );
          } else {
            ToastService.info(
              'Open your organization from the list to invite members.',
            );
            Get.back(result: true);
          }
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
