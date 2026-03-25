import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';

class SentInvite {
  const SentInvite({
    required this.email,
    required this.role,
    required this.status,
  });

  final String email;
  final String role;
  final String status;
}

class InviteMembersController extends GetxController {
  final inviteEmailController = TextEditingController();
  final inviteMessageController = TextEditingController();

  final inviteRole = 'Editor'.obs;

  Map<String, dynamic>? _orgArgs;
  late final ApiService _apiService;

  @override
  void onInit() {
    super.onInit();
    _orgArgs = Get.arguments as Map<String, dynamic>?;
    _apiService = Get.find<ApiService>();
  }
  final isInviting = false.obs;

  final roles = const <String>['Admin', 'Editor', 'Viewer'];
  final sentInvites = <SentInvite>[].obs;

  @override
  void onClose() {
    inviteEmailController.dispose();
    inviteMessageController.dispose();
    super.onClose();
  }

  void setInviteRole(String? v) {
    if (v == null) return;
    inviteRole.value = v;
  }

  Future<void> sendInvite() async {
    if (isInviting.value) return;
    final email = inviteEmailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar('Invite', 'Please enter email');
      return;
    }
    final alreadyAdded = sentInvites.any(
      (i) => i.email.toLowerCase() == email.toLowerCase(),
    );
    if (alreadyAdded) {
      Get.snackbar('Invite', 'This email is already added');
      return;
    }
    isInviting.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      sentInvites.insert(
        0,
        SentInvite(email: email, role: inviteRole.value, status: 'Sent'),
      );
      inviteEmailController.clear();
      Get.snackbar('Invite', 'Invite added');
    } finally {
      isInviting.value = false;
    }
  }

  void removeInvite(SentInvite invite) => sentInvites.remove(invite);

  void skipForNow() {
    Get.back();
    Get.back();
  }

  Future<void> sendInvites() async {
    if (sentInvites.isEmpty) {
      Get.snackbar('Invite', 'Add at least one member');
      return;
    }
    if (isInviting.value) return;
    final orgId = _orgArgs?['organizationId']?.toString().trim() ?? '';
    if (orgId.isEmpty) {
      Get.snackbar('Invite', 'Organization ID is missing');
      return;
    }
    isInviting.value = true;
    try {
      final users = sentInvites
          .map(
            (invite) => <String, dynamic>{
              'email': invite.email,
              'role': invite.role.toLowerCase(),
              'invited_user_id': null,
            },
          )
          .toList();

      await _apiService.postRequest(
        url: ApiUrl.organizationsInvites,
        data: <String, dynamic>{
          'organization_id': orgId,
          'note': inviteMessageController.text.isNotEmpty ? inviteMessageController.text.trim() : null,
          'users': users,
        },
        showSuccessToast: true,
        successToastMessage: 'Invites sent successfully',
        showErrorToast: true,
        onSuccess: (_) {
          inviteMessageController.clear();
          sentInvites.clear();
          Get.back();
        },
        onError: (_) {},
      );
    } finally {
      isInviting.value = false;
    }
  }
}
