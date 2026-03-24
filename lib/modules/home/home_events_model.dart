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
    final rawData = json['data'];
    final items = <HomeEventItem>[];
    if (rawData is List) {
      for (final item in rawData) {
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

  const HomeEventItem({
    required this.id,
    required this.title,
    required this.eventDate,
    required this.location,
    required this.scope,
    required this.organizationId,
    required this.membersCount,
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
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
