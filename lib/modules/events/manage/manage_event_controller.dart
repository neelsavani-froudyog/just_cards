import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManageEventController extends GetxController {
  late final ManageEventArgs args;

  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  // Invites tab
  final inviteEmailController = TextEditingController();
  final inviteMessageController = TextEditingController();
  final inviteRole = 'Editor'.obs;
  final isInviting = false.obs;

  final contacts = <EventPerson>[
    const EventPerson(name: 'Alok Shaw', email: 'sarah.shaw@forudyog.com', companyOrRole: 'Ombyte Systems LLP'),
    const EventPerson(name: 'Alok Shaw', email: 'sarah.shaw@forudyog.com', companyOrRole: 'Ombyte Systems LLP'),
    const EventPerson(name: 'Alok Shaw', email: 'sarah.shaw@forudyog.com', companyOrRole: 'Ombyte Systems LLP'),
    const EventPerson(name: 'Alok Shaw', email: 'sarah.shaw@forudyog.com', companyOrRole: 'Ombyte Systems LLP'),
  ];

  final members = <EventMember>[
    const EventMember(name: 'Alok Shaw [ You ]', email: 'sarah.shaw@forudyog.com', role: 'Admin / Owner', status: null),
    const EventMember(name: 'Alok Shaw', email: 'sarah.shaw@forudyog.com', role: 'Editor', status: null),
    const EventMember(name: 'Alok Shaw', email: 'sarah.shaw@forudyog.com', role: 'Editor', status: 'Pending'),
    const EventMember(name: 'Alok Shaw', email: 'sarah.shaw@forudyog.com', role: 'Viewer', status: null),
    const EventMember(name: 'Alok Shaw', email: 'sarah.shaw@forudyog.com', role: 'Viewer', status: null),
  ].obs;

  final sentInvites = <SentInvite>[
  ].obs;

  final roles = const <String>['Admin', 'Editor', 'Viewer'];

  @override
  void onInit() {
    super.onInit();
    args = ManageEventArgs.from(Get.arguments);
  }

  @override
  void onClose() {
    searchController.dispose();
    inviteEmailController.dispose();
    inviteMessageController.dispose();
    super.onClose();
  }

  void setSearch(String v) => searchQuery.value = v;

  void setInviteRole(String? v) {
    if (v == null) return;
    inviteRole.value = v;
  }

  String _inviteRoleFromMemberRole(String memberRole) {
    final v = memberRole.toLowerCase();
    if (v.contains('admin')) return 'Admin';
    if (v.contains('editor')) return 'Editor';
    if (v.contains('viewer')) return 'Viewer';
    return 'Editor';
  }

  String _memberRoleFromInviteRole(String inviteRole) {
    if (inviteRole == 'Admin') return 'Admin / Owner';
    return inviteRole;
  }

  Future<void> sendInvite() async {
    if (isInviting.value) return;
    final email = inviteEmailController.text.trim();
    if (email.isEmpty) {
      // Get.snackbar('Invite', 'Please enter email');
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
      inviteMessageController.clear();
      Get.snackbar('Invite', 'Invite sent');
    } finally {
      isInviting.value = false;
    }
  }

  void removeInvite(SentInvite invite) => sentInvites.remove(invite);

  Future<void> resendInviteForMember(EventMember member) async {
    // Reuse the same invite flow (email + role) for a member.
    inviteEmailController.text = member.email;
    inviteRole.value = _inviteRoleFromMemberRole(member.role);
    inviteMessageController.clear();
    await sendInvite();
  }

  void updateMemberRole(int index, String inviteRole) {
    if (index < 0 || index >= members.length) return;
    final existing = members[index];
    final nextRole = _memberRoleFromInviteRole(inviteRole);
    members[index] = EventMember(
      name: existing.name,
      email: existing.email,
      role: nextRole,
      status: existing.status,
    );
  }

  void deleteMember(int index) {
    if (index < 0 || index >= members.length) return;
    members.removeAt(index);
  }
}

class ManageEventArgs {
  const ManageEventArgs({
    required this.title,
    required this.location,
    required this.membersCount,
    required this.cardsCount,
  });

  final String title;
  final String location;
  final int membersCount;
  final int cardsCount;

  static ManageEventArgs from(dynamic args) {
    final map = (args as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return ManageEventArgs(
      title: (map['title'] as String?) ?? 'Event',
      location: (map['location'] as String?) ?? 'Greater Noida, India',
      membersCount: (map['membersCount'] as int?) ?? 12,
      cardsCount: (map['cardsCount'] as int?) ?? 143,
    );
  }
}

class EventPerson {
  const EventPerson({required this.name, required this.email, required this.companyOrRole});

  final String name;
  final String email;
  final String companyOrRole;
}

class EventMember {
  const EventMember({required this.name, required this.email, required this.role, required this.status});

  final String name;
  final String email;
  final String role;
  final String? status;
}

class SentInvite {
  const SentInvite({required this.email, required this.role, required this.status});

  final String email;
  final String role;
  final String status;
}

