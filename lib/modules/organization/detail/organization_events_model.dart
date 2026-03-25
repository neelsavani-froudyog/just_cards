class OrganizationEventsResponse {
  const OrganizationEventsResponse({
    required this.ok,
    required this.message,
    required this.data,
  });

  final bool ok;
  final String message;
  final List<OrganizationEvent> data;

  factory OrganizationEventsResponse.fromJson(Map<String, dynamic> json) {
    final ok = json['ok'] == true;
    final message = json['message']?.toString() ?? '';
    final raw = json['data'];
    final items = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => OrganizationEvent.fromJson(e.cast<String, dynamic>()))
            .toList()
        : const <OrganizationEvent>[];
    return OrganizationEventsResponse(ok: ok, message: message, data: items);
  }
}

class OrganizationEvent {
  const OrganizationEvent({
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.locationText,
    required this.contactCount,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  final String eventId;
  final String eventName;
  final String eventDate; // backend: yyyy-MM-dd
  final String locationText;
  final int contactCount;
  final String createdAt;
  final String updatedAt;
  final String createdBy;

  factory OrganizationEvent.fromJson(Map<String, dynamic> json) {
    return OrganizationEvent(
      eventId: json['event_id']?.toString() ?? '',
      eventName: json['event_name']?.toString() ?? '',
      eventDate: json['event_date']?.toString() ?? '',
      locationText: json['location_text']?.toString() ?? '',
      contactCount: (json['contact_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? '',
    );
  }
}

