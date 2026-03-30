class OrganizationsSimpleResponse {
  final bool ok;
  final String message;
  final List<OrganizationOption> data;

  const OrganizationsSimpleResponse({
    required this.ok,
    required this.message,
    required this.data,
  });

  factory OrganizationsSimpleResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'];
    final items = <OrganizationOption>[];

    if (rawList is List) {
      for (final item in rawList) {
        if (item is Map<String, dynamic>) {
          items.add(OrganizationOption.fromJson(item));
        }
      }
    }

    return OrganizationsSimpleResponse(
      ok: json['ok'] == true,
      message: (json['message'] ?? '').toString(),
      data: items,
    );
  }
}

class OrganizationOption {
  final String id;
  final String name;

  const OrganizationOption({
    required this.id,
    required this.name,
  });

  factory OrganizationOption.fromJson(Map<String, dynamic> json) {
    return OrganizationOption(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

