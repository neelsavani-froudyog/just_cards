import 'package:get/get.dart';

import '../../../core/models/parse_card_response.dart';
import '../../../core/services/mlkit_text_recognition_service.dart';
import '../../../core/services/parse_card_service.dart';
import 'multi_card_scan_models.dart';

class MultiCardScanController extends GetxController {
  final scannedCards = <MultiScannedCard>[].obs;
  final isProcessing = false.obs;

  int get scannedCount => scannedCards.length;

  MultiScannedCard? get latestCard =>
      scannedCards.isEmpty ? null : scannedCards.last;

  MultiScannedCard? findById(String? id) {
    if (id == null || id.isEmpty) return latestCard;
    for (final card in scannedCards) {
      if (card.id == id) return card;
    }
    return latestCard;
  }

  void updateCardFields(String cardId, ParseCardFields fields) {
    final index = scannedCards.indexWhere((card) => card.id == cardId);
    if (index < 0) return;

    final current = scannedCards[index];
    scannedCards[index] = current.copyWith(
      fields: fields,
      fingerprint: _buildFingerprint(current.ocrText, fields),
    );
  }

  Future<MultiCardScanAddOutcome> processScannedImage(String imagePath) async {
    if (isProcessing.value) {
      return const MultiCardScanAddOutcome(
        added: false,
        message: 'A scan is already being processed.',
      );
    }

    isProcessing.value = true;
    try {
      final ocrText =
          await MlKitTextRecognitionService.recognizeLatinFromFilePath(
            imagePath,
          );
      final trimmedText = ocrText.trim();
      if (trimmedText.isEmpty) {
        return const MultiCardScanAddOutcome(
          added: false,
          message: 'No readable text found. Please scan again.',
        );
      }

      final parseOutcome = await ParseCardService.to.parseCard(trimmedText);
      final fields = parseOutcome.fields ?? ParseCardFields.empty();
      final fingerprint = _buildFingerprint(trimmedText, fields);

      if (_isDuplicate(fingerprint)) {
        return const MultiCardScanAddOutcome(
          added: false,
          isDuplicate: true,
          message: 'This card looks like a duplicate, so it was skipped.',
        );
      }

      final card = MultiScannedCard(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        imagePath: imagePath,
        ocrText: trimmedText,
        fields: fields,
        parseSucceeded: parseOutcome.success,
        parseError: parseOutcome.errorMessage,
        fingerprint: fingerprint,
      );
      scannedCards.add(card);

      return MultiCardScanAddOutcome(added: true, card: card);
    } finally {
      isProcessing.value = false;
    }
  }

  bool _isDuplicate(String fingerprint) {
    for (final card in scannedCards) {
      if (card.fingerprint == fingerprint) return true;
    }
    return false;
  }

  String _buildFingerprint(String ocrText, ParseCardFields fields) {
    final parts =
        <String>[
          fields.name,
          fields.designation,
          fields.company,
          ...fields.emails,
          ...fields.phones,
          fields.website ?? '',
          fields.address ?? '',
        ].map(_normalize).where((value) => value.isNotEmpty).toList();

    if (parts.isEmpty) {
      return _normalize(ocrText);
    }

    return parts.join('|');
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}
