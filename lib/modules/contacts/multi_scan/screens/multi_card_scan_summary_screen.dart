import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/services/api.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/create_contact_service.dart';
import '../../../../core/services/http_sender_io.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/home_controller.dart';
import '../multi_card_scan_controller.dart';
import '../multi_card_scan_models.dart';

class MultiCardScanSummaryScreen extends StatefulWidget {
  const MultiCardScanSummaryScreen({super.key});

  @override
  State<MultiCardScanSummaryScreen> createState() =>
      _MultiCardScanSummaryScreenState();
}

class _MultiCardScanSummaryScreenState extends State<MultiCardScanSummaryScreen> {
  late final MultiCardScanController controller;

  bool _isSaving = false;
  int _savingIndex = -1;

  @override
  void initState() {
    super.initState();
    controller = Get.find<MultiCardScanController>();
  }

  Future<void> _saveAllContacts() async {
    if (_isSaving) return;

    final cards = controller.scannedCards.toList(growable: false);
    if (cards.isEmpty) {
      ToastService.error('No scanned cards to save');
      return;
    }

    final session = Get.find<AuthSessionService>();
    final token = session.accessToken.value.trim();
    if (token.isEmpty) {
      ToastService.error('Please sign in again');
      return;
    }

    final contactService = Get.find<CreateContactService>();
    final userId = await contactService.fetchProfileUserId();
    if (userId == null || userId.isEmpty) {
      ToastService.error('Could not load your user id');
      return;
    }

    if (mounted) {
      setState(() {
        _isSaving = true;
        _savingIndex = -1;
      });
    }

    try {
      var savedCount = 0;
      for (var index = 0; index < cards.length; index++) {
        if (mounted) {
          setState(() => _savingIndex = index);
        }
        final result = await _saveCard(
          card: cards[index],
          index: index,
          token: token,
          userId: userId,
          contactService: contactService,
        );
        if (!result.success) {
          ToastService.error(result.message ?? 'Failed to save scanned cards');
          return;
        }
        savedCount++;
      }

      ToastService.success(
        savedCount == 1
            ? '1 contact saved'
            : '$savedCount contacts saved successfully',
      );
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().refreshAllData();
      }
      Get.back(result: true, closeOverlays: false);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _savingIndex = -1;
        });
      }
    }
  }

  Future<_BatchSaveResult> _saveCard({
    required MultiScannedCard card,
    required int index,
    required String token,
    required String userId,
    required CreateContactService contactService,
  }) async {
    final imagePath = card.imagePath.trim();
    if (imagePath.isEmpty) {
      return _BatchSaveResult.failure(
        'Card ${index + 1}: missing business card image',
      );
    }

    final filePath =
        imagePath.startsWith('file://') ? imagePath.substring(7) : imagePath;
    final file = File(filePath);
    if (!await file.exists()) {
      return _BatchSaveResult.failure(
        'Card ${index + 1}: image file is missing',
      );
    }

    final fullNameRaw = card.fields.name.trim();
    final nameParts =
        fullNameRaw
            .split(RegExp(r'\s+'))
            .where((part) => part.trim().isNotEmpty)
            .toList();
    final first = nameParts.isNotEmpty ? nameParts.first : '';
    final last = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final designation = card.fields.designation.trim();
    final companyName = card.fields.company.trim();
    final website = (card.fields.website ?? '').trim();
    final email1 =
        card.fields.emails.isNotEmpty ? card.fields.emails.first.trim() : '';
    final email2 =
        card.fields.emails.length > 1 ? card.fields.emails[1].trim() : '';
    final phone1 =
        card.fields.phones.isNotEmpty ? card.fields.phones.first.trim() : '';
    final phone2 =
        card.fields.phones.length > 1 ? card.fields.phones[1].trim() : '';
    final address = (card.fields.address ?? '').trim();

    if (first.isEmpty) {
      return _BatchSaveResult.failure('Card ${index + 1}: first name is required');
    }
    if (companyName.isEmpty) {
      return _BatchSaveResult.failure(
        'Card ${index + 1}: company name is required',
      );
    }
    if (email1.isEmpty) {
      return _BatchSaveResult.failure(
        'Card ${index + 1}: primary email is required',
      );
    }
    if (!email1.contains('@')) {
      return _BatchSaveResult.failure(
        'Card ${index + 1}: please enter a valid email address',
      );
    }
    if (phone1.isEmpty || phone1.replaceAll(RegExp(r'\D'), '').isEmpty) {
      return _BatchSaveResult.failure(
        'Card ${index + 1}: mobile number is required',
      );
    }

    final base = ApiUrl.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base${ApiUrl.profileImagesUpload}');
    final uploadResp = await sendMultipartFormData(
      uri: uri,
      headers: <String, String>{
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      textFields: const <String, String>{'eventName': 'Direct Entry'},
      fileFieldName: 'file',
      file: file,
    );

    if (uploadResp.statusCode < 200 || uploadResp.statusCode >= 300) {
      return _BatchSaveResult.failure(
        'Card ${index + 1}: image upload failed (HTTP ${uploadResp.statusCode})',
      );
    }

    final responseBody = uploadResp.bodyText.trim();
    if (responseBody.isEmpty) {
      return _BatchSaveResult.failure(
        'Card ${index + 1}: empty upload response',
      );
    }

    dynamic decoded;
    try {
      decoded = json.decode(responseBody);
    } catch (_) {
      return _BatchSaveResult.failure(
        'Card ${index + 1}: invalid JSON from upload API',
      );
    }

    final publicUrl =
        decoded is Map
            ? (decoded['data'] is Map
                    ? (decoded['data']['cdnUrl']?.toString() ?? '')
                    : decoded['cdnUrl']?.toString() ?? '')
                .trim()
            : '';

    if (publicUrl.isEmpty) {
      return _BatchSaveResult.failure(
        'Card ${index + 1}: no image URL returned from server',
      );
    }

    final fullName =
        '$first $last'.trim().isEmpty
            ? 'Unnamed contact'
            : '$first $last'.trim();

    final createResult = await contactService.createContact(
      ownerUserId: userId,
      organizationId: null,
      createdBy: userId,
      fullName: fullName,
      source: 'scan',
      eventId: null,
      allowShareOrganization: false,
      firstName: first,
      lastName: last,
      designation: designation,
      companyName: companyName,
      email1: email1,
      email2: email2.isEmpty ? null : email2,
      phone1: phone1,
      phone2: phone2.isEmpty ? null : phone2,
      address: address,
      website: website,
      cardImgUrl: publicUrl,
      tags: const <String>['Lead', 'Follow-up'],
      profilePhotoUrl: null,
      scanLanguage: 'latin',
      rawOcrText: card.ocrText.trim().isEmpty ? null : card.ocrText.trim(),
    );

    if (!createResult.success) {
      return _BatchSaveResult.failure(
        createResult.message ?? 'Card ${index + 1}: failed to save contact',
      );
    }

    return const _BatchSaveResult.success();
  }

  @override
  Widget build(BuildContext context) {
    final cards = controller.scannedCards;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        title: const Text('Review & Save'),
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
                _SummaryHeaderCard(
                  title: '${controller.scannedCount} cards ready',
                  subtitle:
                      _isSaving && _savingIndex >= 0
                          ? 'Saving card ${_savingIndex + 1} of ${controller.scannedCount}'
                          : 'Review the list, then save everything in one step.',
                ),
                const SizedBox(height: 12),
                _SummaryStatsRow(
                  count: controller.scannedCount,
                  isSaving: _isSaving,
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SummaryListCard(
                          card: card,
                          index: index,
                          isSaving: _isSaving && _savingIndex == index,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _isSaving ? null : _saveAllContacts,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(_isSaving ? 'Saving Contacts...' : 'Save All Contacts'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryHeaderCard extends StatelessWidget {
  const _SummaryHeaderCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

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
    );
  }
}

class _SummaryStatsRow extends StatelessWidget {
  const _SummaryStatsRow({required this.count, required this.isSaving});

  final int count;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryStatTile(label: 'Cards', value: '$count'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryStatTile(
            label: 'Status',
            value: isSaving ? 'Saving' : 'Ready',
          ),
        ),
      ],
    );
  }
}

class _SummaryStatTile extends StatelessWidget {
  const _SummaryStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.48),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryListCard extends StatelessWidget {
  const _SummaryListCard({
    required this.card,
    required this.index,
    required this.isSaving,
  });

  final MultiScannedCard card;
  final int index;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Card ${index + 1}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.48),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isSaving)
                Text(
                  'Saving...',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.48),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
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
          if (card.fields.emails.isNotEmpty ||
              card.fields.phones.isNotEmpty ||
              card.fields.company.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (card.fields.emails.isNotEmpty)
                  _InfoChip(text: card.fields.emails.first),
                if (card.fields.phones.isNotEmpty)
                  _InfoChip(text: card.fields.phones.first),
                if (card.fields.company.trim().isNotEmpty)
                  _InfoChip(text: card.fields.company.trim()),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.ink.withValues(alpha: 0.70),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BatchSaveResult {
  const _BatchSaveResult._({required this.success, this.message});

  const _BatchSaveResult.success() : this._(success: true);

  const _BatchSaveResult.failure(String message)
    : this._(success: false, message: message);

  final bool success;
  final String? message;
}
