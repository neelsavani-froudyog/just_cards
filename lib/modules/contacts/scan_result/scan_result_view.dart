import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../core/models/parse_card_response.dart';
import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_session_service.dart';
import '../../../core/services/create_contact_service.dart';
import '../../../core/services/document_scanner_service.dart';
import '../../../core/services/http_sender_io.dart';
import '../../../core/services/parse_card_service.dart';
import '../../../core/services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_search_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import '../../home/home_controller.dart';
import '../../home/home_events_model.dart';
import '../manual_entry/add_tag_dialog.dart';
import '../manual_entry/organization_simple_model.dart';

class _ParsedPhoneData {
  final String nationalNumber;
  final String isoCode;

  const _ParsedPhoneData({
    required this.nationalNumber,
    required this.isoCode,
  });
}

class _DashedPillBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double dashGap;

  const _DashedPillBorderPainter({
    required this.color,
    required this.radius,
    this.strokeWidth = 1.4,
    this.dashLength = 6,
    this.dashGap = 4,
  });

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

class ScanResultView extends StatefulWidget {
  const ScanResultView({super.key});

  @override
  State<ScanResultView> createState() => _ScanResultViewState();
}

class _ScanResultViewState extends State<ScanResultView> {
  List<String> _images = const <String>[];
  String _rawOcrText = '';
  String _ocrScript = 'unknown';

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isRescanning = false;
  bool _isLoadingDialogVisible = false;
  bool _lockOrganization = false;
  bool _lockEvent = false;
  String? _lockedOrganizationId;
  String? _lockedOrganizationName;
  String? _lockedEventId;
  String? _lockedEventTitle;

  late final ApiService _apiService;
  late final CountryService _countryService;

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
  String? _selectedOrganizationId;
  final List<OrganizationOption> _organizationOptions = <OrganizationOption>[];
  bool _isOrganizationsLoading = false;

  static const String _noneEvent = 'Select event';
  final List<String> _events = <String>[_noneEvent];
  String _selectedEvent = _noneEvent;
  String? _selectedEventId;
  final List<HomeEventItem> _eventOptions = <HomeEventItem>[];
  bool _isEventsLoading = false;

  @override
  void initState() {
    super.initState();
    _apiService = Get.find<ApiService>();
    _countryService = CountryService();
    final args =
        Get.arguments as Map<String, dynamic>? ?? const <String, dynamic>{};
    final payloadImagePath = _extractScannerImagePath(args);
    final imagesArg = args['images'];
    _images =
        (imagesArg is List)
            ? imagesArg.cast<String>()
            : (payloadImagePath.isNotEmpty
                ? <String>[payloadImagePath]
                : const <String>[]);
    _lockedOrganizationId = args['organizationId']?.toString().trim();
    _lockedOrganizationName = args['organizationName']?.toString().trim();
    _lockedEventId = args['eventId']?.toString().trim();
    _lockedEventTitle = args['eventTitle']?.toString().trim();
    _lockOrganization = args['lockOrganization'] == true;
    _lockEvent = args['lockEvent'] == true;

    // Show org immediately when locked and name is provided (before API loads).
    if (_lockOrganization) {
      final lockedName = _lockedOrganizationName?.trim() ?? '';
      if (lockedName.isNotEmpty) {
        _organizations
          ..removeWhere((e) => e == lockedName)
          ..add(lockedName);
        _selectedOrganization = lockedName;
        _selectedOrganizationId =
            (_lockedOrganizationId?.trim().isNotEmpty ?? false)
                ? _lockedOrganizationId
                : null;
        _shareWithOrganization = true;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runOcrForCurrentImage());
    });

    // Load dropdowns (Organization + Event) via API, same as Manual Entry screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_fetchOrganizations());
      unawaited(_fetchAllEvents());
    });
  }

  String _extractScannerImagePath(Map<String, dynamic> args) {
    dynamic raw =
        args['resultJson'] ?? args['scan_result_json'] ?? args['scanResult'];
    if (raw == null) return '';
    try {
      if (raw is String) {
        final decoded = json.decode(raw);
        if (decoded is Map) {
          return decoded['image_path']?.toString().trim() ?? '';
        }
      } else if (raw is Map) {
        return raw['image_path']?.toString().trim() ?? '';
      }
    } catch (_) {
      return '';
    }
    return '';
  }

  String _normalizeText(String text) {
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<Map<String, dynamic>> _runAutoOcr(String imagePath) async {
    try {
      if (imagePath.startsWith('content://')) {
        return {'text': '', 'script': 'unknown'};
      }

      final normalizedPath =
          imagePath.startsWith('file://') ? imagePath.substring(7) : imagePath;
      final file = File(normalizedPath);
      if (!await file.exists()) {
        return {'text': '', 'script': 'unknown'};
      }

      final inputImage = InputImage.fromFilePath(normalizedPath);

      final scripts = <String, TextRecognitionScript>{
        'latin': TextRecognitionScript.latin,
        'devanagari': TextRecognitionScript.devanagiri,
        'chinese': TextRecognitionScript.chinese,
        'japanese': TextRecognitionScript.japanese,
        'korean': TextRecognitionScript.korean,
      };

      String bestText = '';
      String bestScript = 'unknown';

      for (final entry in scripts.entries) {
        final recognizer = TextRecognizer(script: entry.value);
        try {
          final result = await recognizer.processImage(inputImage);
          final text = _normalizeText(result.text);
          if (text.length > bestText.length) {
            bestText = text;
            bestScript = entry.key;
          }
        } catch (_) {
        } finally {
          await recognizer.close();
        }
      }

      // Always prefer Latin output when available.
      // Fallback to other scripts only when Latin OCR is empty.

      return {'text': bestText, 'script': bestScript};
    } catch (_) {
      return {'text': '', 'script': 'error'};
    }
  }

  OrganizationOption? _findOrganizationById(String id) {
    final target = id.trim().toLowerCase();
    if (target.isEmpty) return null;
    for (final item in _organizationOptions) {
      if (item.id.trim().toLowerCase() == target) return item;
    }
    return null;
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

  String _composeInternationalPhone(String iso3166alpha2, String nationalRaw) {
    final c = Country.tryParse(iso3166alpha2);
    final pc = (c?.phoneCode ?? '91').trim();
    final codeDigits = pc.replaceAll(RegExp(r'\D'), '');
    final digits = nationalRaw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (nationalRaw.trim().startsWith('+')) return '+$digits';
    return '+$codeDigits$digits';
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

    final normalizedNumber = _normalizeParsedPhone(value);
    return _ParsedPhoneData(
      nationalNumber: normalizedNumber,
      isoCode: bestMatch?.countryCode ?? fallbackIso,
    );
  }

  Future<void> _runOcrForCurrentImage() async {
    if (_images.isEmpty) return;
    final result = await _runAutoOcr(_images.first.trim());
    if (!mounted) return;
    setState(() {
      _rawOcrText = (result['text']?.toString() ?? '').trim();
      _ocrScript = (result['script']?.toString() ?? 'unknown').trim();
    });
    await _parseOcrTextAndFillFields();
  }

  Future<void> _parseOcrTextAndFillFields() async {
    if (_rawOcrText.isEmpty) return;
    await _showLoadingDialog('Parsing card...');

    ParseCardService parseService;
    try {
      parseService = Get.find<ParseCardService>();
    } catch (_) {
      parseService = Get.put<ParseCardService>(
        ParseCardService(),
        permanent: true,
      );
    }

    final outcome = await parseService.parseCard(_rawOcrText);
    await _hideLoadingDialog();
    if (!mounted) return;
    final fields = outcome.fields;
    if (outcome.success && fields != null) {
      _applyParsedFields(fields);
      return;
    }

    final message = outcome.errorMessage;
    if (message != null && message.isNotEmpty && message != 'Session expired') {
      ToastService.error(message);
    }
  }

  void _applyParsedFields(ParseCardFields fields) {
    final name = fields.name.trim();
    final designation = fields.designation.trim();
    final company = fields.company.trim();
    final email1 = fields.emails.isNotEmpty ? fields.emails.first.trim() : '';
    final email2 = fields.emails.length > 1 ? fields.emails[1].trim() : '';
    final phone1 =
        fields.phones.isNotEmpty
            ? _parsePhoneWithCountry(fields.phones.first.trim(), _phone1CountryIso)
            : _ParsedPhoneData(nationalNumber: '', isoCode: _phone1CountryIso);
    final phone2 =
        fields.phones.length > 1
            ? _parsePhoneWithCountry(fields.phones[1].trim(), _phone2CountryIso)
            : _ParsedPhoneData(nationalNumber: '', isoCode: _phone2CountryIso);
    final website = (fields.website ?? '').trim();
    final address = (fields.address ?? '').trim();

    setState(() {
      _fullNameCtrl.text = name;
      _jobTitleCtrl.text = designation;
      _companyCtrl.text = company;
      _emailCtrl.text = email1;
      _secondaryEmailCtrl.text = email2;
      _phone1CountryIso = phone1.isoCode;
      _phone2CountryIso = phone2.isoCode;
      _phoneCtrl.text = phone1.nationalNumber;
      _mobileCtrl.text = phone2.nationalNumber;
      _websiteCtrl.text = website;
      _addressCtrl.text = address;
    });
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

  Widget _salutationDropdown() {
    return CustomSearchDropdown<String>(
      items: _salutations,
      selectedItem: _selectedSalutation,
      hintText: 'Select salutation',
      label: 'Salutation',
      showSearchBox: false,
      itemAsString: (s) => s,
      onChanged: (v) {
        if (v == null) return;
        FocusScope.of(context).unfocus();
        if (mounted) setState(() => _selectedSalutation = v);
      },
      bgColor: const Color(0xFFF5F7FB),
      borderColor: AppColors.ink.withValues(alpha: 0.10),
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      showShadow: false,
    );
  }

  void _setOrganization(String? v) {
    if (_lockOrganization) return;
    FocusScope.of(context).unfocus();
    if (v == null) return;

    if (v == _noneOrganization) {
      if (mounted) {
        setState(() {
          _selectedOrganization = v;
          _selectedOrganizationId = null;
          _shareWithOrganization = false;
        });
      } else {
        _selectedOrganizationId = null;
      }
      unawaited(_fetchAllEvents());
      return;
    }

    OrganizationOption? selected;
    for (final item in _organizationOptions) {
      if (item.name == v) {
        selected = item;
        break;
      }
    }
    final id = selected?.id;
    if (mounted) {
      setState(() {
        _selectedOrganization = v;
        _selectedOrganizationId = id;
        _shareWithOrganization = true;
      });
    } else {
      _selectedOrganizationId = id;
    }
    unawaited(_fetchEventsByOrganization(id));
  }

  void _setEvent(String? v) {
    if (_lockEvent) return;
    FocusScope.of(context).unfocus();
    if (v == null) return;
    if (!mounted) return;
    if (v == _noneEvent) {
      setState(() {
        _selectedEvent = v;
        _selectedEventId = null;
      });
      return;
    }
    HomeEventItem? selected;
    for (final item in _eventOptions) {
      if (item.title == v) {
        selected = item;
        break;
      }
    }
    setState(() {
      _selectedEvent = v;
      _selectedEventId = selected?.id.trim();
    });
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
          if (!parsed.ok) return;

          _organizationOptions
            ..clear()
            ..addAll(parsed.data);

          final names = <String>[
            _noneOrganization,
            ..._organizationOptions
                .map((e) => e.name.trim())
                .where((e) => e.isNotEmpty),
          ];

          if (!mounted) return;
          setState(() {
            _organizations
              ..clear()
              ..addAll(names);
            if (_lockOrganization) {
              final lockedId = _lockedOrganizationId?.trim() ?? '';
              final lockedName = _lockedOrganizationName?.trim() ?? '';
              final match =
                  lockedId.isEmpty ? null : _findOrganizationById(lockedId);
              if (match != null) {
                _selectedOrganization = match.name;
                _selectedOrganizationId = match.id;
                _shareWithOrganization = true;
                unawaited(_fetchEventsByOrganization(match.id));
              } else if (lockedName.isNotEmpty) {
                if (!_organizations.contains(lockedName)) {
                  _organizations.add(lockedName);
                }
                _selectedOrganization = lockedName;
                _selectedOrganizationId = lockedId.isNotEmpty ? lockedId : null;
                _shareWithOrganization = true;
                if (lockedId.isNotEmpty) {
                  unawaited(_fetchEventsByOrganization(lockedId));
                }
              } else {
                _selectedOrganization = _noneOrganization;
                _selectedOrganizationId = null;
                _shareWithOrganization = false;
              }
            } else {
              _selectedOrganization = _noneOrganization;
              _selectedOrganizationId = null;
              _shareWithOrganization = false;
            }
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
          if (!parsed.ok) return;

          _eventOptions
            ..clear()
            ..addAll(parsed.data);

          final names = <String>[
            _noneEvent,
            ..._eventOptions
                .map((e) => e.title.trim())
                .where((t) => t.isNotEmpty),
          ];

          if (!mounted) return;
          setState(() {
            _events
              ..clear()
              ..addAll(names);
            if (_lockEvent &&
                _lockedEventId != null &&
                _lockedEventId!.isNotEmpty) {
              final match = _findEventById(_lockedEventId!);
              if (match != null) {
                _selectedEvent =
                    match.title.trim().isEmpty
                        ? (_lockedEventTitle ?? _noneEvent)
                        : match.title.trim();
                _selectedEventId = match.id.trim();
              } else {
                _selectedEvent =
                    _lockedEventTitle?.trim().isNotEmpty == true
                        ? _lockedEventTitle!.trim()
                        : _noneEvent;
                _selectedEventId = _lockedEventId;
              }
            } else {
              _selectedEvent = _noneEvent;
              _selectedEventId = null;
            }
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
          if (!parsed.ok) return;

          _eventOptions
            ..clear()
            ..addAll(parsed.data);

          final names = <String>[
            _noneEvent,
            ..._eventOptions
                .map((e) => e.title.trim())
                .where((t) => t.isNotEmpty),
          ];

          if (!mounted) return;
          setState(() {
            _events
              ..clear()
              ..addAll(names);
            if (_lockEvent &&
                _lockedEventId != null &&
                _lockedEventId!.isNotEmpty) {
              final match = _findEventById(_lockedEventId!);
              if (match != null) {
                _selectedEvent =
                    match.title.trim().isEmpty
                        ? (_lockedEventTitle ?? _noneEvent)
                        : match.title.trim();
                _selectedEventId = match.id.trim();
              } else {
                _selectedEvent =
                    _lockedEventTitle?.trim().isNotEmpty == true
                        ? _lockedEventTitle!.trim()
                        : _noneEvent;
                _selectedEventId = _lockedEventId;
              }
            } else {
              _selectedEvent = _noneEvent;
              _selectedEventId = null;
            }
          });
        },
        onError: (_) {},
      );
    } finally {
      if (mounted) setState(() => _isEventsLoading = false);
    }
  }

  Widget _organizationDropdown() {
    return CustomSearchDropdown<String>(
      items: _organizations,
      selectedItem: _selectedOrganization,
      hintText: 'Select organization',
      label: 'Add to Organisation',
      showSearchBox: false,
      enabled: !_isOrganizationsLoading && !_lockOrganization,
      itemAsString: (s) => s,
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
      enabled: !_isEventsLoading && !_lockEvent,
      itemAsString: (s) => s,
      onChanged: _setEvent,
      bgColor: const Color(0xFFF5F7FB),
      borderColor: AppColors.ink.withValues(alpha: 0.10),
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      showShadow: false,
    );
  }

  Future<void> _saveContact() async {
    if (_isSaving) return;

    final path = _images.isNotEmpty ? _images.first.trim() : '';
    if (path.isEmpty) {
      ToastService.error('Add a business card image at the top first');
      return;
    }

    final filePath = path.startsWith('file://') ? path.substring(7) : path;
    final file = File(filePath);
    if (!await file.exists()) {
      ToastService.error('Image file is missing. Scan again.');
      return;
    }

    // Trim & validate required fields before doing any network calls (same as manual entry).
    final fullNameRaw = _fullNameCtrl.text.trim();
    final nameParts =
        fullNameRaw
            .split(RegExp(r'\s+'))
            .where((p) => p.trim().isNotEmpty)
            .toList();
    final first = nameParts.isNotEmpty ? nameParts.first : '';
    final last = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final designation = _jobTitleCtrl.text.trim();
    final companyName = _companyCtrl.text.trim();
    final website = _websiteCtrl.text.trim();
    final email1 = _emailCtrl.text.trim();
    final email2 = _secondaryEmailCtrl.text.trim();
    final national1 = _phoneCtrl.text.trim();
    final national2 = _mobileCtrl.text.trim();
    final phone1 = _composeInternationalPhone(_phone1CountryIso, national1);
    final phone2 =
        national2.isEmpty
            ? ''
            : _composeInternationalPhone(_phone2CountryIso, national2);
    final address = _addressCtrl.text.trim();

    if (first.isEmpty) {
      ToastService.error('First name is required');
      return;
    }
    if (companyName.isEmpty) {
      ToastService.error('Company name is required');
      return;
    }
    if (email1.isEmpty) {
      ToastService.error('Primary email is required');
      return;
    }
    if (!email1.contains('@')) {
      ToastService.error('Please enter a valid email address');
      return;
    }
    if (phone1.isEmpty || national1.replaceAll(RegExp(r'\D'), '').isEmpty) {
      ToastService.error('Mobile number is required');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final session = Get.find<AuthSessionService>();
      final token = session.accessToken.value.trim();
      if (token.isEmpty) {
        ToastService.error('Please sign in again');
        return;
      }

      final base = ApiUrl.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$base${ApiUrl.profileImagesUpload}');

      final uploadResp = await sendMultipartFormData(
        uri: uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        textFields: <String, String>{
          'eventName':
              _selectedEvent == _noneEvent ? 'Direct Entry' : _selectedEvent,
        },
        fileFieldName: 'file',
        file: file,
      );

      if (uploadResp.statusCode < 200 || uploadResp.statusCode >= 300) {
        ToastService.error(
          'Image upload failed (HTTP ${uploadResp.statusCode})',
        );
        return;
      }

      final responseBody = uploadResp.bodyText.trim();
      if (responseBody.isEmpty) {
        ToastService.error('Empty upload response');
        return;
      }

      dynamic decoded;
      try {
        decoded = json.decode(responseBody);
      } catch (_) {
        ToastService.error('Invalid JSON from upload API');
        return;
      }

      final publicUrl =
          decoded is Map
              ? (decoded['data'] is Map
                      ? (decoded['data']['cdnUrl']?.toString() ?? '')
                      : decoded['cdnUrl']?.toString() ?? '')
                  .trim()
              : '';

      if (publicUrl.isEmpty) {
        ToastService.error('No `public_url` returned from server');
        return;
      }

      final contactService = Get.find<CreateContactService>();
      final userId = await contactService.fetchProfileUserId();
      if (userId == null || userId.isEmpty) {
        ToastService.error('Could not load your user id');
        return;
      }

      final fullName =
          '$first $last'.trim().isEmpty
              ? 'Unnamed contact'
              : '$first $last'.trim();

      final lockedOrgId = _lockedOrganizationId?.trim();
      final orgId = _selectedOrganizationId?.trim();
      final resolvedOrgId =
          (_lockOrganization && lockedOrgId != null && lockedOrgId.isNotEmpty)
              ? lockedOrgId
              : (_selectedOrganization == _noneOrganization ||
                  orgId == null ||
                  orgId.isEmpty)
              ? null
              : orgId;

      final lockedEventId = _lockedEventId?.trim();
      final eid = _selectedEventId?.trim();
      final resolvedEventId =
          (_lockEvent && lockedEventId != null && lockedEventId.isNotEmpty)
              ? lockedEventId
              : (_selectedEvent == _noneEvent || eid == null || eid.isEmpty)
              ? null
              : eid;

      final createResult = await contactService.createContact(
        ownerUserId: userId,
        organizationId: resolvedOrgId,
        createdBy: userId,
        fullName: fullName,
        source: 'scan',
        eventId: resolvedEventId,
        allowShareOrganization: _shareWithOrganization,
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
        tags: List<String>.from(_selectedTags),
        profilePhotoUrl: null,
        scanLanguage: _ocrScript,
        rawOcrText: _rawOcrText.isEmpty ? null : _rawOcrText,
      );

      if (!createResult.success) {
        ToastService.error(createResult.message ?? 'Failed to save contact');
        return;
      }

      ToastService.success(createResult.message ?? 'Saved');
      if (Get.isRegistered<HomeController>()) {
        await Get.find<HomeController>().refreshAllData();
      }
      Get.back(result: true, closeOverlays: false);
    } finally {
      await _hideLoadingDialog();
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showLoadingDialog(String message) async {
    if (!mounted || _isLoadingDialogVisible) return;
    _isLoadingDialogVisible = true;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.6),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Our AI Magic Capturing!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.60),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
      ).then((_) {
        _isLoadingDialogVisible = false;
      }),
    );
  }

  Future<void> _hideLoadingDialog() async {
    if (!mounted || !_isLoadingDialogVisible) return;
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    _isLoadingDialogVisible = false;
  }

  Future<void> _rescanCard() async {
    if (_isRescanning) return;
    setState(() => _isRescanning = true);
    try {
      final images = await DocumentScannerService.scan(allowMultiple: false);
      setState(() {
        _images = images;
        _rawOcrText = '';
        _ocrScript = 'unknown';
      });
      await _runOcrForCurrentImage();
      ToastService.info(
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

  Future<void> _openAddTagDialog() async {
    await Get.dialog<void>(
      AddTagDialog(selectedTags: _selectedTags),
      barrierDismissible: true,
    );
    if (mounted) setState(() {});
  }

  Widget _buildCardPreview() {
    final path = _images.isNotEmpty ? _images.first : '';
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
      suffixIcon:
          suffixIcon == null
              ? null
              : Icon(suffixIcon, color: AppColors.ink.withValues(alpha: 0.55)),
    );
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
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  foregroundColor: AppColors.primary,
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
        ..._selectedTags.map((t) => chip(t, selected: true)),
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
                onPressed: _isSaving ? null : () => Get.back(),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Cancel'),
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
                onPressed: _isSaving ? null : _saveContact,
                icon:
                    _isSaving
                        ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        )
                        : const Icon(Icons.check_rounded),
                label: Text(_isSaving ? 'Saving...' : 'Save Contact'),
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
  Widget build(BuildContext context) {
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
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final stack = constraints.maxWidth < 420;
                              final org = _organizationDropdown();
                              final company = _field(
                                label: 'Company',
                                controller: _companyCtrl,
                                hint: 'Company name',
                              );
                              if (stack) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    org,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        org,
                                      ],
                                    ),
                                  ),
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
                            ],
                          ),
                        ),
                      ],
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
