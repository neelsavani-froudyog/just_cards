class OrganizationContactsResponse {
  final bool ok;
  final String message;
  final List<OrganizationContactItem> data;
  final int limit;
  final int offset;
  final int total;

  const OrganizationContactsResponse({
    required this.ok,
    required this.message,
    required this.data,
    required this.limit,
    required this.offset,
    required this.total,
  });

  factory OrganizationContactsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final items = <OrganizationContactItem>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          items.add(OrganizationContactItem.fromJson(item));
        }
      }
    }

    return OrganizationContactsResponse(
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

class OrganizationContactItem {
  final String id;
  final String fullName;
  final String firstName;
  final String lastName;
  final String email1;
  final String phone1;
  final String companyName;
  final String designation;
  final String status;

  const OrganizationContactItem({
    required this.id,
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.email1,
    required this.phone1,
    required this.companyName,
    required this.designation,
    required this.status,
  });

  factory OrganizationContactItem.fromJson(Map<String, dynamic> json) {
    return OrganizationContactItem(
      id: (json['id'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      email1: (json['email_1'] ?? '').toString(),
      phone1: (json['phone_1'] ?? '').toString(),
      companyName: (json['company_name'] ?? '').toString(),
      designation: (json['designation'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

