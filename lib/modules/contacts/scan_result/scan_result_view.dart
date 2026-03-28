import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/parse_card_response.dart';
import '../../../core/services/document_scanner_service.dart';
import '../../../core/services/mlkit_text_recognition_service.dart';
import '../../../core/services/parse_card_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/business_card_ocr_parser.dart';
import '../../../widgets/custom_text_field.dart';

class ScanResultView extends StatefulWidget {
  const ScanResultView({super.key});

  @override
  State<ScanResultView> createState() => _ScanResultViewState();
}

class _ScanResultViewState extends State<ScanResultView> {
  List<String> _images = const <String>[];

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isRescanning = false;

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _eventCtrl = TextEditingController();
  final _segmentCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final List<String> _selectedTags = <String>['Lead', 'Follow-up'];
  final List<String> _suggestedTags = <String>['Priority', 'VIP', 'Prospect'];

  bool _shareWithOrganization = false;
  bool _isOcrLoading = false;

  @override
  void initState() {
    super.initState();
    final args =
        Get.arguments as Map<String, dynamic>? ?? const <String, dynamic>{};
    final imagesArg = args['images'];
    _images = (imagesArg is List) ? imagesArg.cast<String>() : const <String>[];
    _isOcrLoading = _images.isNotEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_images.isNotEmpty) {
        _runOcrOnFirstImage();
      }
    });
  }

  void _applyParsed(ParsedBusinessCardFields parsed) {
    _fullNameCtrl.text = parsed.fullName;
    _phoneCtrl.text = parsed.primaryPhone;
    _mobileCtrl.text = parsed.secondaryPhone;
    _emailCtrl.text = parsed.email;
    _companyCtrl.text = parsed.company;
    _jobTitleCtrl.text = parsed.jobTitle;
    _websiteCtrl.text = '';
    _addressCtrl.text = '';
  }

  void _applyApiFields(ParseCardFields f) {
    _fullNameCtrl.text = f.name;
    _jobTitleCtrl.text = f.designation;
    _companyCtrl.text = f.company;
    _emailCtrl.text = f.emails.isNotEmpty ? f.emails.join(', ') : '';
    if (f.phones.isNotEmpty) {
      _phoneCtrl.text = f.phones.first;
      _mobileCtrl.text = f.phones.length > 1 ? f.phones[1] : '';
    } else {
      _phoneCtrl.text = '';
      _mobileCtrl.text = '';
    }
    _websiteCtrl.text = f.website ?? '';
    _addressCtrl.text = f.address ?? '';
  }

  void _clearAllExtractedFields() {
    _applyParsed(ParsedBusinessCardFields.empty);
  }

  Future<void> _runOcrOnFirstImage() async {
    if (_images.isEmpty) {
      if (mounted) setState(() => _isOcrLoading = false);
      return;
    }
    if (mounted) setState(() => _isOcrLoading = true);
    try {
      // 1) On-device OCR → plain text
      final raw = await MlKitTextRecognitionService.recognizeLatinFromFilePath(
        _images.first,
      );
      if (kDebugMode) {
        debugPrint('OCR raw text:\n$raw');
      }

      if (raw.trim().isEmpty) {
        if (mounted) {
          Get.snackbar('Scan', 'No text found on card');
          _clearAllExtractedFields();
        }
        return;
      }

      // 2) Backend: POST /scan-quota/parse-card { "ocr_text": "..." }
      ParseCardService parseService;
      try {
        parseService = Get.find<ParseCardService>();
      } catch (_) {
        Get.put<ParseCardService>(ParseCardService(), permanent: true);
        parseService = Get.find<ParseCardService>();
      }

      final outcome = await parseService.parseCard(raw);

      if (!mounted) return;

      final apiFields = outcome.response?.data?.fields;
      if (outcome.success && apiFields != null) {
        _applyApiFields(apiFields);
      } else {
        final err = outcome.errorMessage;
        if (err != null &&
            err.isNotEmpty &&
            err != 'Session expired') {
          Get.snackbar('Card parse', err);
        }
        final parsed = BusinessCardOcrParser.parse(raw);
        _applyParsed(parsed);
      }
    } catch (e, st) {
      debugPrint('OCR / parse flow failed: $e\n$st');
      if (mounted) {
        Get.snackbar('Scan', 'Could not read text from image');
      }
    } finally {
      if (mounted) {
        setState(() => _isOcrLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _companyCtrl.dispose();
    _jobTitleCtrl.dispose();
    _eventCtrl.dispose();
    _segmentCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      Get.snackbar('Contact', 'Saved');
      Get.back();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _rescanCard() async {
    if (_isRescanning) return;
    setState(() => _isRescanning = true);
    try {
      final images = await DocumentScannerService.scan(allowMultiple: false);
      setState(() {
        _images = images;
      });
      if (images.isNotEmpty) {
        await _runOcrOnFirstImage();
      } else {
        _clearAllExtractedFields();
      }
      Get.snackbar(
        'Rescan',
        images.isNotEmpty ? 'New image captured' : 'No image captured',
      );
    } finally {
      if (mounted) {
        setState(() => _isRescanning = false);
      }
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  void _addSuggestedTag() {
    final remaining = _suggestedTags.where(
      (tag) => !_selectedTags.contains(tag),
    );
    if (remaining.isEmpty) {
      Get.snackbar('Tags', 'No more suggested tags');
      return;
    }
    setState(() => _selectedTags.add(remaining.first));
  }

  Widget _buildCardPreview() {
    final path = _images.isNotEmpty ? _images.first : '';
    if (path.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight.withValues(alpha: 0.95),
              const Color(0xFFFFD8C3),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.credit_card_rounded,
          size: 44,
          color: AppColors.darkGrey.withValues(alpha: 0.80),
        ),
      );
    }

    final isHttp = path.startsWith('http');
    final isFile = path.startsWith('/') || path.startsWith('file://');

    Widget child;
    if (isHttp) {
      child = Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: AppColors.fieldFill),
      );
    } else if (isFile) {
      child = Image.file(
        File(path.startsWith('file://') ? path.substring(7) : path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: AppColors.fieldFill),
      );
    } else {
      try {
        final bytes = base64Decode(path);
        child = Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: AppColors.fieldFill),
        );
      } catch (_) {
        child = Container(color: AppColors.fieldFill);
      }
    }

    return ClipRRect(borderRadius: BorderRadius.circular(20), child: child);
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkGrey.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGrey.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.darkGrey.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: AppColors.darkGrey),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    IconData? suffixIcon,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      inputType: inputType,
      maxLines: maxLines,
      enabled: _isEditing || readOnly,
      readOnly: readOnly || !_isEditing,
      filled: true,
      fillColor: const Color(0xFFF5F7FB),
      borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      cursorColor: AppColors.darkGrey.withValues(alpha: 0.65),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.darkGrey.withValues(alpha: 0.72),
            fontWeight: FontWeight.w800,
          ),
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.darkGrey.withValues(alpha: 0.40),
            fontWeight: FontWeight.w600,
          ),
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.darkGrey.withValues(alpha: 0.92),
            fontWeight: FontWeight.w700,
          ),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(
              suffixIcon,
              color: AppColors.darkGrey.withValues(alpha: 0.55),
            ),
    );
  }

  Widget _scanPreviewThumbnail({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withValues(alpha: 0.95),
            const Color(0xFFFFD8C3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _buildCardPreview(),
    );
  }

  Widget _topSummaryCard() {
    final theme = Theme.of(context);
    final muted = AppColors.darkGrey.withValues(alpha: 0.55);

    Widget heroCopy() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.darkGrey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: AppColors.darkGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  'REVIEW SCAN',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'OCR processed successfully',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.darkGrey,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check the extracted details and save when everything looks right.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.tonalIcon(
                onPressed: _isRescanning ? null : _rescanCard,
                icon: Icon(
                  _isRescanning
                      ? Icons.hourglass_top_rounded
                      : Icons.photo_camera_outlined,
                ),
                label: Text(_isRescanning ? 'Retaking...' : 'Retake'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.darkGrey.withValues(alpha: 0.08),
                  foregroundColor: AppColors.darkGrey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _isEditing = !_isEditing),
                icon: Icon(
                  _isEditing
                      ? Icons.check_circle_outline
                      : Icons.edit_outlined,
                ),
                label: Text(_isEditing ? 'Done' : 'Edit fields'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkGrey,
                  side: BorderSide(
                    color: AppColors.darkGrey.withValues(alpha: 0.16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 520;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.darkGrey.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkGrey.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: _scanPreviewThumbnail(
                        width: constraints.maxWidth.clamp(0, 280),
                        height: 132,
                      ),
                    ),
                    const SizedBox(height: 18),
                    heroCopy(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: heroCopy()),
                    const SizedBox(width: 14),
                    _scanPreviewThumbnail(width: 132, height: 108),
                  ],
                ),
        );
      },
    );
  }

  Widget _tagChips() {
    final theme = Theme.of(context);

    Widget chip(String text, {required bool selected}) {
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: InkWell(
          onTap: () => _toggleTag(text),
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.darkGrey.withValues(alpha: 0.12)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AppColors.darkGrey.withValues(alpha: 0.22)
                    : AppColors.darkGrey.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.darkGrey.withValues(
                      alpha: selected ? 0.92 : 0.72,
                    ),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.darkGrey.withValues(alpha: 0.60),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      children: [
        ..._selectedTags.map((t) => chip(t, selected: true)),
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: InkWell(
            onTap: _addSuggestedTag,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.darkGrey.withValues(alpha: 0.14),
                ),
              ),
              child: Text(
                '+ Add Tag',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.darkGrey.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _shareWithOrganisationRow() {
    final theme = Theme.of(context);
    const activeGreen = Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkGrey.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share with my organisation',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Allow team members to view this contact',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.darkGrey.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _shareWithOrganization,
            activeColor: activeGreen,
            onChanged: (value) {
              setState(() => _shareWithOrganization = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.darkGrey.withValues(alpha: 0.08)),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveContact,
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(
              _isSaving ? 'Saving...' : 'Save Contact',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGrey,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.darkGrey,
          onPressed: () => Get.back(),
        ),
        title: const Text('Review Scan'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.darkGrey,
              fontWeight: FontWeight.w800,
            ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _topSummaryCard(),
                        const SizedBox(height: 18),
                        _section(
                          icon: Icons.person_rounded,
                          title: 'Contact Details',
                          child: Column(
                            children: [
                              _field(
                                label: 'Full Name',
                                controller: _fullNameCtrl,
                                hint: 'Full name',
                              ),
                              const SizedBox(height: 14),
                              _field(
                                label: 'Phone Number',
                                controller: _phoneCtrl,
                                hint: 'Phone number',
                                inputType: TextInputType.phone,
                              ),
                              const SizedBox(height: 14),
                              _field(
                                label: 'Email Address',
                                controller: _emailCtrl,
                                hint: 'Email address',
                                inputType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),
                              _field(
                                label: 'Website',
                                controller: _websiteCtrl,
                                hint: 'Website',
                                inputType: TextInputType.url,
                              ),
                              const SizedBox(height: 14),
                              _field(
                                label: 'Address',
                                controller: _addressCtrl,
                                hint: 'Address',
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _section(
                          icon: Icons.business_rounded,
                          title: 'Organization',
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final stack = constraints.maxWidth < 420;
                              final company = _field(
                                label: 'Company',
                                controller: _companyCtrl,
                                hint: 'Company name',
                              );
                              final job = _field(
                                label: 'Job Title',
                                controller: _jobTitleCtrl,
                                hint: 'Job title',
                              );
                              if (stack) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    company,
                                    const SizedBox(height: 14),
                                    job,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: company),
                                  const SizedBox(width: 12),
                                  Expanded(child: job),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        _section(
                          icon: Icons.sell_rounded,
                          title: 'Event & Tags',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _field(
                                label: 'Event',
                                controller: _eventCtrl,
                                hint: 'Select event',
                                readOnly: true,
                                suffixIcon: Icons.keyboard_arrow_down_rounded,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Tags',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: AppColors.darkGrey.withValues(
                                        alpha: 0.72,
                                      ),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              _tagChips(),
                              const SizedBox(height: 14),
                              _field(
                                label: 'Segment',
                                controller: _segmentCtrl,
                                hint: 'Select segment',
                                readOnly: true,
                                suffixIcon: Icons.keyboard_arrow_down_rounded,
                              ),
                              const SizedBox(height: 14),
                              _shareWithOrganisationRow(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _section(
                          icon: Icons.call_outlined,
                          title: 'Additional Contact',
                          child: _field(
                            label: 'Secondary Number',
                            controller: _mobileCtrl,
                            hint: 'Secondary phone',
                            inputType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isOcrLoading)
                    Positioned.fill(
                      child: ColoredBox(
                        color: AppColors.white.withValues(alpha: 0.72),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: AppColors.darkGrey,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Reading business card…',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: AppColors.darkGrey,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }
}
