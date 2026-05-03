import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/services/document_scanner_service.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_routes.dart';
import '../multi_card_scan_controller.dart';
import '../multi_card_scan_models.dart';

class MultiCardScannerScreen extends StatefulWidget {
  const MultiCardScannerScreen({super.key});

  @override
  State<MultiCardScannerScreen> createState() => _MultiCardScannerScreenState();
}

class _MultiCardScannerScreenState extends State<MultiCardScannerScreen> {
  final MultiCardScanController controller =
      Get.find<MultiCardScanController>();

  bool _isLoopRunning = false;
  String _status = 'Preparing camera scanner...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runScanLoop();
    });
  }

  Future<void> _runScanLoop() async {
    if (_isLoopRunning || !mounted) return;

    _isLoopRunning = true;
    try {
      while (mounted) {
        setState(() {
          _status = 'Opening scanner...';
        });

        final images = await DocumentScannerService.scan(allowMultiple: false);
        if (!mounted) return;

        if (images.isEmpty) {
          setState(() {
            _status =
                controller.scannedCount == 0
                    ? 'Camera scanner closed. Retry to continue.'
                    : 'Scanner closed. You can finish or keep scanning.';
          });
          break;
        }

        setState(() {
          _status = 'Reading card details...';
        });

        final outcome = await controller.processScannedImage(images.first);
        if (!mounted) return;

        if (outcome.isDuplicate) {
          await HapticFeedback.selectionClick();
          await ToastService.error(
            outcome.message ?? 'Duplicate card skipped.',
          );
          continue;
        }

        if (!outcome.added || outcome.card == null) {
          await ToastService.error(
            outcome.message ?? 'Unable to process this card. Please retry.',
          );
          setState(() {
            _status = 'Processing failed. Retry when ready.';
          });
          break;
        }

        await HapticFeedback.mediumImpact();
        final action = await Get.toNamed(
          Routes.multiCardScanResult,
          arguments: <String, dynamic>{'cardId': outcome.card!.id},
        );
        if (!mounted) return;

        if (action == MultiCardScanAction.scanNext) {
          continue;
        }

        if (action == MultiCardScanAction.finishScanning) {
          await Get.toNamed(Routes.multiCardScanSummary);
          if (!mounted) return;
          Get.back(result: controller.scannedCards.toList(growable: false));
          return;
        }

        setState(() {
          _status = 'Scanning paused. Tap retry to resume.';
        });
        break;
      }
    } finally {
      _isLoopRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCards = controller.scannedCount > 0;
    final isBusy = _isLoopRunning || controller.isProcessing.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        title: const Text('Scan Cards'),
        backgroundColor: const Color(0xFFF7F7F5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SimpleHeaderCard(
                  title:
                      hasCards
                          ? '${controller.scannedCount} cards scanned'
                          : 'Ready to scan cards',
                  subtitle: _status,
                  trailing:
                      isBusy
                          ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            hasCards ? 'In progress' : 'Start',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.ink.withValues(alpha: 0.58),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                ),
                const SizedBox(height: 12),
                if (controller.latestCard != null) ...[
                  const SizedBox(height: 12),
                  _MinimalLatestCard(card: controller.latestCard!),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: _isLoopRunning ? null : _runScanLoop,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    hasCards ? 'Scan Another Card' : 'Start Scanning',
                  ),
                ),
                if (hasCards) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () async {
                      await Get.toNamed(Routes.multiCardScanSummary);
                      if (mounted) {
                        Get.back(
                          result: controller.scannedCards.toList(
                            growable: false,
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      side: BorderSide(
                        color: AppColors.ink.withValues(alpha: 0.12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text('Review & Save (${controller.scannedCount})'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleHeaderCard extends StatelessWidget {
  const _SimpleHeaderCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: trailing,
          ),
        ],
      ),
    );
  }
}

class _StepsRow extends StatelessWidget {
  const _StepsRow({required this.activeStep});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StepTile(label: 'Scan', active: activeStep >= 1)),
        const SizedBox(width: 8),
        Expanded(child: _StepTile(label: 'Review', active: activeStep >= 2)),
        const SizedBox(width: 8),
        Expanded(child: _StepTile(label: 'Save', active: activeStep >= 3)),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color:
            active ? AppColors.white : AppColors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.ink.withValues(alpha: active ? 0.10 : 0.05),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: AppColors.ink.withValues(alpha: active ? 0.88 : 0.42),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MinimalLatestCard extends StatelessWidget {
  const _MinimalLatestCard({required this.card});

  final MultiScannedCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest card',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.50),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            card.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (card.subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              card.subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.62),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.ink.withValues(alpha: 0.62),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
