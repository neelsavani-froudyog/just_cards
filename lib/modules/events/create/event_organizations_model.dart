class EventOrganizationsResponse {
  final bool ok;
  final String message;
  final List<EventOrganizationOption> data;

  const EventOrganizationsResponse({
    required this.ok,
    required this.message,
    required this.data,
  });

  factory EventOrganizationsResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = <EventOrganizationOption>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          items.add(EventOrganizationOption.fromJson(item));
        }
      }
    }

    return EventOrganizationsResponse(
      ok: json['ok'] == true,
      message: (json['message'] ?? '').toString(),
      data: items,
    );
  }
}

class EventOrganizationOption {
  final String id;
  final String name;

  const EventOrganizationOption({
    required this.id,
    required this.name,
  });

  factory EventOrganizationOption.fromJson(Map<String, dynamic> json) {
    return EventOrganizationOption(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}
