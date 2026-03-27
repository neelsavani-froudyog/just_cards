import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../events/manage/manage_event_controller.dart'
    show EventPerson, SentInvite;
import 'organization_events_model.dart';
import 'organization_members_model.dart';

class OrganizationDetailArgs {
  const OrganizationDetailArgs({
    required this.organizationId,
    required this.name,
    required this.role,
    this.industry,
    this.isActive = true,
    this.initialTab = 0,
  });

  final String organizationId;
  final String name;
  final String role;
  final String? industry;
  final bool isActive;
  final int initialTab;

  factory OrganizationDetailArgs.from(dynamic arguments) {
    final map = (arguments as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final dynamic tabRaw = map['initialTab'];
    final tab = tabRaw is int
        ? tabRaw
        : int.tryParse(tabRaw?.toString() ?? '') ?? 0;
    return OrganizationDetailArgs(
      organizationId: map['organizationId']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Organization',
      role: map['role']?.toString() ?? '',
      industry: map['industry']?.toString(),
      isActive: map['isActive'] == true,
      initialTab: tab.clamp(0, 2),
    );
  }
}

class OrganizationDetailController extends GetxController {
  late final OrganizationDetailArgs args;

  late final ApiService _apiService;

  final searchController = TextEditingController();
  final searchQuery = ''.obs;
  final selectedTabIndex = 0.obs;
  final currentUserRole = ''.obs;

  final eventsExpanded = false.obs;

  final inviteEmailController = TextEditingController();
  final inviteMessageController = TextEditingController();
  final inviteRole = 'Editor'.obs;
  final isInviting = false.obs;

  final orgEvents = <OrganizationEvent>[].obs;
  final isEventsLoading = false.obs;
  final eventsErrorText = RxnString();

  final contacts = <EventPerson>[
    const EventPerson(
      name: 'Alok Shaw',
      email: 'sarah.shaw@forudyog.com',
      companyOrRole: 'Ombyte Systems LLP',
    ),
    const EventPerson(
      name: 'Alok Shaw',
      email: 'sarah.shaw@forudyog.com',
      companyOrRole: 'Ombyte Systems LLP',
    ),
    const EventPerson(
      name: 'Alok Shaw',
      email: 'sarah.shaw@forudyog.com',
      companyOrRole: 'Ombyte Systems LLP',
    ),
  ];

  final members = <OrganizationMemberItem>[].obs;
  final isMembersLoading = false.obs;
  final membersErrorText = RxnString();

  // Invite list is dynamic: items are added/removed by the user.
  final sentInvites = <SentInvite>[].obs;

  final roles = const <String>['Admin', 'Editor', 'Viewer'];

  int get membersCount => members.length;
  int get pendingInvitesCount =>
      sentInvites.where((i) => i.status.toLowerCase() != 'accepted').length;
  int get eventsCount => orgEvents.length;

  @override
  void onInit() {
    super.onInit();
    args = OrganizationDetailArgs.from(Get.arguments);
    currentUserRole.value = args.role.trim().toLowerCase();
    selectedTabIndex.value = args.initialTab;
    _apiService = Get.find<ApiService>();
    fetchMembers();
    fetchOrganizationEvents();
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

  void toggleEventsExpanded() =>
      eventsExpanded.value = !eventsExpanded.value;

  void setInviteRole(String? v) {
    if (v == null) return;
    inviteRole.value = v;
  }

  Future<void> fetchMembers() async {
    final orgId = args.organizationId.trim();
    if (orgId.isEmpty || isMembersLoading.value) return;

    isMembersLoading.value = true;
    membersErrorText.value = null;
    try {
      await _apiService.getRequest(
        url: ApiUrl.profileOrganizationsMembers,
        queryParameters: <String, dynamic>{'id': orgId},
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) {
            membersErrorText.value = 'Invalid members response';
            return;
          }

          final parsed = OrganizationMembersResponse.fromJson(raw);
          if (!parsed.ok) {
            membersErrorText.value =
                parsed.message.isNotEmpty ? parsed.message : 'Failed to load members';
            return;
          }

          members.assignAll(parsed.data);
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

  Future<void> fetchOrganizationEvents() async {
    final orgId = args.organizationId.trim();
    if (orgId.isEmpty || isEventsLoading.value) return;

    isEventsLoading.value = true;
    eventsErrorText.value = null;
    try {
      await _apiService.getRequest(
        url: ApiUrl.eventsOrganization,
        queryParameters: <String, dynamic>{'organizationId': orgId},
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) {
            eventsErrorText.value = 'Invalid events response';
            orgEvents.clear();
            return;
          }

          final parsed = OrganizationEventsResponse.fromJson(raw);
          if (!parsed.ok) {
            eventsErrorText.value =
                parsed.message.isNotEmpty ? parsed.message : 'Failed to load events';
            orgEvents.clear();
            return;
          }

          orgEvents.assignAll(parsed.data);
        },
        onError: (message) {
          eventsErrorText.value =
              (message?.isNotEmpty ?? false) ? message! : 'Failed to load events';
          orgEvents.clear();
        },
      );
    } finally {
      isEventsLoading.value = false;
    }
  }

  String _apiRoleFromBackendRole(String backendRole) {
    final v = backendRole.toLowerCase();
    if (v.contains('admin') || v.contains('owner')) return 'admin';
    if (v.contains('editor')) return 'editor';
    return 'viewer';
  }

  Future<void> resendInviteForMember(OrganizationMemberItem member) async {
    if (isInviting.value) return;

    final orgId = args.organizationId.trim();
    if (orgId.isEmpty) {
      Get.snackbar('Invite', 'Organization ID is missing');
      return;
    }

    isInviting.value = true;
    try {
      await _apiService.postRequest(
        url: ApiUrl.organizationsInvites,
        data: <String, dynamic>{
          'organization_id': orgId,
          'note': 'Resent invite',
          'users': <Map<String, dynamic>>[
            <String, dynamic>{
              'email': member.email,
              'role': _apiRoleFromBackendRole(member.role),
              'invited_user_id': member.userId.isNotEmpty ? member.userId : null,
            },
          ],
        },
        showSuccessToast: true,
        successToastMessage: 'Invite resent',
        showErrorToast: true,
        onSuccess: (_) => fetchMembers(),
        onError: (_) {},
      );
    } finally {
      isInviting.value = false;
    }
  }

  Future<void> removeInviteForMember(OrganizationMemberItem member) async {
    if (isInviting.value) return;

    final inviteId = member.inviteId?.toString().trim();
    if (inviteId == null || inviteId.isEmpty) {
      Get.snackbar('Remove', 'Invite ID is missing');
      return;
    }

    isInviting.value = true;
    try {
      await _apiService.deleteRequest(
        url: ApiUrl.organizationsInvitesMember,
        queryParameters: <String, dynamic>{'id': inviteId},
        data: null,
        showSuccessToast: true,
        successToastMessage: 'Invite removed',
        showErrorToast: true,
        onSuccess: (_) => fetchMembers(),
        onError: (_) {},
      );
    } finally {
      isInviting.value = false;
    }
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
    } finally {
      isInviting.value = false;
    }
  }

  Future<void> sendInvites() async {
    if (isInviting.value) return;
    if (sentInvites.isEmpty) {
      Get.snackbar('Invite', 'Add at least one member');
      return;
    }

    final orgId = args.organizationId.trim();
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
          // Keep the user on the Organization Detail page, but clear the form.
          inviteMessageController.clear();
          sentInvites.clear();
        },
        onError: (_) {},
      );
    } finally {
      isInviting.value = false;
    }
  }

  void removeInvite(SentInvite invite) => sentInvites.remove(invite);

  bool get canManageOrganization {
    final role = currentUserRole.value;
    return role != 'editor' && role != 'viewer';
  }

  List<EventPerson> get filteredContacts {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return contacts;
    return contacts
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.email.toLowerCase().contains(q) ||
              p.companyOrRole.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> updateMemberRole(int index, String selected) async {
    if (index < 0 || index >= members.length) return;

    final member = members[index];
    final inviteId = member.inviteId?.toString().trim();
    if (inviteId == null || inviteId.isEmpty) {
      Get.snackbar('Update', 'Invite ID is missing');
      return;
    }

    final v = selected.toLowerCase().trim();
    final apiRole = v.contains('admin')
        ? 'admin'
        : v.contains('editor')
            ? 'editor'
            : 'viewer';

    await _apiService.patchRequest(
      url: ApiUrl.organizationsInvitesRole,
      queryParameters: <String, dynamic>{'id': inviteId},
      data: <String, dynamic>{
        'role': apiRole,
      },
      showSuccessToast: true,
      successToastMessage: 'Role updated',
      showErrorToast: true,
      onSuccess: (_) => fetchMembers(),
      onError: (_) {},
    );
  }

  Future<void> deleteMember(int index) async {
    if (index < 0 || index >= members.length) return;
    final member = members[index];
    if (member.inviteId == null || member.inviteId!.toString().trim().isEmpty) {
      Get.snackbar('Remove', 'Invite ID is missing');
      return;
    }
    await removeInviteForMember(member);
  }
}
