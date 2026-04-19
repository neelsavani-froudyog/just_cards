class EventMembersResponse {
  final bool ok;
  final String message;
  final List<EventMemberItem> data;

  const EventMembersResponse({
    required this.ok,
    required this.message,
    required this.data,
  });

  factory EventMembersResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final items = <EventMemberItem>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          items.add(EventMemberItem.fromJson(item));
        }
      }
    }
    return EventMembersResponse(
      ok: json['ok'] == true,
      message: (json['message'] ?? '').toString(),
      data: items,
    );
  }
}

class EventMemberItem {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String role;
  final String? status;
  final String? inviteId;
  final String? inviteBatchId;
  final String? invitedBy;
  final String? joinedAt;

  const EventMemberItem({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.status,
    required this.inviteId,
    required this.inviteBatchId,
    required this.invitedBy,
    required this.joinedAt,
  });

  factory EventMemberItem.fromJson(Map<String, dynamic> json) {
    return EventMemberItem(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      role: (json['role'] ?? 'viewer').toString(),
      status: json['status']?.toString(),
      inviteId: json['invite_id']?.toString(),
      inviteBatchId: _firstString(
        json,
        const <String>[
          'invite_batch_id',
          'inviteBatchId',
          'batch_id',
          'invite_batch',
        ],
      ),
      invitedBy: json['invited_by']?.toString(),
      joinedAt: json['joined_at']?.toString(),
    );
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final v = json[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }
}
