import '../../../core/models/parse_card_response.dart';

enum MultiCardScanAction { scanNext, finishScanning }

class MultiScannedCard {
  const MultiScannedCard({
    required this.id,
    required this.imagePath,
    required this.ocrText,
    required this.fields,
    required this.parseSucceeded,
    required this.fingerprint,
    this.parseError,
  });

  final String id;
  final String imagePath;
  final String ocrText;
  final ParseCardFields fields;
  final bool parseSucceeded;
  final String fingerprint;
  final String? parseError;

  MultiScannedCard copyWith({
    String? id,
    String? imagePath,
    String? ocrText,
    ParseCardFields? fields,
    bool? parseSucceeded,
    String? fingerprint,
    String? parseError,
  }) {
    return MultiScannedCard(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      ocrText: ocrText ?? this.ocrText,
      fields: fields ?? this.fields,
      parseSucceeded: parseSucceeded ?? this.parseSucceeded,
      fingerprint: fingerprint ?? this.fingerprint,
      parseError: parseError ?? this.parseError,
    );
  }

  String get title {
    if (fields.name.isNotEmpty) return fields.name;
    if (fields.company.isNotEmpty) return fields.company;
    return 'Scanned card';
  }

  String get subtitle {
    if (fields.designation.isNotEmpty && fields.company.isNotEmpty) {
      return '${fields.designation} • ${fields.company}';
    }
    if (fields.designation.isNotEmpty) return fields.designation;
    if (fields.company.isNotEmpty) return fields.company;
    return parseSucceeded ? 'Parsed from scan' : 'OCR only';
  }
}

class MultiCardScanAddOutcome {
  const MultiCardScanAddOutcome({
    required this.added,
    this.card,
    this.isDuplicate = false,
    this.message,
  });

  final bool added;
  final MultiScannedCard? card;
  final bool isDuplicate;
  final String? message;
}
