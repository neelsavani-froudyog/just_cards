import 'package:get/get.dart';

enum InviteStatus { pending, accepted, declined }

enum InviteFilter { all, pending, accepted, declined }

class OrganizationInvite {
  const OrganizationInvite({
    required this.id,
    required this.orgName,
    required this.role,
    required this.invitedBy,
    required this.timeAgo,
    required this.status,
  });

  final String id;
  final String orgName;
  final String role;
  final String invitedBy;
  final String timeAgo;
  final InviteStatus status;

  OrganizationInvite copyWith({InviteStatus? status}) {
    return OrganizationInvite(
      id: id,
      orgName: orgName,
      role: role,
      invitedBy: invitedBy,
      timeAgo: timeAgo,
      status: status ?? this.status,
    );
  }
}

class NotificationsController extends GetxController {
  final query = ''.obs;
  final filter = InviteFilter.all.obs;

  final invites = <OrganizationInvite>[
    const OrganizationInvite(
      id: '1',
      orgName: 'Electronica 2026',
      role: 'Editor',
      invitedBy: 'Alok Shaw',
      timeAgo: '2h ago',
      status: InviteStatus.pending,
    ),
    const OrganizationInvite(
      id: '2',
      orgName: 'Ombyte Systems LLP',
      role: 'Viewer',
      invitedBy: 'Sarah Shaw',
      timeAgo: 'Yesterday',
      status: InviteStatus.pending,
    ),
    const OrganizationInvite(
      id: '3',
      orgName: 'Startup Studio',
      role: 'Admin',
      invitedBy: 'Priya Shah',
      timeAgo: '3d ago',
      status: InviteStatus.accepted,
    ),
  ].obs;

  int countFor(InviteFilter f) {
    if (f == InviteFilter.all) return invites.length;
    return invites.where((i) => i.status.name == f.name).length;
  }

  List<OrganizationInvite> get filtered {
    final q = query.value.trim().toLowerCase();
    final f = filter.value;
    return invites.where((i) {
      final matchesQuery = q.isEmpty ||
          i.orgName.toLowerCase().contains(q) ||
          i.invitedBy.toLowerCase().contains(q) ||
          i.role.toLowerCase().contains(q);
      final matchesFilter =
          f == InviteFilter.all ? true : i.status.name == f.name;
      return matchesQuery && matchesFilter;
    }).toList(growable: false);
  }

  void setQuery(String v) => query.value = v;

  void setFilter(InviteFilter v) => filter.value = v;
}

