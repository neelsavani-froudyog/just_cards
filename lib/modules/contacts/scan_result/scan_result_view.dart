import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/services/document_scanner_service.dart';
import '../../../core/theme/app_colors.dart';
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

  final _fullNameCtrl = TextEditingController(text: 'Jonathan Henderson');
  final _phoneCtrl = TextEditingController(text: '+1 (555) 012-3456');
  final _mobileCtrl = TextEditingController(text: '+1 (555) 017-555-5555');
  final _emailCtrl = TextEditingController(text: 'jon@technova.com');
  final _companyCtrl = TextEditingController(text: 'TechNova Solutions');
  final _jobTitleCtrl = TextEditingController(text: 'Senior Design Lead');
  final _eventCtrl = TextEditingController(text: 'Electronica India 2026');
  final _segmentCtrl = TextEditingController(text: 'Warm Leads');

  final List<String> _selectedTags = <String>['Lead', 'Follow-up'];
  final List<String> _suggestedTags = <String>['Priority', 'VIP', 'Prospect'];

  bool _shareWithOrganization = false;

  @override
  void initState() {
    super.initState();
    final args =
        Get.arguments as Map<String, dynamic>? ?? const <String, dynamic>{};
    final imagesArg = args['images'];
    _images = (imagesArg is List) ? imagesArg.cast<String>() : const <String>[];
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

  Future<void> _saveDraft() async {
    Get.snackbar('Draft', 'Saved as draft');
  }

  Future<void> _openAdvancedSettings() async {
    Get.snackbar('Advanced Settings', 'Coming soon');
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 22,
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.darkGrey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 19, color: AppColors.darkGrey),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.darkGrey,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.62),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: controller,
          hint: hint,
          enabled: _isEditing || readOnly,
          readOnly: readOnly || !_isEditing,
          filled: true,
          fillColor: const Color(0xFFF7F8FB),
          borderColor: AppColors.ink.withValues(alpha: 0.08),
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          suffixIcon: suffixIcon == null
              ? null
              : Icon(
                  suffixIcon,
                  size: 18,
                  color: AppColors.ink.withValues(alpha: 0.45),
                ),
        ),
      ],
    );
  }

  Widget _topSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.darkGrey,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'OCR processed successfully',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check the extracted contact details and save when everything looks right.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.64),
                    height: 1.35,
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
                            : Icons.videocam_outlined,
                      ),
                      label: Text(_isRescanning ? 'Retaking...' : 'Retake'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.darkGrey.withValues(
                          alpha: 0.08,
                        ),
                        foregroundColor: AppColors.darkGrey,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                      label: Text(_isEditing ? 'Editing' : 'Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkGrey,
                        side: BorderSide(
                          color: AppColors.darkGrey.withValues(alpha: 0.16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 128,
            height: 104,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryLight.withValues(alpha: 0.95),
                  const Color(0xFFFFD8C3),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: _buildCardPreview(),
          ),
        ],
      ),
    );
  }

  Widget _tagChips() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ..._selectedTags.map(
          (tag) => InkWell(
            onTap: () => _toggleTag(tag),
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.darkGrey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tag,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.darkGrey,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.darkGrey.withValues(alpha: 0.72),
                  ),
                ],
              ),
            ),
          ),
        ),
        InkWell(
          onTap: _addSuggestedTag,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.darkGrey.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: AppColors.darkGrey.withValues(alpha: 0.72),
                ),
                const SizedBox(width: 6),
                Text(
                  'Add Tag',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.darkGrey.withValues(alpha: 0.76),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isSaving ? null : _saveContact,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.darkGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_outlined, color: AppColors.white),
                    const SizedBox(width: 10),
                    Text(
                      _isSaving ? 'Saving...' : 'Save Contact',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _saveDraft,
                    icon: const Icon(Icons.drafts_outlined),
                    label: const Text('Save Draft'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.darkGrey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _openAdvancedSettings,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Advanced'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.darkGrey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text('Review Scan'),
        actions: [
          IconButton(
            onPressed: _openAdvancedSettings,
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                          ),
                          const SizedBox(height: 14),
                          _field(
                            label: 'Email Address',
                            controller: _emailCtrl,
                            hint: 'Email address',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _section(
                      icon: Icons.business_rounded,
                      title: 'Organization',
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _field(
                              label: 'Company',
                              controller: _companyCtrl,
                              hint: 'Company name',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              label: 'Job Title',
                              controller: _jobTitleCtrl,
                              hint: 'Job title',
                            ),
                          ),
                        ],
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
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.ink.withValues(alpha: 0.62),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _tagChips(),
                          const SizedBox(height: 16),
                          _field(
                            label: 'Segment',
                            controller: _segmentCtrl,
                            hint: 'Select segment',
                            readOnly: true,
                            suffixIcon: Icons.keyboard_arrow_down_rounded,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FB),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.ink.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Share with my organisation',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppColors.darkGrey,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                Switch(
                                  value: _shareWithOrganization,
                                  activeThumbColor: AppColors.white,
                                  activeTrackColor: AppColors.darkGrey,
                                  inactiveThumbColor: AppColors.white,
                                  inactiveTrackColor: AppColors.ink.withValues(
                                    alpha: 0.18,
                                  ),
                                  onChanged: (value) {
                                    setState(
                                      () => _shareWithOrganization = value,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }
}
