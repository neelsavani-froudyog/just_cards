import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/models/parse_card_response.dart';
import '../../../../core/services/api.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/custom_search_dropdown.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../home/home_events_model.dart';
import '../../manual_entry/add_tag_dialog.dart';
import '../../manual_entry/organization_simple_model.dart';
import '../multi_card_scan_controller.dart';
import '../multi_card_scan_models.dart';

class _ParsedPhoneData {
  const _ParsedPhoneData({required this.nationalNumber, required this.isoCode});

  final String nationalNumber;
  final String isoCode;
}

class _DashedPillBorderPainter extends CustomPainter {
  const _DashedPillBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;
  final double strokeWidth = 1.4;
  final double dashLength = 6;
  final double dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedPillBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        radius != oldDelegate.radius ||
        strokeWidth != oldDelegate.strokeWidth ||
        dashLength != oldDelegate.dashLength ||
        dashGap != oldDelegate.dashGap;
  }
}

class MultiCardScanResultScreen extends StatefulWidget {
  const MultiCardScanResultScreen({super.key});

  @override
  State<MultiCardScanResultScreen> createState() =>
      _MultiCardScanResultScreenState();
}

class _MultiCardScanResultScreenState extends State<MultiCardScanResultScreen> {
  late final MultiCardScanController _scanController;
  late final ApiService _apiService;
  late final CountryService _countryService;
  late final String _cardId;

  MultiScannedCard? _card;

  bool _isEditing = false;
  bool _isOrganizationsLoading = false;
  bool _isEventsLoading = false;

  final List<String> _salutations = <String>['Mr.', 'Ms.', 'Mrs.', 'Dr.'];
  String _selectedSalutation = 'Mr.';

  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _secondaryEmailCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final List<String> _selectedTags = <String>['Lead', 'Follow-up'];
  bool _shareWithOrganization = false;
  String _phone1CountryIso = 'IN';
  String _phone2CountryIso = 'IN';

  static const String _noneOrganization = 'Select organization';
  final List<String> _organizations = <String>[_noneOrganization];
  String _selectedOrganization = _noneOrganization;
  final List<OrganizationOption> _organizationOptions = <OrganizationOption>[];

  static const String _noneEvent = 'Select event';
  final List<String> _events = <String>[_noneEvent];
  String _selectedEvent = _noneEvent;
  String? _selectedEventId;
  final List<HomeEventItem> _eventOptions = <HomeEventItem>[];

  @override
  void initState() {
    super.initState();
    _scanController = Get.find<MultiCardScanController>();
    _apiService = Get.find<ApiService>();
    _countryService = CountryService();

    final args =
        (Get.arguments as Map<dynamic, dynamic>?) ?? <dynamic, dynamic>{};
    _cardId = args['cardId']?.toString() ?? '';
    _card = _scanController.findById(_cardId);
    if (_card != null) {
      _applyParsedFields(_card!.fields);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_fetchOrganizations());
      unawaited(_fetchAllEvents());
    });
  }

  HomeEventItem? _findEventById(String id) {
    for (final item in _eventOptions) {
      if (item.id.trim() == id) return item;
    }
    return null;
  }

  void _openCountryPicker({required bool isPhone1}) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: const <String>['IN', 'US', 'NZ'],
      searchAutofocus: false,
      countryListTheme: const CountryListThemeData(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      onSelect: (Country c) {
        if (!mounted) return;
        setState(() {
          if (isPhone1) {
            _phone1CountryIso = c.countryCode;
          } else {
            _phone2CountryIso = c.countryCode;
          }
        });
      },
    );
  }

  String _normalizeParsedPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.length <= 10) return digits;
    return digits.substring(digits.length - 10);
  }

  _ParsedPhoneData _parsePhoneWithCountry(String raw, String fallbackIso) {
    final value = raw.trim();
    if (value.isEmpty) {
      return _ParsedPhoneData(nationalNumber: '', isoCode: fallbackIso);
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return _ParsedPhoneData(nationalNumber: '', isoCode: fallbackIso);
    }

    Country? bestMatch;
    var bestMatchLength = 0;
    for (final country in _countryService.getAll()) {
      final codeDigits = country.phoneCode.replaceAll(RegExp(r'\D'), '');
      if (codeDigits.isEmpty) continue;
      if (digits.startsWith(codeDigits) &&
          codeDigits.length > bestMatchLength) {
        bestMatch = country;
        bestMatchLength = codeDigits.length;
      }
    }

    return _ParsedPhoneData(
      nationalNumber: _normalizeParsedPhone(value),
      isoCode: bestMatch?.countryCode ?? fallbackIso,
    );
  }

  void _applyParsedFields(ParseCardFields fields) {
    final email1 = fields.emails.isNotEmpty ? fields.emails.first.trim() : '';
    final email2 = fields.emails.length > 1 ? fields.emails[1].trim() : '';
    final phone1 =
        fields.phones.isNotEmpty
            ? _parsePhoneWithCountry(
              fields.phones.first.trim(),
              _phone1CountryIso,
            )
            : _ParsedPhoneData(nationalNumber: '', isoCode: _phone1CountryIso);
    final phone2 =
        fields.phones.length > 1
            ? _parsePhoneWithCountry(fields.phones[1].trim(), _phone2CountryIso)
            : _ParsedPhoneData(nationalNumber: '', isoCode: _phone2CountryIso);

    _fullNameCtrl.text = fields.name.trim();
    _jobTitleCtrl.text = fields.designation.trim();
    _companyCtrl.text = fields.company.trim();
    _emailCtrl.text = email1;
    _secondaryEmailCtrl.text = email2;
    _phone1CountryIso = phone1.isoCode;
    _phone2CountryIso = phone2.isoCode;
    _phoneCtrl.text = phone1.nationalNumber;
    _mobileCtrl.text = phone2.nationalNumber;
    _websiteCtrl.text = (fields.website ?? '').trim();
    _addressCtrl.text = (fields.address ?? '').trim();
  }

  void _persistEdits() {
    final card = _card;
    if (card == null) return;

    final emails =
        <String>[
          _emailCtrl.text.trim(),
          _secondaryEmailCtrl.text.trim(),
        ].where((value) => value.isNotEmpty).toList();

    final phones =
        <String>[
          _phoneCtrl.text.trim(),
          _mobileCtrl.text.trim(),
        ].where((value) => value.isNotEmpty).toList();

    final updatedFields = card.fields.copyWith(
      name: _fullNameCtrl.text.trim(),
      designation: _jobTitleCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
      emails: emails,
      phones: phones,
      website: _websiteCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    );

    _scanController.updateCardFields(card.id, updatedFields);
    _card = _scanController.findById(card.id);
  }

  Future<void> _fetchOrganizations() async {
    if (_isOrganizationsLoading) return;
    if (mounted) setState(() => _isOrganizationsLoading = true);
    try {
      await _apiService.getRequest(
        url: ApiUrl.profileOrganizationsSimple,
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) return;

          final parsed = OrganizationsSimpleResponse.fromJson(raw);
          if (!parsed.ok || !mounted) return;

          _organizationOptions
            ..clear()
            ..addAll(parsed.data);

          setState(() {
            _organizations
              ..clear()
              ..add(_noneOrganization)
              ..addAll(
                _organizationOptions
                    .map((item) => item.name.trim())
                    .where((name) => name.isNotEmpty),
              );
          });
        },
        onError: (_) {},
      );
    } finally {
      if (mounted) setState(() => _isOrganizationsLoading = false);
    }
  }

  Future<void> _fetchAllEvents() async {
    if (_isEventsLoading) return;
    if (mounted) setState(() => _isEventsLoading = true);
    try {
      await _apiService.getRequest(
        url: ApiUrl.events,
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) return;

          final parsed = HomeEventsResponse.fromJson(raw);
          if (!parsed.ok || !mounted) return;

          _eventOptions
            ..clear()
            ..addAll(parsed.data);

          setState(() {
            _events
              ..clear()
              ..add(_noneEvent)
              ..addAll(
                _eventOptions
                    .map((item) => item.title.trim())
                    .where((title) => title.isNotEmpty),
              );
          });
        },
        onError: (_) {},
      );
    } finally {
      if (mounted) setState(() => _isEventsLoading = false);
    }
  }

  Future<void> _fetchEventsByOrganization(String? organizationId) async {
    final orgId = organizationId?.trim();
    if (orgId == null || orgId.isEmpty) {
      await _fetchAllEvents();
      return;
    }

    if (_isEventsLoading) return;
    if (mounted) setState(() => _isEventsLoading = true);
    try {
      await _apiService.postRequest(
        url: ApiUrl.eventsByOrganization,
        data: <String, dynamic>{'p_organization_id': orgId},
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final raw = payload['response'];
          if (raw is! Map<String, dynamic>) return;

          final parsed = HomeEventsResponse.fromJson(raw);
          if (!parsed.ok || !mounted) return;

          _eventOptions
            ..clear()
            ..addAll(parsed.data);

          setState(() {
            _events
              ..clear()
              ..add(_noneEvent)
              ..addAll(
                _eventOptions
                    .map((item) => item.title.trim())
                    .where((title) => title.isNotEmpty),
              );

            final current = _selectedEventId?.trim();
            if (current != null && current.isNotEmpty) {
              final match = _findEventById(current);
              if (match != null) {
                _selectedEvent = match.title.trim();
              } else {
                _selectedEvent = _noneEvent;
                _selectedEventId = null;
              }
            }
          });
        },
        onError: (_) {},
      );
    } finally {
      if (mounted) setState(() => _isEventsLoading = false);
    }
  }

  void _setOrganization(String? value) {
    FocusScope.of(context).unfocus();
    if (value == null) return;

    if (value == _noneOrganization) {
      setState(() {
        _selectedOrganization = value;
        _shareWithOrganization = false;
      });
      unawaited(_fetchAllEvents());
      return;
    }

    OrganizationOption? selected;
    for (final item in _organizationOptions) {
      if (item.name == value) {
        selected = item;
        break;
      }
    }

    setState(() {
      _selectedOrganization = value;
      _shareWithOrganization = true;
    });
    unawaited(_fetchEventsByOrganization(selected?.id));
  }

  void _setEvent(String? value) {
    FocusScope.of(context).unfocus();
    if (value == null) return;
    if (value == _noneEvent) {
      setState(() {
        _selectedEvent = value;
        _selectedEventId = null;
      });
      return;
    }

    HomeEventItem? selected;
    for (final item in _eventOptions) {
      if (item.title == value) {
        selected = item;
        break;
      }
    }
    setState(() {
      _selectedEvent = value;
      _selectedEventId = selected?.id.trim();
    });
  }

  Future<void> _openAddTagDialog() async {
    await Get.dialog<void>(
      AddTagDialog(selectedTags: _selectedTags),
      barrierDismissible: true,
    );
    if (mounted) setState(() {});
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

  Widget _salutationDropdown() {
    return CustomSearchDropdown<String>(
      items: _salutations,
      selectedItem: _selectedSalutation,
      hintText: 'Select salutation',
      label: 'Salutation',
      showSearchBox: false,
      itemAsString: (item) => item,
      onChanged: (value) {
        if (value == null) return;
        FocusScope.of(context).unfocus();
        setState(() => _selectedSalutation = value);
      },
      bgColor: const Color(0xFFF5F7FB),
      borderColor: AppColors.ink.withValues(alpha: 0.10),
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      showShadow: false,
    );
  }

  Widget _organizationDropdown() {
    return CustomSearchDropdown<String>(
      items: _organizations,
      selectedItem: _selectedOrganization,
      hintText: 'Select organization',
      label: 'Add to Organisation',
      showSearchBox: false,
      enabled: !_isOrganizationsLoading,
      itemAsString: (item) => item,
      onChanged: _setOrganization,
      bgColor: const Color(0xFFF5F7FB),
      borderColor: AppColors.ink.withValues(alpha: 0.10),
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      showShadow: false,
    );
  }

  Widget _eventDropdown() {
    return CustomSearchDropdown<String>(
      items: _events,
      selectedItem: _selectedEvent,
      hintText: 'Select event',
      label: 'Associate with Event',
      showSearchBox: false,
      enabled: !_isEventsLoading,
      itemAsString: (item) => item,
      onChanged: _setEvent,
      bgColor: const Color(0xFFF5F7FB),
      borderColor: AppColors.ink.withValues(alpha: 0.10),
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      showShadow: false,
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      inputType: inputType,
      maxLines: maxLines,
      enabled: _isEditing,
      readOnly: !_isEditing,
      filled: true,
      fillColor: const Color(0xFFF5F7FB),
      borderColor: AppColors.ink.withValues(alpha: 0.10),
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      cursorColor: AppColors.ink.withValues(alpha: 0.65),
      labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.ink.withValues(alpha: 0.72),
        fontWeight: FontWeight.w800,
      ),
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.ink.withValues(alpha: 0.40),
        fontWeight: FontWeight.w600,
      ),
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.ink.withValues(alpha: 0.92),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _phoneFieldWithCountry({
    required String label,
    required TextEditingController textController,
    required String hint,
    required bool isPhone1,
  }) {
    final theme = Theme.of(context);
    final iso = isPhone1 ? _phone1CountryIso : _phone2CountryIso;
    final country = Country.tryParse(iso) ?? Country.parse('IN');
    final isIndiaCode = country.phoneCode == '91';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.72),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap:
                    _isEditing
                        ? () => _openCountryPicker(isPhone1: isPhone1)
                        : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.ink.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        country.flagEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+${country.phoneCode}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.ink.withValues(alpha: 0.55),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextField(
                controller: textController,
                hint: hint,
                inputType: TextInputType.phone,
                maxLength: isIndiaCode ? 10 : null,
                enabled: _isEditing,
                readOnly: !_isEditing,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                cursorColor: AppColors.ink.withValues(alpha: 0.65),
                fillColor: const Color(0xFFF5F7FB),
                borderColor: AppColors.ink.withValues(alpha: 0.10),
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.40),
                  fontWeight: FontWeight.w600,
                ),
                textStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardPreview() {
    final path = _card?.imagePath.trim() ?? '';
    if (path.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.ink.withValues(alpha: 0.04),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.credit_card_rounded,
          size: 44,
          color: AppColors.ink.withValues(alpha: 0.22),
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

    return ClipRRect(borderRadius: BorderRadius.circular(8), child: child);
  }

  Widget _scanPreviewThumbnail({
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildCardPreview(),
    );
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
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

  Widget _topSummaryCard() {
    final theme = Theme.of(context);

    Widget heroCopy() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: AppColors.primary.withValues(alpha: 0.92),
                ),
                const SizedBox(width: 8),
                Text(
                  'REVIEW SCAN',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Card ${_scanController.scannedCount} scanned successfully',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review the details below, make quick edits if needed, then continue the scan loop.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.62),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _isEditing = !_isEditing),
                icon: Icon(
                  _isEditing ? Icons.check_circle_outline : Icons.edit_outlined,
                ),
                label: Text(_isEditing ? 'Done' : 'Edit fields'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: BorderSide(
                    color: AppColors.ink.withValues(alpha: 0.14),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_scanController.scannedCount} cards scanned',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
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
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child:
              narrow
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: _scanPreviewThumbnail(
                          width: double.infinity,
                          height: 145,
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
                      _scanPreviewThumbnail(width: 130, height: 140),
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
              color:
                  selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color:
                    selected
                        ? AppColors.primary.withValues(alpha: 0.26)
                        : AppColors.ink.withValues(alpha: 0.10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color:
                        selected
                            ? AppColors.primary
                            : AppColors.ink.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.primary.withValues(alpha: 0.70),
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
        ..._selectedTags.map((tag) => chip(tag, selected: true)),
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: InkWell(
            onTap: _openAddTagDialog,
            borderRadius: BorderRadius.circular(999),
            child: CustomPaint(
              painter: _DashedPillBorderPainter(
                color: AppColors.primary.withValues(alpha: 0.40),
                radius: 999,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  '+ Add Tag',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w800,
                  ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.10)),
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
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Allow team members to view this contact',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _shareWithOrganization,
            activeTrackColor: AppColors.primary,
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
            top: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _persistEdits();
                  Get.back(result: MultiCardScanAction.finishScanning);
                },
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Finish Scanning'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: BorderSide(
                    color: AppColors.ink.withValues(alpha: 0.14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _persistEdits();
                  Get.back(result: MultiCardScanAction.scanNext);
                },
                icon: const Icon(Icons.navigate_next_rounded),
                label: const Text('Scan Next Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _secondaryEmailCtrl.dispose();
    _companyCtrl.dispose();
    _jobTitleCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = _card ?? _scanController.findById(_cardId);
    _card = card;

    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan Result')),
        body: const Center(child: Text('No scan result found.')),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          color: AppColors.ink,
          onPressed: () => Get.back(),
        ),
        title: const Text('Review Scan'),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w800,
        ),
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
                          _salutationDropdown(),
                          const SizedBox(height: 14),
                          _field(
                            label: 'Full Name',
                            controller: _fullNameCtrl,
                            hint: 'Full name',
                          ),
                          const SizedBox(height: 14),
                          _field(
                            label: 'Company',
                            controller: _companyCtrl,
                            hint: 'Company name',
                          ),
                          const SizedBox(height: 14),
                          _field(
                            label: 'Designation',
                            controller: _jobTitleCtrl,
                            hint: 'Designation',
                          ),
                          const SizedBox(height: 14),
                          _phoneFieldWithCountry(
                            label: 'Mobile',
                            textController: _phoneCtrl,
                            hint: 'Phone Number 1 ...',
                            isPhone1: true,
                          ),
                          const SizedBox(height: 14),
                          _phoneFieldWithCountry(
                            label: 'Phone',
                            textController: _mobileCtrl,
                            hint: 'Phone number 2',
                            isPhone1: false,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            label: 'Primary Email',
                            controller: _emailCtrl,
                            hint: 'Email',
                            inputType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            label: 'Secondary Email',
                            controller: _secondaryEmailCtrl,
                            hint: 'Email',
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
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _section(
                      icon: Icons.business_rounded,
                      title: 'Organization',
                      child: _organizationDropdown(),
                    ),
                    const SizedBox(height: 18),
                    _section(
                      icon: Icons.sell_rounded,
                      title: 'Event & Tags',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _eventDropdown(),
                          const SizedBox(height: 14),
                          Text(
                            'Tags',
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(
                              color: AppColors.ink.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _tagChips(),
                          const SizedBox(height: 14),
                          _shareWithOrganisationRow(),
                          if (!card.parseSucceeded &&
                              (card.parseError ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              'Parse Note',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              card.parseError!.trim(),
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.62),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
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
