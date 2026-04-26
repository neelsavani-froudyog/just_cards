class HomeEventsResponse {
  final bool ok;
  final String message;
  final List<HomeEventItem> data;

  const HomeEventsResponse({
    required this.ok,
    required this.message,
    required this.data,
  });

  factory HomeEventsResponse.fromJson(Map<String, dynamic> json) {
    // API may return either:
    // 1) { data: [ ... ] }
    // 2) { data: { data: [ ... ], total: N } }
    final dynamic rawData = json['data'];
    final dynamic rawList =
        rawData is Map<String, dynamic> ? rawData['data'] : rawData;

    final items = <HomeEventItem>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          items.add(HomeEventItem.fromJson(item));
        }
      }
    }
    return HomeEventsResponse(
      ok: json['ok'] == true,
      message: (json['message'] ?? '').toString(),
      data: items,
    );
  }
}

class HomeEventItem {
  final String id;
  final String title;
  final String eventDate;
  final String location;
  final String scope;
  final String? organizationId;
  final int membersCount;
  final String role;
  final String type;
  final String createdBy;

  const HomeEventItem({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.location,
    required this.scope,
    required this.organizationId,
    required this.membersCount,
    required this.role,
    required this.type,
    this.createdBy = '',
  });

  factory HomeEventItem.fromJson(Map<String, dynamic> json) {
    return HomeEventItem(
      id: (json['id'] ?? '').toString(),
      title: (json['name'] ?? json['title'] ?? '').toString(),
      eventDate: (json['event_date'] ?? '').toString(),
      location: (json['location_text'] ?? json['location'] ?? '').toString(),
      scope: (json['scope'] ?? '').toString(),
      organizationId: json['organization_id']?.toString(),
      membersCount: _toInt(
        json['member_count'] ?? json['members_count'] ?? json['membersCount'],
      ),
      role: (json['member_role'] ?? json['event_role'] ?? json['my_role'] ?? json['user_role'] ?? '')
          .toString(),
      type: (json['type'] ?? '').toString(),
      createdBy: (json['created_by'] ?? json['createdBy'] ?? json['user_id'] ?? '')
          .toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
