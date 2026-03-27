import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:barcode_scanner/scanbot_barcode_sdk.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_field.dart';

class ImportFromQrView extends StatefulWidget {
  const ImportFromQrView({super.key});

  @override
  State<ImportFromQrView> createState() => _ImportFromQrViewState();
}

class _ImportFromQrViewState extends State<ImportFromQrView> {
  final TextEditingController _qrDataController = TextEditingController();
  bool _isScanning = false;
  bool _sdkInitialized = false;

  @override
  void dispose() {
    _qrDataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.ink,
        ),
        title: const Text('Import from QR'),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          color: AppColors.ink.withValues(alpha: 0.80),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Scan or paste QR content',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Import contact details quickly from a QR code.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(
                    controller: _qrDataController,
                    label: 'QR Data',
                    hint: 'Paste vCard / QR text here...',
                    minLines: 6,
                    maxLines: 6,
                    filled: true,
                    fillColor: AppColors.surface,
                    borderColor: AppColors.ink.withValues(alpha: 0.14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isScanning ? null : _openQrScanner,
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: Text(_isScanning ? 'Opening…' : 'Open QR Scanner'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: BorderSide(color: AppColors.ink.withValues(alpha: 0.22)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.snackbar(
                          '',
                          'QR import design is ready. Parser hookup next.',
                          titleText: const SizedBox.shrink(),
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: AppColors.primary,
                          colorText: AppColors.white,
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Import Contact'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ensureSdkInitialized() async {
    if (_sdkInitialized) return;
    final config = SdkConfiguration(
      licenseKey: '',
      loggingEnabled: true,
    );
    await ScanbotBarcodeSdk.initialize(config);
    _sdkInitialized = true;
  }

  Future<void> _openQrScanner() async {
    setState(() => _isScanning = true);
    try {
      await _ensureSdkInitialized();

      final configuration = BarcodeScannerScreenConfiguration();
      configuration.useCase = SingleScanningMode();

      final result = await ScanbotBarcodeSdk.barcode.startScanner(configuration);
      final uiResult = result.getOrNull();
      final text = uiResult?.items.isNotEmpty == true
          ? uiResult!.items.first.barcode.text.trim()
          : '';

      if (text.isNotEmpty) {
        _qrDataController.text = text;
      }

      uiResult?.release();
    } catch (e) {
      Get.snackbar(
        '',
        'Unable to open QR scanner: $e',
        titleText: const SizedBox.shrink(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: AppColors.white,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }
}
