class ProfileMeResponse {
  final bool ok;
  final String message;
  final ProfileData? data;

  const ProfileMeResponse({
    required this.ok,
    required this.message,
    required this.data,
  });

  factory ProfileMeResponse.fromJson(Map<String, dynamic> json) {
    return ProfileMeResponse(
      ok: json['ok'] == true,
      message: (json['message'] ?? '').toString(),
      data: json['data'] is Map<String, dynamic>
          ? ProfileData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ProfileData {
  final String? role;
  final String email;
  final String? phone;
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? createdAt;
  final String? updatedAt;
  final String? companyName;
  final String? designation;
  final String? address;
  final String? website;
  final String? secondaryEmail;
  final String? secondaryPhone;

  const ProfileData({
    required this.role,
    required this.email,
    required this.phone,
    required this.userId,
    required this.fullName,
    required this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.companyName,
    required this.designation,
    required this.address,
    required this.website,
    required this.secondaryEmail,
    required this.secondaryPhone,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      role: json['role']?.toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone']?.toString(),
      userId: (json['user_id'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      companyName: json['company_name']?.toString(),
      designation: json['designation']?.toString(),
      address: json['address']?.toString(),
      website: json['website']?.toString(),
      secondaryEmail: json['secondary_email']?.toString(),
      secondaryPhone: json['secondary_phone']?.toString(),
    );
  }
}
