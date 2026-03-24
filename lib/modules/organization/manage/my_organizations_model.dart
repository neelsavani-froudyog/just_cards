class MyOrganizationsResponse {
  final bool ok;
  final String message;
  final List<OrganizationSummary> data;
  final int limit;
  final int total;
  final int offset;

  const MyOrganizationsResponse({
    required this.ok,
    required this.message,
    required this.data,
    required this.limit,
    required this.total,
    required this.offset,
  });

  factory MyOrganizationsResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = <OrganizationSummary>[];
    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          items.add(OrganizationSummary.fromJson(item));
        }
      }
    }

    return MyOrganizationsResponse(
      ok: json['ok'] == true,
      message: (json['message'] ?? '').toString(),
      data: items,
      limit: _toInt(json['limit']),
      total: _toInt(json['total']),
      offset: _toInt(json['offset']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class OrganizationSummary {
  final String id;
  final String name;
  final String? industry;
  final String? createdBy;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const OrganizationSummary({
    required this.id,
    required this.name,
    required this.industry,
    required this.createdBy,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrganizationSummary.fromJson(Map<String, dynamic> json) {
    return OrganizationSummary(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      industry: json['industry']?.toString(),
      createdBy: json['created_by']?.toString(),
      isActive: json['is_active'] == true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

