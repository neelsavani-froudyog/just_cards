import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Runs on-device OCR on an image file path (local path or `file://` URI).
class MlKitTextRecognitionService {
  const MlKitTextRecognitionService._();

  static String _normalizePath(String path) {
    if (path.startsWith('file://')) {
      return path.substring(7);
    }
    return path;
  }

  /// Returns recognized plain text (often newline-separated lines). Empty if unreadable.
  static Future<String> recognizeLatinFromFilePath(String imagePath) async {
    final normalized = _normalizePath(imagePath);
    final file = File(normalized);
    if (!await file.exists()) {
      return '';
    }

    final inputImage = InputImage.fromFilePath(file.path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(inputImage);
      return recognized.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}
