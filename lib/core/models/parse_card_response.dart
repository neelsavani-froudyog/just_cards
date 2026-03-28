/// Response from `POST /scan-quota/parse-card`.
class ParseCardResponse {
  const ParseCardResponse({
    required this.ok,
    required this.message,
    this.data,
  });

  final bool ok;
  final String message;
  final ParseCardData? data;

  factory ParseCardResponse.fromJson(Map<String, dynamic> json) {
    final dynamic rawData = json['data'];
    return ParseCardResponse(
      ok: json['ok'] == true,
      message: json['message']?.toString() ?? '',
      data: rawData is Map<String, dynamic>
          ? ParseCardData.fromJson(rawData)
          : null,
    );
  }
}

class ParseCardData {
  const ParseCardData({
    required this.fields,
    this.meta,
  });

  final ParseCardFields fields;
  final ParseCardMeta? meta;

  factory ParseCardData.fromJson(Map<String, dynamic> json) {
    final dynamic rawFields = json['fields'];
    final dynamic rawMeta = json['meta'];
    return ParseCardData(
      fields: rawFields is Map<String, dynamic>
          ? ParseCardFields.fromJson(rawFields)
          : ParseCardFields.empty(),
      meta: rawMeta is Map<String, dynamic>
          ? ParseCardMeta.fromJson(rawMeta)
          : null,
    );
  }
}

class ParseCardFields {
  const ParseCardFields({
    required this.name,
    required this.designation,
    required this.company,
    required this.emails,
    required this.phones,
    this.website,
    this.address,
  });

  factory ParseCardFields.empty() => const ParseCardFields(
        name: '',
        designation: '',
        company: '',
        emails: <String>[],
        phones: <String>[],
        website: null,
        address: null,
      );

  final String name;
  final String designation;
  final String company;
  final List<String> emails;
  final List<String> phones;
  final String? website;
  final String? address;

  factory ParseCardFields.fromJson(Map<String, dynamic> json) {
    List<String> listOfString(dynamic v) {
      if (v is! List) return <String>[];
      return v.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }

    return ParseCardFields(
      name: json['name']?.toString().trim() ?? '',
      designation: json['designation']?.toString().trim() ?? '',
      company: json['company']?.toString().trim() ?? '',
      emails: listOfString(json['emails']),
      phones: listOfString(json['phones']),
      website: json['website']?.toString().trim(),
      address: json['address']?.toString().trim(),
    );
  }
}

class ParseCardMeta {
  const ParseCardMeta({
    this.id,
    this.userId,
    this.model,
    this.used,
    this.quota,
    this.remaining,
    this.resetAt,
    this.planCode,
    this.languageDetected,
    this.phoneCandidates,
  });

  final String? id;
  final String? userId;
  final String? model;
  final int? used;
  final int? quota;
  final int? remaining;
  final String? resetAt;
  final String? planCode;
  final List<String>? languageDetected;
  final List<String>? phoneCandidates;

  factory ParseCardMeta.fromJson(Map<String, dynamic> json) {
    List<String>? strings(dynamic v) {
      if (v is! List) return null;
      return v.map((e) => e.toString()).toList();
    }

    int? asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '');
    }

    return ParseCardMeta(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      model: json['model']?.toString(),
      used: asInt(json['used']),
      quota: asInt(json['quota']),
      remaining: asInt(json['remaining']),
      resetAt: json['reset_at']?.toString(),
      planCode: json['plan_code']?.toString(),
      languageDetected: strings(json['language_detected']),
      phoneCandidates: strings(json['phone_candidates']),
    );
  }
}
