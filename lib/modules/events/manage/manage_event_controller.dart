import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import 'event_members_model.dart';

class ManageEventController extends GetxController {
  late final ManageEventArgs args;
  late final ApiService _apiService;

  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final selectedTabIndex = 0.obs;
  final currentUserRole = ''.obs;

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
  ].obs;
  final isMembersLoading = false.obs;
  final membersErrorText = RxnString();

  final sentInvites = <SentInvite>[
  ].obs;

  final roles = const <String>['Admin', 'Editor', 'Viewer'];

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    args = ManageEventArgs.from(Get.arguments);
    currentUserRole.value = args.role.trim().toLowerCase();
    fetchMembers();
  }

  @override
  void onClose() {
    searchController.dispose();
    inviteEmailController.dispose();
    inviteMessageController.dispose();
    super.onClose();
  }

  void setSearch(String v) => searchQuery.value = v;
  void setSelectedTab(int index) => selectedTabIndex.value = index;

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

  void addInviteToLocalList() {
    final email = inviteEmailController.text.trim();
    if (email.isEmpty) return;

    // Keep message as a shared note for the whole batch (same payload for all users).
    sentInvites.insert(
      0,
      SentInvite(
        email: email,
        role: inviteRole.value,
        status: 'Pending',
      ),
    );
    inviteEmailController.clear();
    Get.snackbar('Invite', 'Added to invite list');
  }

  String _apiRoleFromUiRole(String uiRole) {
    final v = uiRole.toLowerCase();
    if (v.contains('admin') || v.contains('owner')) return 'admin';
    if (v.contains('editor')) return 'editor';
    if (v.contains('viewer')) return 'viewer';
    return v;
  }

  Future<void> _sendInvitesRequest(List<SentInvite> invites) async {
    if (isInviting.value) return;
    if (invites.isEmpty) {
      Get.snackbar('Invite', 'Add members to the invite list first');
      return;
    }

    final eventId = args.eventId.trim();
    if (eventId.isEmpty) return;

    final note = inviteMessageController.text.trim();
    final users = invites
        .map(
          (i) => <String, dynamic>{
            'email': i.email.trim(),
            'role': _apiRoleFromUiRole(i.role),
          },
        )
        .toList();

    isInviting.value = true;
    try {
      var didSucceed = false;

      await _apiService.postRequest(
        url: ApiUrl.eventsInvites,
        data: <String, dynamic>{
          'event_id': eventId,
          'note': note.isNotEmpty ? note : null,
          'users': users,
        },
        showSuccessToast: true,
        successToastMessage: 'Invites sent',
        showErrorToast: true,
        onSuccess: (_) {
          didSucceed = true;
        },
        onError: (_) {},
      );

      if (didSucceed) {
        sentInvites.clear();
        inviteMessageController.clear();
      }
    } finally {
      isInviting.value = false;
    }
  }

  Future<void> sendInvites() => _sendInvitesRequest(sentInvites.toList());

  void removeInvite(SentInvite invite) => sentInvites.remove(invite);

  Future<void> resendInviteForMember(EventMember member) async {
    // Resend for a single user (do not touch the local batch list).
    if (isInviting.value) return;
    await _sendInvitesRequest(
      <SentInvite>[
        SentInvite(
          email: member.email,
          role: _inviteRoleFromMemberRole(member.role),
          status: 'Pending',
        ),
      ],
    );
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
      joinedAt: existing.joinedAt,
    );
  }

  void deleteMember(int index) {
    if (index < 0 || index >= members.length) return;
    members.removeAt(index);
  }

  Future<void> fetchMembers() async {
    final eventId = args.eventId.trim();
    if (eventId.isEmpty || isMembersLoading.value) return;
    isMembersLoading.value = true;
    membersErrorText.value = null;
    try {
      await _apiService.getRequest(
        url: ApiUrl.eventsMembers,
        queryParameters: <String, dynamic>{'id': eventId},
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) {
            membersErrorText.value = 'Invalid members response';
            return;
          }
          final parsed = EventMembersResponse.fromJson(raw);
          if (!parsed.ok) {
            membersErrorText.value =
                parsed.message.isNotEmpty ? parsed.message : 'Failed to load members';
            return;
          }
          members.assignAll(
            parsed.data
                .map(
                  (m) => EventMember(
                    name: m.fullName.isNotEmpty ? m.fullName : 'Unknown',
                    email: m.email,
                    role: _normalizeRole(m.role),
                    status: m.status,
                    joinedAt: m.joinedAt?.trim().isEmpty == true ? null : m.joinedAt,
                  ),
                )
                .toList(),
          );
        },
        onError: (message) {
          membersErrorText.value =
              (message?.isNotEmpty ?? false) ? message! : 'Failed to load members';
        },
      );
    } finally {
      isMembersLoading.value = false;
    }
  }

  String _normalizeRole(String role) {
    final value = role.trim().toLowerCase();
    switch (value) {
      case 'owner':
        return 'Admin / Owner';
      case 'admin':
        return 'Admin';
      case 'editor':
        return 'Editor';
      case 'viewer':
        return 'Viewer';
      default:
        return role;
    }
  }

  bool get canShowInvitesTab {
    final role = currentUserRole.value;
    return role != 'editor' && role != 'viewer';
  }
}

class ManageEventArgs {
  const ManageEventArgs({
    required this.eventId,
    required this.title,
    required this.location,
    required this.membersCount,
    required this.cardsCount,
    required this.role,
  });

  final String eventId;
  final String title;
  final String location;
  final int membersCount;
  final int cardsCount;
  final String role;

  static ManageEventArgs from(dynamic args) {
    final map = (args as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return ManageEventArgs(
      eventId: (map['eventId'] ?? '').toString(),
      title: (map['title'] as String?) ?? 'Event',
      location: (map['location'] as String?) ?? 'Greater Noida, India',
      membersCount: (map['membersCount'] as int?) ?? 12,
      cardsCount: (map['cardsCount'] as int?) ?? 143,
      role: (map['role'] ?? '').toString(),
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
  const EventMember({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  final String name;
  final String email;
  final String role;
  final String? status;
  final String? joinedAt;
}

class SentInvite {
  const SentInvite({required this.email, required this.role, required this.status});

  final String email;
  final String role;
  final String status;
}

