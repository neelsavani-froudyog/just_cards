import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'api.dart';
import 'api_service.dart';
import 'auth_session_service.dart';
import 'http_sender_io.dart';
import '../../routes/app_routes.dart';

class CreateContactResult {
  const CreateContactResult({
    required this.success,
    this.message,
  });

  final bool success;
  final String? message;
}

/// Creates a contact via `POST /contacts` on [ApiUrl.baseUrl] (e.g. local `:3000`).
class CreateContactService extends GetxService {
  static CreateContactService get to => Get.find<CreateContactService>();

  Future<String?> fetchProfileUserId() async {
    final session = Get.find<AuthSessionService>();
    final token = session.accessToken.value.trim();
    if (token.isEmpty) return null;

    final base = ApiUrl.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base${ApiUrl.profileMe}');

    try {
      final response = await sendHttpRequest(
        method: 'GET',
        uri: uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        session.clear();
        Get.offAllNamed(Routes.login);
        return null;
      }

      final body = response.bodyText.trim();
      if (body.isEmpty) return null;

      final decoded = json.decode(body);
      if (decoded is! Map) return null;
      final data = decoded['data'];
      if (data is! Map) return null;
      final id = data['user_id']?.toString().trim();
      if (id == null || id.isEmpty) return null;
      return id;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[create_contact] profile: $e\n$st');
      }
      return null;
    }
  }

  /// Body matches backend / Supabase RPC parameter names.
  Future<CreateContactResult> createContact({
    required String ownerUserId,
    required String createdBy,
    required String fullName,
    required String source,
    required String eventId,
    required bool allowShareOrganization,
    required String firstName,
    required String lastName,
    required String designation,
    required String companyName,
    required String email1,
    required String email2,
    required String phone1,
    required String phone2,
    required String address,
    required String website,
    required String cardImgUrl,
    required List<String> tags,
    String? profilePhotoUrl,
  }) async {
    final session = Get.find<AuthSessionService>();
    final token = session.accessToken.value.trim();
    if (token.isEmpty) {
      return const CreateContactResult(
        success: false,
        message: 'Please sign in',
      );
    }

    final bodyMap = <String, dynamic>{
      'p_owner_user_id': ownerUserId,
      'p_created_by': createdBy,
      'p_full_name': fullName,
      'p_source': source,
      'p_event_id': eventId,
      'p_allow_share_organization': allowShareOrganization,
      'p_first_name': firstName,
      'p_last_name': lastName,
      'p_designation': designation,
      'p_company_name': companyName,
      'p_email_1': email1,
      'p_email_2': email2,
      'p_phone_1': phone1,
      'p_phone_2': phone2,
      'p_address': address,
      'p_website': website,
      'p_card_img_url': cardImgUrl,
      'p_profile_photo_url': profilePhotoUrl,
      'p_tags': tags,
    };

    final api = Get.find<ApiService>();
    CreateContactResult result = const CreateContactResult(
      success: false,
      message: 'Request failed',
    );

    try {
      if (kDebugMode) {
        debugPrint('[create_contact] POST ${ApiUrl.contacts}');
      }

      await api.postRequest(
        url: ApiUrl.contacts,
        data: bodyMap,
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is Map) {
            final message = raw['message']?.toString().trim();
            result = CreateContactResult(
              success: true,
              message: (message != null && message.isNotEmpty)
                  ? message
                  : 'Contact saved',
            );
            return;
          }

          result = const CreateContactResult(
            success: true,
            message: 'Contact saved',
          );
        },
        onError: (message) {
          result = CreateContactResult(success: false, message: message);
        },
      );

      return result;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[create_contact] error: $e\n$st');
      }
      return CreateContactResult(success: false, message: e.toString());
    }
  }

}
