class HomeContactsResponse {
  final bool ok;
  final String message;
  final List<HomeContactItem> data;
  final int limit;
  final int offset;
  final int total;

  const HomeContactsResponse({
    required this.ok,
    required this.message,
    required this.data,
    required this.limit,
    required this.offset,
    required this.total,
  });

  factory HomeContactsResponse.fromJson(Map<String, dynamic> json) {
    // API returns: { data: { data: [ ... ], limit, offset, total } }
    final root = json['data'];
    final nested = root is Map<String, dynamic> ? root : const <String, dynamic>{};
    final rawList = nested['data'];

    final items = <HomeContactItem>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          items.add(HomeContactItem.fromJson(item));
        }
      }
    }

    return HomeContactsResponse(
      ok: json['ok'] == true,
      message: (json['message'] ?? '').toString(),
      data: items,
      limit: _toInt(nested['limit']),
      offset: _toInt(nested['offset']),
      total: _toInt(nested['total']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class HomeContactItem {
  final String id;
  final String fullName;
  final String firstName;
  final String lastName;
  final String email1;
  final String phone1;
  final String designation;
  final String companyName;
  final String accessType;
  final String createdAt;

  const HomeContactItem({
    required this.id,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.email1,
    required this.phone1,
    required this.designation,
    required this.companyName,
    required this.accessType,
    required this.createdAt,
  });

  factory HomeContactItem.fromJson(Map<String, dynamic> json) {
    return HomeContactItem(
      id: (json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      email1: (json['email_1'] ?? '').toString(),
      phone1: (json['phone_1'] ?? '').toString(),
      designation: (json['designation'] ?? '').toString(),
      companyName: (json['company_name'] ?? '').toString(),
      accessType: (json['access_type'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

