import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:barcode_scanner/scanbot_barcode_sdk.dart';

import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/document_scanner_service.dart';
import '../../../routes/app_routes.dart';
import '../../events/create/create_event_sheet.dart';
import '../home_controller.dart';

class AddContactSheet extends StatelessWidget {
  const AddContactSheet({super.key});

  static bool _qrSdkInitialized = false;

  static Future<void> _ensureQrSdkInitialized() async {
    if (_qrSdkInitialized) return;
    final config = SdkConfiguration(
      licenseKey: '',
      loggingEnabled: true,
    );
    await ScanbotBarcodeSdk.initialize(config);
    _qrSdkInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add Contact',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: Get.back,
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded, color: AppColors.ink.withValues(alpha: 0.75)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Column(
                children: [
                  _SheetTile(
                    icon: Icons.photo_camera_rounded,
                    title: 'Scan business card',
                    subtitle: 'Instant AI data extraction',
                    onTap: () async {
                      Get.back();
                      final images = await DocumentScannerService.scan(allowMultiple: false);
                      if (images.isNotEmpty) {
                        Get.toNamed(
                          Routes.scanResult,
                          arguments: <String, dynamic>{'images': images},
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _SheetTile(
                    icon: Icons.library_add_rounded,
                    title: 'Scan multiple cards',
                    subtitle: 'Batch process stack of cards',
                    onTap: () async {
                      Get.back();
                      final images = await DocumentScannerService.scan(allowMultiple: true);
                      if (images.isNotEmpty) {
                        Get.toNamed(
                          Routes.scanResult,
                          arguments: <String, dynamic>{'images': images},
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _SheetTile(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Import from QR',
                    subtitle: 'Open QR scanner camera',
                    onTap: () async {
                      Get.back();
                      try {
                        await _ensureQrSdkInitialized();
                        final configuration = BarcodeScannerScreenConfiguration()
                          ..useCase = SingleScanningMode();

                        final result = await ScanbotBarcodeSdk.barcode
                            .startScanner(configuration);
                        final uiResult = result.getOrNull();
                        final text = uiResult?.items.isNotEmpty == true
                            ? uiResult!.items.first.barcode.text.trim()
                            : '';
                        uiResult?.release();

                        if (text.isEmpty) {
                          ToastService.info('No QR code detected');
                          return;
                        }

                        ToastService.success('QR scanned');
                        // If you want to use `text` further (vCard parsing / import),
                        // this is the place to navigate to a form and prefill it.
                      } catch (e) {
                        ToastService.error('Unable to open QR scanner: $e');
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _SheetTile(
                    icon: Icons.edit_note_rounded,
                    title: 'Add Manually',
                    subtitle: 'Type details yourself',
                    onTap: () async {
                      if (!Get.isRegistered<HomeController>()) {
                        Get.back();
                        await Get.toNamed(Routes.manualEntry);
                        return;
                      }

                      final homeController = Get.find<HomeController>();
                      await homeController.fetchScanQuotaStatus();

                      if (homeController.canProceedManualEntry) {
                        Get.back();
                        final created = await Get.toNamed(Routes.manualEntry);
                        if (created == true) {
                          await homeController.refreshAllData();
                        }
                        return;
                      }

                      await ToastService.error('Your scan quota is full.');
                    },
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: AppColors.ink.withValues(alpha: 0.08),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: _SheetTile(
                icon: Icons.calendar_month_rounded,
                title: 'Create new event',
                subtitle: 'Add or Scan Cards under segment',
                onTap: () async {
                  final created = await CreateEventSheet.open();
                  if (created == true) {
                    Get.back(result: true);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
            color: AppColors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.primaryLight.withValues(alpha: 0.35),
                ),
                child: Icon(icon, color: AppColors.ink.withValues(alpha: 0.85)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: AppColors.ink.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}
