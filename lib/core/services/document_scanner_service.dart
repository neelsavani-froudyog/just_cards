import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

class DocumentScannerService {
  const DocumentScannerService._();

  static Future<List<String>> scan({required bool allowMultiple}) async {
    final options = DocumentScannerOptions(
      documentFormats: {DocumentFormat.jpeg},
      mode: ScannerMode.full,
      pageLimit: allowMultiple ? 20 : 1,
      isGalleryImport: true,
    );

    final scanner = DocumentScanner(options: options);
    try {
      final result = await scanner.scanDocument();
      return result.images ?? <String>[];
    } catch (_) {
      // ToastService.error('Unable to open scanner');
      return <String>[];
    } finally {
      await scanner.close();
    }
  }
}
