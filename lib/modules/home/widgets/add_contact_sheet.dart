import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/document_scanner_service.dart';
import '../../events/create/create_event_sheet.dart';

class AddContactSheet extends StatelessWidget {
  const AddContactSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
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
                        Get.snackbar('Scan complete', '${images.length} page(s) captured');
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
                        Get.snackbar('Scan complete', '${images.length} page(s) captured');
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _SheetTile(
                    icon: Icons.qr_code_scanner_rounded,
                    title: 'Import from QR',
                    subtitle: null,
                    onTap: () => Get.back(),
                  ),
                  const SizedBox(height: 10),
                  _SheetTile(
                    icon: Icons.edit_note_rounded,
                    title: 'Add Manually',
                    subtitle: 'Type details yourself',
                    onTap: () => Get.back(),
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
                onTap: () {
                  // Get.back();
                  CreateEventSheet.open();
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
            color: Colors.white,
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

