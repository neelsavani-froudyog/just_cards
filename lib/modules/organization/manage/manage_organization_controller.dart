import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ManageOrganizationController extends GetxController {
  late final ManageOrganizationArgs args;

  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final isEventsExpanded = true.obs;

  final inviteEmailController = TextEditingController();
  final inviteMessageController = TextEditingController();
  final inviteRole = 'Editor'.obs;
  final isInviting = false.obs;

  final events = const <OrganizationEvent>[
    OrganizationEvent(title: 'Electronica 2026', count: 36),
    OrganizationEvent(title: 'PlastIndia 2026', count: 68),
    OrganizationEvent(title: 'Aahar Expo', count: 12),
    OrganizationEvent(title: 'Smart Tech', count: 24),
  ];

  final contacts = const <OrganizationPerson>[
    OrganizationPerson(
      name: 'Alok Shaw',
      email: 'sarah.shaw@forudyog.com',
      companyOrRole: 'Ombyte Systems LLP',
    ),
    OrganizationPerson(
      name: 'Alok Shaw',
      email: 'sarah.shaw@forudyog.com',
      companyOrRole: 'Ombyte Systems LLP',
    ),
    OrganizationPerson(
      name: 'Alok Shaw',
      email: 'sarah.shaw@forudyog.com',
      companyOrRole: 'Ombyte Systems LLP',
    ),
  ];

  final members = <OrganizationMember>[
    const OrganizationMember(
      name: 'Alok Shaw [ You ]',
      email: 'sarah.shaw@forudyog.com',
      role: 'Admin / Owner',
      status: null,
    ),
    const OrganizationMember(
      name: 'Alok Shaw',
      email: 'sarah.shaw@forudyog.com',
      role: 'Editor',
      status: null,
    ),
    const OrganizationMember(
      name: 'Alok Shaw',
      email: 'sarah.shaw@forudyog.com',
      role: 'Editor',
      status: 'Pending',
    ),
    const OrganizationMember(
      name: 'Alok Shaw',
      email: 'sarah.shaw@forudyog.com',
      role: 'Viewer',
      status: null,
    ),
  ].obs;

  final sentInvites = <OrganizationInvitePill>[
    const OrganizationInvitePill(
      email: 'sarah.shaw@forudyog.com',
      role: 'Admin',
      status: 'Sent',
    ),
  ].obs;

  final roles = const <String>['Admin', 'Editor', 'Viewer'];

  @override
  void onInit() {
    super.onInit();
    args = ManageOrganizationArgs.from(Get.arguments);
  }

  @override
  void onClose() {
    searchController.dispose();
    inviteEmailController.dispose();
    inviteMessageController.dispose();
    super.onClose();
  }

  void setSearch(String value) => searchQuery.value = value;

  void toggleEventsExpanded() {
    isEventsExpanded.value = !isEventsExpanded.value;
  }

  void setInviteRole(String? value) {
    if (value == null) return;
    inviteRole.value = value;
  }

  Future<void> sendInvite() async {
    if (isInviting.value) return;
    final email = inviteEmailController.text.trim();
    if (email.isEmpty) return;

    isInviting.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      sentInvites.insert(
        0,
        OrganizationInvitePill(
          email: email,
          role: inviteRole.value,
          status: 'Sent',
        ),
      );
      inviteEmailController.clear();
      inviteMessageController.clear();
      Get.snackbar('Invite', 'Invite sent');
    } finally {
      isInviting.value = false;
    }
  }

  void removeInvite(OrganizationInvitePill invite) {
    sentInvites.remove(invite);
  }
}

class ManageOrganizationArgs {
  const ManageOrganizationArgs({
    required this.name,
    required this.membersCount,
    required this.pendingInvites,
    required this.eventsCount,
  });

  final String name;
  final int membersCount;
  final int pendingInvites;
  final int eventsCount;

  static ManageOrganizationArgs from(dynamic args) {
    final map =
        (args as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return ManageOrganizationArgs(
      name: (map['name'] as String?) ?? 'Galaxy Infotect Limited',
      membersCount: (map['membersCount'] as int?) ?? 12,
      pendingInvites: (map['pendingInvites'] as int?) ?? 3,
      eventsCount: (map['eventsCount'] as int?) ?? 7,
    );
  }
}

class OrganizationEvent {
  const OrganizationEvent({required this.title, required this.count});

  final String title;
  final int count;
}

class OrganizationPerson {
  const OrganizationPerson({
    required this.name,
    required this.email,
    required this.companyOrRole,
  });

  final String name;
  final String email;
  final String companyOrRole;
}

class OrganizationMember {
  const OrganizationMember({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  final String name;
  final String email;
  final String role;
  final String? status;
}

class OrganizationInvitePill {
  const OrganizationInvitePill({
    required this.email,
    required this.role,
    required this.status,
  });

  final String email;
  final String role;
  final String status;
}
