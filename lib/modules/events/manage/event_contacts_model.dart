class EventContactsResponse {
  final bool ok;
  final String message;
  final List<EventContactItem> data;
  final int limit;
  final int offset;
  final int total;

  const EventContactsResponse({
    required this.ok,
    required this.message,
    required this.data,
    required this.limit,
    required this.offset,
    required this.total,
  });

  factory EventContactsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final items = <EventContactItem>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          items.add(EventContactItem.fromJson(item));
        }
      }
    }

    return EventContactsResponse(
      ok: json['ok'] == true,
      message: (json['message'] ?? '').toString(),
      data: items,
      limit: _toInt(json['limit']),
      offset: _toInt(json['offset']),
      total: _toInt(json['total']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class EventContactItem {
  final String id;
  final String fullName;
  final String firstName;
  final String lastName;
  final String email1;
  final String email2;
  final String phone1;
  final String phone2;
  final String companyName;
  final String designation;
  final String website;
  final String address;
  final String status;
  final String source;
  final String eventId;
  final String? organizationId;
  final String cardImgUrl;
  final String? profilePhotoUrl;
  final String createdAt;

  const EventContactItem({
    required this.id,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.email1,
    required this.email2,
    required this.phone1,
    required this.phone2,
    required this.companyName,
    required this.designation,
    required this.website,
    required this.address,
    required this.status,
    required this.source,
    required this.eventId,
    required this.organizationId,
    required this.cardImgUrl,
    required this.profilePhotoUrl,
    required this.createdAt,
  });

  factory EventContactItem.fromJson(Map<String, dynamic> json) {
    return EventContactItem(
      id: (json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      email1: (json['email_1'] ?? '').toString(),
      email2: (json['email_2'] ?? '').toString(),
      phone1: (json['phone_1'] ?? '').toString(),
      phone2: (json['phone_2'] ?? '').toString(),
      companyName: (json['company_name'] ?? '').toString(),
      designation: (json['designation'] ?? '').toString(),
      website: (json['website'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      eventId: (json['event_id'] ?? '').toString(),
      organizationId: json['organization_id']?.toString(),
      cardImgUrl: (json['card_img_url'] ?? '').toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

