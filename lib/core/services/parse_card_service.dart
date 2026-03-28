import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/parse_card_response.dart';
import 'api.dart';
import 'auth_session_service.dart';
import 'http_sender_io.dart';
import '../../routes/app_routes.dart';

/// Sends OCR text to the backend for structured card parsing (GPT).
class ParseCardService extends GetxService {
  static ParseCardService get to => Get.find<ParseCardService>();

  Future<ParseCardOutcome> parseCard(String ocrText) async {
    final trimmed = ocrText.trim();
    if (trimmed.isEmpty) {
      return const ParseCardOutcome(
        success: false,
        errorMessage: 'No text to parse',
      );
    }

    final session = Get.find<AuthSessionService>();
    final token = session.accessToken.value.trim();

    final base = ApiUrl.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base${ApiUrl.parseCard}');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    try {
      if (kDebugMode) {
        debugPrint('[parse-card] POST $uri');
        if (token.isEmpty) {
          debugPrint('[parse-card] warning: no access token; API may return 401');
        }
      }

      final response = await sendHttpRequest(
        method: 'POST',
        uri: uri,
        headers: headers,
        body: json.encode(<String, dynamic>{'ocr_text': trimmed}),
      );

      if (kDebugMode) {
        debugPrint(
          '[parse-card] status=${response.statusCode} len=${response.bodyText.length}',
        );
      }

      if (response.statusCode == 401) {
        session.clear();
        Get.offAllNamed(Routes.login);
        return const ParseCardOutcome(
          success: false,
          errorMessage: 'Session expired',
        );
      }

      final okHttp = response.statusCode >= 200 && response.statusCode < 300;
      final body = response.bodyText.trim();
      if (body.isEmpty) {
        return ParseCardOutcome(
          success: false,
          errorMessage: 'Empty response (HTTP ${response.statusCode})',
        );
      }

      dynamic decodedRaw;
      try {
        decodedRaw = json.decode(body);
      } catch (e) {
        return ParseCardOutcome(
          success: false,
          errorMessage: 'Invalid JSON: $e',
        );
      }

      if (decodedRaw is! Map) {
        return const ParseCardOutcome(
          success: false,
          errorMessage: 'Invalid response shape',
        );
      }

      final decoded = Map<String, dynamic>.from(decodedRaw);

      if (!okHttp) {
        final msg = decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            'HTTP ${response.statusCode}';
        return ParseCardOutcome(success: false, errorMessage: msg);
      }

      final parsed = ParseCardResponse.fromJson(decoded);
      if (!parsed.ok || parsed.data == null) {
        return ParseCardOutcome(
          success: false,
          errorMessage:
              parsed.message.isNotEmpty ? parsed.message : 'Parse failed',
        );
      }

      return ParseCardOutcome(
        success: true,
        response: parsed,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[parse-card] error: $e\n$st');
      }
      return ParseCardOutcome(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}

class ParseCardOutcome {
  const ParseCardOutcome({
    required this.success,
    this.response,
    this.errorMessage,
  });

  final bool success;
  final ParseCardResponse? response;
  final String? errorMessage;

  ParseCardFields? get fields => response?.data?.fields;
}
