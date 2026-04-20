import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/create_contact_service.dart';
import '../../../core/services/toast_service.dart';
import '../../home/home_controller.dart';
import 'event_members_model.dart';
import 'event_contacts_model.dart';

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

  // Contacts tab
  final contacts = <EventContactItem>[].obs;
  final isContactsLoading = false.obs;
  final contactsErrorText = RxnString();
  final contactsTotal = 0.obs;
  final contactsLimit = 10.obs;
  final contactsOffset = 0.obs;

  // Cards count (total contacts in this event)
  final eventCardsTotalCount = RxnInt();
  final isEventCardsTotalLoading = false.obs;

  Timer? _contactsSearchDebounce;

  final members = <EventMember>[
  ].obs;
  final isMembersLoading = false.obs;
  final membersErrorText = RxnString();

  final sentInvites = <SentInvite>[
  ].obs;

  final roles = const <String>['Admin', 'Editor', 'Viewer'];

  final eventTitle = ''.obs;
  final eventLocation = ''.obs;
  final eventDateIso = ''.obs;
  final eventNotes = ''.obs;
  final eventOrganizationId = RxnString();

  final isDeletingEvent = false.obs;

  /// From `GET /profile/me` (`data.user_id`), for creator check.
  final currentUserId = RxnString();

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    args = ManageEventArgs.from(Get.arguments);
    currentUserRole.value = args.role.trim().toLowerCase();
    eventTitle.value = args.title;
    eventLocation.value = args.location;
    eventDateIso.value = args.eventDateIso;
    eventNotes.value = args.notes;
    eventOrganizationId.value = args.organizationId;
    _loadCurrentUserId();
    fetchContacts(reset: true);
    fetchEventCardsTotalCount();
    fetchMembers();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final id = await Get.find<CreateContactService>().fetchProfileUserId();
      currentUserId.value = id;
    } catch (_) {
      currentUserId.value = null;
    }
  }

  /// Edit / delete menu: only when event creator matches logged-in user.
  bool get canShowEventOwnerActions {
    final creator = args.createdBy.trim();
    final me = currentUserId.value?.trim() ?? '';
    if (creator.isEmpty || me.isEmpty) return false;
    return creator == me;
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
  }

  String _apiRoleFromUiRole(String uiRole) {
    final v = uiRole.toLowerCase();
    if (v.contains('admin') || v.contains('owner')) return 'admin';
    if (v.contains('editor')) return 'editor';
    if (v.contains('viewer')) return 'viewer';
    return v;
  }

  Future<void> fetchContacts({required bool reset}) async {
    final eventId = args.eventId.trim();
    if (eventId.isEmpty || isContactsLoading.value) return;

    if (reset) {
      contactsOffset.value = 0;
      contacts.clear();
    }

    isContactsLoading.value = true;
    contactsErrorText.value = null;
    try {
      await _apiService.postRequest(
        url: ApiUrl.contactsByEvent,
        data: <String, dynamic>{
          'p_event_id': eventId,
          'p_limit': contactsLimit.value,
          'p_offset': contactsOffset.value,
          'p_search': searchQuery.value.trim().isEmpty ? null : searchQuery.value.trim(),
        },
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) {
            contactsErrorText.value = 'Invalid contacts response';
            return;
          }
          final parsed = EventContactsResponse.fromJson(raw);
          if (!parsed.ok) {
            contactsErrorText.value = parsed.message.isNotEmpty
                ? parsed.message
                : 'Failed to load contacts';
            return;
          }

          contacts.assignAll(parsed.data);
          contactsTotal.value = parsed.total;
          contactsLimit.value = parsed.limit == 0 ? contactsLimit.value : parsed.limit;
          contactsOffset.value = parsed.offset;
        },
        onError: (message) {
          contactsErrorText.value =
              (message.isNotEmpty) ? message : 'Failed to load contacts';
        },
      );
    } finally {
      isContactsLoading.value = false;
      // Keep header Cards count in sync with server totals.
      fetchEventCardsTotalCount();
    }
  }

  Future<void> fetchEventCardsTotalCount() async {
    final eventId = args.eventId.trim();
    if (eventId.isEmpty || isEventCardsTotalLoading.value) return;

    isEventCardsTotalLoading.value = true;
    try {
      await _apiService.postRequest(
        url: ApiUrl.contactsByEventTotalCount,
        data: <String, dynamic>{'p_event_id': eventId},
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) {
            eventCardsTotalCount.value = null;
            return;
          }
          if (raw['ok'] != true) {
            eventCardsTotalCount.value = null;
            return;
          }
          final data = raw['data'];
          final total =
              (data is Map<String, dynamic>) ? data['total'] : raw['total'];
          if (total is num) {
            eventCardsTotalCount.value = total.toInt();
          } else {
            eventCardsTotalCount.value = int.tryParse(total?.toString() ?? '');
          }
        },
        onError: (_) {
          eventCardsTotalCount.value = null;
        },
      );
    } finally {
      isEventCardsTotalLoading.value = false;
    }
  }

  Future<void> _sendInvitesRequest(List<SentInvite> invites) async {
    if (isInviting.value) return;
    if (invites.isEmpty) {
      ToastService.info('Add members to the invite list first');
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

  Future<void> recallInviteForMember(EventMember member) async {
    if (isInviting.value) return;

    final batchId = member.inviteBatchId?.trim() ?? '';
    if (batchId.isEmpty) {
      ToastService.error('Invite batch ID is missing');
      return;
    }

    isInviting.value = true;
    try {
      await _apiService.postRequest(
        url: ApiUrl.eventInvitesNotify,
        data: <String, dynamic>{'invite_batch_id': batchId},
        showSuccessToast: true,
        successToastMessage: 'Invite recalled',
        showErrorToast: true,
        onSuccess: (_) => fetchMembers(),
        onError: (_) {},
      );
    } finally {
      isInviting.value = false;
    }
  }

  void updateMemberRole(int index, String inviteRole) {
    if (index < 0 || index >= members.length) return;
    final existing = members[index];
    final nextRole = _memberRoleFromInviteRole(inviteRole);
    members[index] = EventMember(
      id: existing.id,
      name: existing.name,
      email: existing.email,
      avatarUrl: existing.avatarUrl,
      role: nextRole,
      status: existing.status,
      inviteId: existing.inviteId,
      inviteBatchId: existing.inviteBatchId,
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
                    id: m.id,
                    name: m.fullName.isNotEmpty ? m.fullName : 'Unknown',
                    email: m.email,
                    avatarUrl: m.avatarUrl?.trim(),
                    role: _normalizeRole(m.role),
                    status: m.status,
                    inviteId: m.inviteId?.trim().isEmpty == true
                        ? null
                        : m.inviteId?.trim(),
                    inviteBatchId: m.inviteBatchId?.trim().isEmpty == true
                        ? null
                        : m.inviteBatchId?.trim(),
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

  bool get canManageEvent {
    final role = currentUserRole.value;
    return role != 'editor' && role != 'viewer' && role != 'admin';
  }

  void applyEventEditResult(dynamic result) {
    if (result is! Map) return;
    final t = result['title']?.toString().trim();
    if (t != null && t.isNotEmpty) eventTitle.value = t;
    final loc = result['location']?.toString().trim();
    if (loc != null && loc.isNotEmpty) eventLocation.value = loc;
    final d = result['eventDate']?.toString().trim();
    if (d != null && d.isNotEmpty) eventDateIso.value = d;
    if (result.containsKey('notes')) {
      eventNotes.value = result['notes']?.toString() ?? '';
    }
    if (result.containsKey('organizationId')) {
      final o = result['organizationId']?.toString().trim();
      eventOrganizationId.value =
          (o == null || o.isEmpty) ? null : o;
    }
  }

  Future<void> deleteEvent() async {
    if (isDeletingEvent.value) return;
    final eventId = args.eventId.trim();
    if (eventId.isEmpty) return;

    isDeletingEvent.value = true;
    var deleted = false;
    try {
      await _apiService.deleteRequest(
        url: ApiUrl.events,
        data: <String, dynamic>{'p_event_id': eventId},
        showSuccessToast: true,
        successToastMessage: 'Event deleted',
        showErrorToast: true,
        onSuccess: (_) => deleted = true,
        onError: (_) {},
      );
      if (deleted) {
        if (Get.isRegistered<HomeController>()) {
          await Get.find<HomeController>().refreshAllData();
        }
        Get.back(result: 'event_deleted');
      }
    } finally {
      isDeletingEvent.value = false;
    }
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
    this.eventDateIso = '',
    this.notes = '',
    this.organizationId,
    this.createdBy = '',
  });

  final String eventId;
  final String title;
  final String location;
  final int membersCount;
  final int cardsCount;
  final String role;
  final String eventDateIso;
  final String notes;
  final String? organizationId;
  final String createdBy;

  static ManageEventArgs from(dynamic args) {
    final map = (args as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return ManageEventArgs(
      eventId: (map['eventId'] ?? '').toString(),
      title: (map['title'] as String?) ?? 'Event',
      location: (map['location'] as String?) ?? 'Greater Noida, India',
      membersCount: (map['membersCount'] as int?) ?? 12,
      cardsCount: (map['cardsCount'] as int?) ?? 143,
      role: (map['role'] ?? '').toString(),
      eventDateIso:
          (map['eventDate'] ?? map['event_date'] ?? '').toString(),
      notes: (map['notes'] ?? '').toString(),
      organizationId: map['organizationId']?.toString() ??
          map['organization_id']?.toString(),
      createdBy: (map['createdBy'] ?? map['created_by'] ?? '').toString(),
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
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.status,
    this.inviteId,
    this.inviteBatchId,
    this.joinedAt,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String role;
  final String? status;
  final String? inviteId;
  final String? inviteBatchId;
  final String? joinedAt;
}

class SentInvite {
  const SentInvite({required this.email, required this.role, required this.status});

  final String email;
  final String role;
  final String status;
}

