/// Nested event or organization on contact detail (`/contacts/detail`).
class ContactDetailRef {
  const ContactDetailRef({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  static ContactDetailRef? maybeFrom(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final id = _str(m['id']);
    final name = _str(m['name']);
    if (id.isEmpty && name.isEmpty) return null;
    return ContactDetailRef(id: id, name: name);
  }
}

/// Response `data` object from `POST /contacts/detail`.
class ContactDetail {
  const ContactDetail({
    required this.id,
    this.event,
    this.organization,
    required this.source,
    required this.status,
    required this.address,
    this.email1,
    this.email2,
    this.phone1,
    this.phone2,
    this.website,
    this.eventId,
    required this.fullName,
    required this.lastName,
    required this.createdAt,
    this.createdBy,
    required this.firstName,
    required this.updatedAt,
    required this.designation,
    this.cardImgUrl,
    required this.companyName,
    this.ownerUserId,
    this.organizationId,
    this.profilePhotoUrl,
  });

  final String id;
  final ContactDetailRef? event;
  final ContactDetailRef? organization;
  final String source;
  final String status;
  final String address;
  final String? email1;
  final String? email2;
  final String? phone1;
  final String? phone2;
  final String? website;
  final String? eventId;
  final String fullName;
  final String lastName;
  final String createdAt;
  final String? createdBy;
  final String firstName;
  final String updatedAt;
  final String designation;
  final String? cardImgUrl;
  final String companyName;
  final String? ownerUserId;
  final String? organizationId;
  final String? profilePhotoUrl;

  String get displayName {
    final n = fullName.trim();
    if (n.isNotEmpty) return n;
    final combined = '${firstName.trim()} ${lastName.trim()}'.trim();
    if (combined.isNotEmpty) return combined;
    return 'Contact';
  }

  String get headerSubtitle {
    final c = companyName.trim();
    if (c.isNotEmpty) return c;
    final org = organization?.name.trim() ?? '';
    if (org.isNotEmpty) return org;
    final d = designation.trim();
    if (d.isNotEmpty) return d;
    return '';
  }

  String get phonesLine {
    final parts = <String>[
      if (phone1 != null && phone1!.trim().isNotEmpty) phone1!.trim(),
      if (phone2 != null && phone2!.trim().isNotEmpty) phone2!.trim(),
    ];
    return parts.join('  •  ');
  }

  String get emailsLine {
    final parts = <String>[
      if (email1 != null && email1!.trim().isNotEmpty) email1!.trim(),
      if (email2 != null && email2!.trim().isNotEmpty) email2!.trim(),
    ];
    return parts.join('\n');
  }

  String? get primaryPhone {
    if (phone1 != null && phone1!.trim().isNotEmpty) return phone1!.trim();
    if (phone2 != null && phone2!.trim().isNotEmpty) return phone2!.trim();
    return null;
  }

  String? get primaryEmail {
    if (email1 != null && email1!.trim().isNotEmpty) return email1!.trim();
    if (email2 != null && email2!.trim().isNotEmpty) return email2!.trim();
    return null;
  }

  factory ContactDetail.fromJson(Map<String, dynamic> json) {
    return ContactDetail(
      id: _str(json['id']),
      event: ContactDetailRef.maybeFrom(json['event']),
      organization: ContactDetailRef.maybeFrom(json['organization']),
      source: _str(json['source']),
      status: _str(json['status']),
      address: _str(json['address']),
      email1: _nullableStr(json['email_1']),
      email2: _nullableStr(json['email_2']),
      phone1: _nullableStr(json['phone_1']),
      phone2: _nullableStr(json['phone_2']),
      website: _nullableStr(json['website']),
      eventId: _nullableStr(json['event_id']),
      fullName: _str(json['full_name']),
      lastName: _str(json['last_name']),
      createdAt: _str(json['created_at']),
      createdBy: _nullableStr(json['created_by']),
      firstName: _str(json['first_name']),
      updatedAt: _str(json['updated_at']),
      designation: _str(json['designation']),
      cardImgUrl: _nullableStr(json['card_img_url']),
      companyName: _str(json['company_name']),
      ownerUserId: _nullableStr(json['owner_user_id']),
      organizationId: _nullableStr(json['organization_id']),
      profilePhotoUrl: _nullableStr(json['profile_photo_url']),
    );
  }
}

String _str(dynamic v) => v?.toString().trim() ?? '';

String? _nullableStr(dynamic v) {
  final s = v?.toString().trim() ?? '';
  if (s.isEmpty) return null;
  return s;
}
