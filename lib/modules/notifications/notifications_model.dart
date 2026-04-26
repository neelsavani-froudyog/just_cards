class NotificationsResponse {
  final bool ok;
  final bool success;
  final NotificationsData data;

  const NotificationsResponse({
    required this.ok,
    required this.success,
    required this.data,
  });

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      ok: json['ok'] == true,
      success: json['success'] == true,
      data: NotificationsData.fromJson(
        json['data'] is Map<String, dynamic>
            ? json['data']
            : <String, dynamic>{},
      ),
    );
  }
}

class NotificationsData {
  final NotificationCounts counts;
  final List<AppNotificationItem> notifications;

  const NotificationsData({
    required this.counts,
    required this.notifications,
  });

  factory NotificationsData.fromJson(Map<String, dynamic> json) {
    final raw = json['notifications'];
    final items = <AppNotificationItem>[];

    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          items.add(AppNotificationItem.fromJson(e));
        }
      }
    }

    return NotificationsData(
      counts: NotificationCounts.fromJson(
        json['counts'] is Map<String, dynamic>
            ? json['counts']
            : <String, dynamic>{},
      ),
      notifications: items,
    );
  }
}

class NotificationCounts {
  final int all;
  final int pending;
  final int accepted;
  final int declined;

  const NotificationCounts({
    required this.all,
    required this.pending,
    required this.accepted,
    required this.declined,
  });

  factory NotificationCounts.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) => int.tryParse((v ?? 0).toString()) ?? 0;

    return NotificationCounts(
      all: parseInt(json['all']),
      pending: parseInt(json['pending']),
      accepted: parseInt(json['accepted']),
      declined: parseInt(json['declined']),
    );
  }
}

class AppNotificationItem {
  final String id;
  final String role;
  final String title;
  final bool isSeen;
  final String message;
  final NotificationPayload payload;
  final String entityId;
  final String createdAt;
  final String actionType;
  final String entityType;
  final String actionStatus;
  final String? invitedByName;
  final bool requiresAction;
  final String notificationType;
  final String? organizationName;

  const AppNotificationItem({
    required this.id,
    required this.role,
    required this.title,
    required this.isSeen,
    required this.message,
    required this.payload,
    required this.entityId,
    required this.createdAt,
    required this.actionType,
    required this.entityType,
    required this.actionStatus,
    required this.invitedByName,
    required this.requiresAction,
    required this.notificationType,
    required this.organizationName,
  });

  AppNotificationItem copyWith({
    String? id,
    String? role,
    String? title,
    bool? isSeen,
    String? message,
    NotificationPayload? payload,
    String? entityId,
    String? createdAt,
    String? actionType,
    String? entityType,
    String? actionStatus,
    String? invitedByName,
    bool? requiresAction,
    String? notificationType,
    String? organizationName,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      role: role ?? this.role,
      title: title ?? this.title,
      isSeen: isSeen ?? this.isSeen,
      message: message ?? this.message,
      payload: payload ?? this.payload,
      entityId: entityId ?? this.entityId,
      createdAt: createdAt ?? this.createdAt,
      actionType: actionType ?? this.actionType,
      entityType: entityType ?? this.entityType,
      actionStatus: actionStatus ?? this.actionStatus,
      invitedByName: invitedByName ?? this.invitedByName,
      requiresAction: requiresAction ?? this.requiresAction,
      notificationType: notificationType ?? this.notificationType,
      organizationName: organizationName ?? this.organizationName,
    );
  }

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) {

    return AppNotificationItem(
      id: (json['id'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      isSeen: json['is_seen'] == true,
      message: (json['message'] ?? '').toString(),
      payload: NotificationPayload.fromJson(
        json['payload'] is Map<String, dynamic>
            ? json['payload']
            : <String, dynamic>{},
      ),
      entityId: (json['entity_id'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      actionType: (json['action_type'] ?? '').toString(),
      entityType: (json['entity_type'] ?? '').toString(),
      actionStatus: (json['action_status'] ?? '').toString(),
      invitedByName: json['invited_by_name']?.toString(),
      requiresAction: json['requires_action'] == true,
      notificationType: (json['notification_type'] ?? '').toString(),
      organizationName: json['organization_name']?.toString(),
    );
  }
}

class NotificationPayload {
  final String? note;
  final String? role;

  // Common
  final String? inviteId;
  final String? invitedBy;
  final String? appOpenPath;
  final String? accessSummary;
  final String? appDownloadUrl;

  // Organization
  final String? organizationId;
  final String? organizationName;

  // Event ✅ (NEW)
  final String? eventId;
  final String? eventName;

  const NotificationPayload({
    required this.note,
    required this.role,
    required this.inviteId,
    required this.invitedBy,
    required this.appOpenPath,
    required this.accessSummary,
    required this.organizationId,
    required this.organizationName,
    required this.appDownloadUrl,
    required this.eventId,
    required this.eventName,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      note: json['note']?.toString(),
      role: json['role']?.toString(),
      inviteId: json['invite_id']?.toString(),
      invitedBy: json['invited_by']?.toString(),
      appOpenPath: json['app_open_path']?.toString(),
      accessSummary: json['access_summary']?.toString(),
      organizationId: json['organization_id']?.toString(),
      organizationName: json['organization_name']?.toString(),
      appDownloadUrl: json['app_download_url']?.toString(),

      // ✅ Event fields (FIX)
      eventId: json['event_id']?.toString(),
      eventName: json['event_name']?.toString(),
    );
  }
}