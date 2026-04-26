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
  final String? source;
  final String? inviteId;
  final String? inviteBatchId;
  final String? invitedBy;
  final String? joinedAt;
  final String? invitedAt;

  const EventMemberItem({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.avatarUrl,
    required this.role,
    required this.status,
    required this.source,
    required this.inviteId,
    required this.inviteBatchId,
    required this.invitedBy,
    required this.joinedAt,
    required this.invitedAt,
  });

  factory EventMemberItem.fromJson(Map<String, dynamic> json) {
    final userId = (json['user_id'] ?? '').toString();
    final inviteId = json['invite_id']?.toString();
    final idRaw = (json['id'] ?? '').toString().trim();
    final resolvedId =
        idRaw.isNotEmpty
            ? idRaw
            : (userId.trim().isNotEmpty
                ? userId.trim()
                : (inviteId ?? '').trim());
    return EventMemberItem(
      id: resolvedId,
      userId: userId,
      fullName: (json['full_name'] ?? json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      role: (json['role'] ?? 'viewer').toString(),
      status: json['status']?.toString(),
      source: json['source']?.toString(),
      inviteId: inviteId,
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
      invitedAt: json['invited_at']?.toString(),
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
