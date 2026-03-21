import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
  }

  Future<void> sendInvites() async {
    if (sentInvites.isEmpty) {
      Get.snackbar('Invite', 'Add at least one member');
      return;
    }
    if (isInviting.value) return;
    isInviting.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      inviteMessageController.clear();
      Get.snackbar('Invite', 'Invites sent');
      Get.back();
    } finally {
      isInviting.value = false;
    }
  }
}
