import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/parse_card_response.dart';
import 'api.dart';
import 'api_service.dart';

/// Sends OCR text to the backend for structured card parsing (GPT).
class ParseCardService extends GetxService {
  static ParseCardService get to => Get.find<ParseCardService>();

  Future<ParseCardOutcome> parseCard(String ocrText) async {
    log('[parse-card] parsing card: $ocrText');
    final trimmed = ocrText.trim();
    if (trimmed.isEmpty) {
      return const ParseCardOutcome(
        success: false,
        errorMessage: 'No text to parse',
      );
    }

    final api = Get.find<ApiService>();
    ParseCardOutcome result = const ParseCardOutcome(
      success: false,
      errorMessage: 'Request failed',
    );

    try {
      if (kDebugMode) {
        debugPrint('[parse-card] POST ${ApiUrl.parseCard}');
      }

      await api.postRequest(
        url: ApiUrl.parseCard,
        data: {'ocr_text': trimmed},
        header: {'Content-Type': 'application/json'},
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) {
            result = const ParseCardOutcome(
              success: false,
              errorMessage: 'Invalid response shape',
            );
            return;
          }

          final parsed = ParseCardResponse.fromJson(raw);
          if (!parsed.ok || parsed.data == null) {
            result = ParseCardOutcome(
              success: false,
              errorMessage:
                  parsed.message.isNotEmpty ? parsed.message : 'Parse failed',
            );
            return;
          }

          result = ParseCardOutcome(
            success: true,
            response: parsed,
          );
        },
        onError: (message) {
          result = ParseCardOutcome(
            success: false,
            errorMessage: message.isNotEmpty ? message : 'Request failed',
          );
        },
      );

      return result;
    } catch (e, st) {
      if (kDebugMode) {
        log('[parse-card] error: $e\n$st');
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
