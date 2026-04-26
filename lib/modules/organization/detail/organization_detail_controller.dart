import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_session_service.dart';
import '../../../core/services/http_sender_io.dart';
import '../../../core/utils/contacts_csv_export.dart';
import '../../../routes/app_routes.dart';
import '../../events/manage/manage_event_controller.dart' show SentInvite;
import '../../../core/services/toast_service.dart';
import 'organization_events_model.dart';
import 'organization_contacts_model.dart';
import 'organization_members_model.dart';
import '../manage/manage_organization_controller.dart';

class OrganizationDetailArgs {
  const OrganizationDetailArgs({
    required this.organizationId,
    required this.name,
    required this.role,
    this.type = '',
    this.industry,
    this.isActive = true,
    this.initialTab = 0,
  });

  final String organizationId;
  final String name;
  final String role;
  final String type;
  final String? industry;
  final bool isActive;
  final int initialTab;

  factory OrganizationDetailArgs.from(dynamic arguments) {
    final map =
        (arguments as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final dynamic tabRaw = map['initialTab'];
    final tab =
        tabRaw is int ? tabRaw : int.tryParse(tabRaw?.toString() ?? '') ?? 0;
    return OrganizationDetailArgs(
      organizationId:
          (map['organizationId'] ?? map['organization_id'] ?? '').toString(),
      name: map['name']?.toString() ?? 'Organization',
      role: (map['role'] ?? map['member_role'] ?? '').toString(),
      type: (map['type'] ?? map['organization_type'] ?? '').toString(),
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

  /// Updated when returning from [Routes.editOrganization].
  final organizationDisplayName = ''.obs;
  final isDeletingOrganization = false.obs;

  final eventsExpanded = false.obs;

  final inviteEmailController = TextEditingController();
  final inviteMessageController = TextEditingController();
  final inviteRole = 'Editor'.obs;
  final isInviting = false.obs;

  final orgEvents = <OrganizationEvent>[].obs;
  final isEventsLoading = false.obs;
  final eventsErrorText = RxnString();

  // Contacts tab
  final contacts = <OrganizationContactItem>[].obs;
  final isContactsLoading = false.obs;
  final contactsErrorText = RxnString();
  final contactsTotal = 0.obs;
  final contactsLimit = 10.obs;
  final contactsOffset = 0.obs;
  final isExportingContacts = false.obs;
  Timer? _contactsSearchDebounce;

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
    organizationDisplayName.value =
        args.name.trim().isEmpty ? 'Organization' : args.name.trim();
    _apiService = Get.find<ApiService>();
    fetchMembers();
    fetchOrganizationEvents();
    fetchContacts(reset: true);
  }

  @override
  void onClose() {
    searchController.dispose();
    inviteEmailController.dispose();
    inviteMessageController.dispose();
    _contactsSearchDebounce?.cancel();
    super.onClose();
  }

  void setSearch(String v) {
    searchQuery.value = v;
    _contactsSearchDebounce?.cancel();
    _contactsSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      fetchContacts(reset: true);
    });
  }

  /// Called when the tab changes in the UI.
  /// Keeps `selectedTabIndex` in sync and refreshes the corresponding data.
  void setSelectedTab(int index) {
    selectedTabIndex.value = index;

    // 0 = Contacts, 1 = Members, 2 = Invites (if present)
    if (index == 0) {
      // Always reload contacts when user comes back to this tab
      fetchContacts(reset: true);
    } else if (index == 1) {
      // Refresh members list when switching to Members tab
      fetchMembers();
    }
    // For the Invites tab (index 2) we currently work with local state
    // (`sentInvites`) and dedicated send/remove methods, so no extra fetch.
  }

  void applyOrganizationEditResult(dynamic result) {
    if (result is! Map) return;
    final name = result['name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      organizationDisplayName.value = name;
    }
  }

  Future<void> deleteOrganization() async {
    if (isDeletingOrganization.value) return;
    isDeletingOrganization.value = true;
    try {
      await _apiService.deleteRequest(
        url: ApiUrl.profileDeleteOrganization,
        data: <String, dynamic>{'p_org_id': args.organizationId},
        showSuccessToast: true,
        successToastMessage: 'Organization deleted',
        showErrorToast: true,
        onSuccess: (_) {
          if (Get.isRegistered<ManageOrganizationController>()) {
            Get.find<ManageOrganizationController>().fetchOrganizations();
          }
          Get.back(result: 'org_deleted');
        },
        onError: (_) {},
      );
    } finally {
      isDeletingOrganization.value = false;
    }
  }

  Future<void> fetchContacts({required bool reset}) async {
    final orgId = args.organizationId.trim();
    if (orgId.isEmpty || isContactsLoading.value) return;

    if (reset) {
      contactsOffset.value = 0;
      contacts.clear();
    }

    isContactsLoading.value = true;
    contactsErrorText.value = null;
    try {
      await _apiService.postRequest(
        url: ApiUrl.contactsByOrganization,
        data: <String, dynamic>{
          'p_organization_id': orgId,
          'p_limit': contactsLimit.value,
          'p_offset': contactsOffset.value,
          'p_search':
              searchQuery.value.trim().isEmpty
                  ? null
                  : searchQuery.value.trim(),
        },
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) {
            contactsErrorText.value = 'Invalid contacts response';
            return;
          }
          final parsed = OrganizationContactsResponse.fromJson(raw);
          if (!parsed.ok) {
            contactsErrorText.value =
                parsed.message.isNotEmpty
                    ? parsed.message
                    : 'Failed to load contacts';
            return;
          }

          contacts.assignAll(parsed.data);
          contactsTotal.value = parsed.total;
          contactsLimit.value =
              parsed.limit == 0 ? contactsLimit.value : parsed.limit;
          contactsOffset.value = parsed.offset;
        },
        onError: (message) {
          contactsErrorText.value =
              message.isNotEmpty ? message : 'Failed to load contacts';
        },
      );
    } finally {
      isContactsLoading.value = false;
    }
  }

  /// Exports org contacts: `POST /contacts/by-organization/export`, then
  /// falls back to `POST /contacts/by-organization` + client CSV (same as event flow).
  Future<void> exportOrganizationContactsCsv() async {
    if (isExportingContacts.value) return;
    final orgId = args.organizationId.trim();
    if (orgId.isEmpty) {
      ToastService.error('Organization id is missing');
      return;
    }

    isExportingContacts.value = true;
    try {
      final session = Get.find<AuthSessionService>();
      final token = session.accessToken.value.trim();
      if (token.isEmpty) {
        ToastService.error('Not signed in');
        return;
      }

      final orgNameForFile =
          organizationDisplayName.value.trim().isNotEmpty
              ? organizationDisplayName.value
              : args.name;
      final orgStem = sanitizeCsvExportStem(
        orgNameForFile,
        fallback: 'organization',
      );
      final defaultFileName = '${orgStem}_contacts.xlsx';

      ParsedContactsExport parsed = const ParsedContactsExport(
        errorMessage: 'Export failed',
      );
      try {
        final base = ApiUrl.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
        final uri = Uri.parse('$base${ApiUrl.contactsByOrganizationExport}');

        final response = await sendHttpRequest(
          method: 'POST',
          uri: uri,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=utf-8',
            'Accept':
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/json, text/csv, */*',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(<String, String>{'p_organization_id': orgId}),
        );

        if (response.statusCode == 401) {
          session.clear();
          Get.offAllNamed(Routes.login);
          return;
        }

        parsed = parseContactsExportHttpResponse(
          statusCode: response.statusCode,
          bodyText: response.bodyText,
          headers: response.headers,
        );
      } catch (_) {
        parsed = const ParsedContactsExport(
          errorMessage: 'Export request failed',
        );
      }

      if (parsed.isSuccess) {
        final rows = await _fetchAllOrganizationContactsForExport();
        if (rows == null) {
          ToastService.error(
            parsed.errorMessage ?? 'Could not export contacts',
          );
          return;
        }
        if (rows.isEmpty) {
          ToastService.info('No contacts to export');
          return;
        }
        await saveContactsXlsxToDevice(
          bytes: buildOrganizationContactsXlsxBytes(rows),
          fileName: defaultFileName,
        );
        return;
      }

      final rows = await _fetchAllOrganizationContactsForExport();
      if (rows == null) {
        ToastService.error(parsed.errorMessage ?? 'Could not export contacts');
        return;
      }
      if (rows.isEmpty) {
        ToastService.info('No contacts to export');
        return;
      }
      await saveContactsXlsxToDevice(
        bytes: buildOrganizationContactsXlsxBytes(rows),
        fileName: defaultFileName,
      );
    } catch (_) {
      ToastService.error('Could not export contacts');
    } finally {
      isExportingContacts.value = false;
    }
  }

  Future<List<OrganizationContactItem>?>
  _fetchAllOrganizationContactsForExport() async {
    final orgId = args.organizationId.trim();
    if (orgId.isEmpty) return null;

    List<OrganizationContactItem>? rows;
    await _apiService.postRequest(
      url: ApiUrl.contactsByOrganization,
      data: <String, dynamic>{
        'p_organization_id': orgId,
        'p_limit': 10000,
        'p_offset': 0,
        'p_search':
            searchQuery.value.trim().isEmpty ? null : searchQuery.value.trim(),
      },
      showSuccessToast: false,
      showErrorToast: false,
      onSuccess: (payload) {
        final raw = payload['response'];
        if (raw is! Map<String, dynamic>) {
          rows = null;
          return;
        }
        final p = OrganizationContactsResponse.fromJson(raw);
        rows = p.ok ? p.data : null;
      },
      onError: (_) {
        rows = null;
      },
    );
    return rows;
  }

  void toggleEventsExpanded() => eventsExpanded.value = !eventsExpanded.value;

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
                parsed.message.isNotEmpty
                    ? parsed.message
                    : 'Failed to load members';
            return;
          }

          members.assignAll(parsed.data);
        },
        onError: (message) {
          membersErrorText.value =
              (message?.isNotEmpty ?? false)
                  ? message!
                  : 'Failed to load members';
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
                parsed.message.isNotEmpty
                    ? parsed.message
                    : 'Failed to load events';
            orgEvents.clear();
            return;
          }

          orgEvents.assignAll(parsed.data);
        },
        onError: (message) {
          eventsErrorText.value =
              (message?.isNotEmpty ?? false)
                  ? message!
                  : 'Failed to load events';
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
      ToastService.error('Organization ID is missing');
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
              'invited_user_id':
                  member.userId.isNotEmpty ? member.userId : null,
            },
          ],
        },
        showSuccessToast: true,
        successToastMessage: 'Invite resent',
        // We'll handle error toast manually to customize specific messages.
        showErrorToast: false,
        onSuccess: (_) => fetchMembers(),
        onError: (message) async {
          const duplicateMsg =
              'Invite creation did not return an invite_batch_id.';
          if (message.trim() == duplicateMsg) {
            await ToastService.error('Member already invited');
          } else if (message.isNotEmpty) {
            await ToastService.error(message);
          }
        },
      );
    } finally {
      isInviting.value = false;
    }
  }

  Future<void> removeInviteForMember(OrganizationMemberItem member) async {
    if (isInviting.value) return;

    final inviteId = member.inviteId?.toString().trim();
    if (inviteId == null || inviteId.isEmpty) {
      ToastService.error('Invite ID is missing');
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
      ToastService.error('Please enter email');
      return;
    }

    final alreadyAdded = sentInvites.any(
      (i) => i.email.toLowerCase() == email.toLowerCase(),
    );
    if (alreadyAdded) {
      ToastService.error('This email is already added');
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
      ToastService.info('Add at least one member');
      return;
    }

    final orgId = args.organizationId.trim();
    if (orgId.isEmpty) {
      ToastService.error('Organization ID is missing');
      return;
    }

    isInviting.value = true;
    try {
      final users =
          sentInvites
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
          'note':
              inviteMessageController.text.isNotEmpty
                  ? inviteMessageController.text.trim()
                  : null,
          'users': users,
        },
        showSuccessToast: true,
        successToastMessage: 'Invites sent successfully',
        // Custom error handling to map known backend messages.
        showErrorToast: false,
        onSuccess: (_) {
          // Keep the user on the Organization Detail page, but clear the form.
          inviteMessageController.clear();
          sentInvites.clear();
        },
        onError: (message) async {
          const duplicateMsg =
              'Invite creation did not return an invite_batch_id.';
          if (message.trim() == duplicateMsg) {
            await ToastService.error('Member already invited');
          } else if (message.isNotEmpty) {
            await ToastService.error(message);
          }
        },
      );
    } finally {
      isInviting.value = false;
    }
  }

  void removeInvite(SentInvite invite) => sentInvites.remove(invite);

  bool get canManageOrganization {
    final role = currentUserRole.value;
    return role != 'editor' && role != 'viewer' && role != 'admin';
  }

  bool get canShowDownloadContactsAction {
    final type = args.type.trim().toLowerCase();
    final memberRole = args.role.trim().toLowerCase();
    print('type: $type, memberRole: $memberRole');

    if (type == 'owner') return true;
    if (type == 'member') {
      return memberRole == 'owner' || memberRole == 'admin';
    }
    return false;
  }

  // Contacts are fetched server-side with `p_search`.

  Future<void> updateMemberRole(int index, String selected) async {
    if (index < 0 || index >= members.length) return;

    final member = members[index];
    final inviteId = member.inviteId?.toString().trim();
    if (inviteId == null || inviteId.isEmpty) {
      ToastService.error('Invite ID is missing');
      return;
    }

    final v = selected.toLowerCase().trim();
    final apiRole =
        v.contains('admin')
            ? 'admin'
            : v.contains('editor')
            ? 'editor'
            : 'viewer';

    await _apiService.patchRequest(
      url: ApiUrl.organizationsInvitesRole,
      queryParameters: <String, dynamic>{'id': inviteId},
      data: <String, dynamic>{'role': apiRole},
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
      ToastService.error('Invite ID is missing');
      return;
    }
    await removeInviteForMember(member);
  }
}
