import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'api.dart';
import 'auth_session_service.dart';
import 'http_sender_io.dart';
import '../../routes/app_routes.dart';

class BusinessCardUploadResult {
  const BusinessCardUploadResult({
    required this.success,
    this.publicUrl,
    this.storagePath,
    this.message,
  });

  final bool success;
  final String? publicUrl;
  final String? storagePath;
  final String? message;
}

/// Uploads the scanned card image to CDN via [ApiUrl.eventsBusinessCardUpload].
class BusinessCardUploadService extends GetxService {
  static BusinessCardUploadService get to => Get.find<BusinessCardUploadService>();

  Future<BusinessCardUploadResult> upload({
    required String eventName,
    required File imageFile,
  }) async {
    final trimmedEvent = eventName.trim();
    if (trimmedEvent.isEmpty) {
      return const BusinessCardUploadResult(
        success: false,
        message: 'Event name is required',
      );
    }

    final session = Get.find<AuthSessionService>();
    final token = session.accessToken.value.trim();
    if (token.isEmpty) {
      return const BusinessCardUploadResult(
        success: false,
        message: 'Please sign in to upload',
      );
    }

    final base = ApiUrl.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base${ApiUrl.eventsBusinessCardUpload}');

    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final textFields = <String, String>{
      'event_name': trimmedEvent,
    };

    try {
      if (kDebugMode) {
        debugPrint('[business-card-upload] POST $uri event_name=$trimmedEvent');
      }

      final response = await sendMultipartFormData(
        uri: uri,
        headers: headers,
        textFields: textFields,
        fileFieldName: 'image',
        file: imageFile,
      );

      if (response.statusCode == 401) {
        session.clear();
        Get.offAllNamed(Routes.login);
        return const BusinessCardUploadResult(
          success: false,
          message: 'Session expired',
        );
      }

      final body = response.bodyText.trim();
      if (body.isEmpty) {
        return BusinessCardUploadResult(
          success: false,
          message: 'Empty response (HTTP ${response.statusCode})',
        );
      }

      dynamic decodedRaw;
      try {
        decodedRaw = json.decode(body);
      } catch (e) {
        return BusinessCardUploadResult(
          success: false,
          message: 'Invalid JSON: $e',
        );
      }

      if (decodedRaw is! Map) {
        return const BusinessCardUploadResult(
          success: false,
          message: 'Invalid response',
        );
      }

      final decoded = Map<String, dynamic>.from(decodedRaw);
      final ok = decoded['ok'] == true;
      final msg = decoded['message']?.toString() ?? '';

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return BusinessCardUploadResult(
          success: false,
          message: msg.isNotEmpty
              ? msg
              : 'Upload failed (HTTP ${response.statusCode})',
        );
      }

      if (!ok) {
        return BusinessCardUploadResult(
          success: false,
          message: msg.isNotEmpty ? msg : 'Upload failed',
        );
      }

      final data = decoded['data'];
      String? publicUrl;
      String? storagePath;
      if (data is Map) {
        publicUrl = data['public_url']?.toString();
        storagePath = data['storage_path']?.toString();
      }

      if (publicUrl == null || publicUrl.isEmpty) {
        return BusinessCardUploadResult(
          success: false,
          message: msg.isNotEmpty ? msg : 'No public_url in response',
        );
      }

      return BusinessCardUploadResult(
        success: true,
        publicUrl: publicUrl,
        storagePath: storagePath,
        message: msg.isNotEmpty ? msg : 'Uploaded',
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[business-card-upload] error: $e\n$st');
      }
      return BusinessCardUploadResult(
        success: false,
        message: e.toString(),
      );
    }
  }
}
