import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_cards/modules/contacts/qr_import/qr_data_entry/qr_contact_controller.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import 'contact_qr_parser.dart';

/// Full-screen QR scanner; after a successful read opens [ManualEntryView] flow
/// with the same layout as manual entry, prefilled from the QR payload.
class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key});

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _busy = false;
  bool _torchOn = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;

    final raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    if (raw == null || raw.trim().isEmpty) return;

    _busy = true;
    setState(() => _errorText = null);

    try {
      await _controller.stop();

      final data = ContactQrParser.parse(raw);
      if (data.format != 'vcard') {
        const message = 'This is not a valid contact QR';
        if (!mounted) return;
        setState(() => _errorText = message);
        await ToastService.error(message);
        await _controller.start();
        _busy = false;
        return;
      }

      final args = <String, dynamic>{
        ...data.toMap(),
        '__appBarTitle': 'Contact from QR',
      };

      if (Get.isRegistered<QrContactController>()) {
        Get.delete<QrContactController>(force: true);
      }

      final result = await Get.toNamed(
        Routes.qrContact,
        arguments: args,
      );

      if (!mounted) return;
      Get.back(result: result == true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.toString());
      await _controller.start();
      _busy = false;
    }
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (mounted) setState(() => _torchOn = !_torchOn);
  }

  Future<void> _flipCamera() async {
    await _controller.switchCamera();
  }

  Future<void> _cancel() async {
    await _controller.stop();
    if (mounted) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: _cancel,
        ),
        title: const Text(
          'Scan contact QR',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: Colors.white,
            ),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded, color: Colors.white),
            onPressed: _flipCamera,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Point camera at a contact QR code (vCard / MeCard)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
