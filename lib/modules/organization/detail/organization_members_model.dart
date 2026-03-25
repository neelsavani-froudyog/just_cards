class OrganizationMembersResponse {
  final bool ok;
  final String message;
  final List<OrganizationMemberItem> data;

  const OrganizationMembersResponse({
    required this.ok,
    required this.message,
    required this.data,
  });

  factory OrganizationMembersResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final items = <OrganizationMemberItem>[];
    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map<String, dynamic>) {
          items.add(OrganizationMemberItem.fromJson(item));
        }
      }
    }
    return OrganizationMembersResponse(
      ok: json['ok'] == true,
      message: (json['message'] ?? '').toString(),
      data: items,
    );
  }
}

class OrganizationMemberItem {
  final String role;
  final String email;
  final String source;
  final String status;
  final String? inviteId;
  final String userId;
  final String fullName;
  final String? joinedAt;
  final String? invitedAt;

  const OrganizationMemberItem({
    required this.role,
    required this.email,
    required this.source,
    required this.status,
    required this.inviteId,
    required this.userId,
    required this.fullName,
    required this.joinedAt,
    required this.invitedAt,
  });

  factory OrganizationMemberItem.fromJson(Map<String, dynamic> json) {
    final email = (json['email'] ?? '').toString();
    final fullNameRaw = (json['full_name'] ?? '').toString();
    return OrganizationMemberItem(
      role: (json['role'] ?? '').toString(),
      email: email,
      source: (json['source'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      inviteId: json['invite_id']?.toString(),
      userId: (json['user_id'] ?? '').toString(),
      fullName: fullNameRaw.isNotEmpty ? fullNameRaw : email,
      joinedAt: json['joined_at']?.toString(),
      invitedAt: json['invited_at']?.toString(),
    );
  }
}

