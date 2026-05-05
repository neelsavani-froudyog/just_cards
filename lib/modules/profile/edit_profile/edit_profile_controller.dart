import 'dart:convert';
import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_session_service.dart';
import '../../../core/services/http_sender_io.dart';
import '../../../core/services/toast_service.dart';
import '../profile_controller.dart';
import '../profile_model.dart';

class EditProfileController extends GetxController {
  final fullNameController = TextEditingController();
  final companyNameController = TextEditingController();
  final designationController = TextEditingController();
  final websiteController = TextEditingController();
  final addressController = TextEditingController();
  final phoneController = TextEditingController();
  final secondaryPhoneController = TextEditingController();
  final emailController = TextEditingController();
  final secondaryEmailController = TextEditingController();
  final avatarUrl = ''.obs;
  final phoneCountryIso = 'IN'.obs;
  final secondaryPhoneCountryIso = 'IN'.obs;

  final isLoading = false.obs;
  final isSaving = false.obs;
  final isUploadingAvatar = false.obs;

  late final ApiService _api;
  late final AuthSessionService _session;

  @override
  void onInit() {
    super.onInit();
    _api = Get.find<ApiService>();
    _session = Get.find<AuthSessionService>();
    loadProfile();
  }

  @override
  void onClose() {
    fullNameController.dispose();
    companyNameController.dispose();
    designationController.dispose();
    websiteController.dispose();
    addressController.dispose();
    phoneController.dispose();
    secondaryPhoneController.dispose();
    emailController.dispose();
    secondaryEmailController.dispose();
    super.onClose();
  }

  void setPhoneCountry(Country country) {
    phoneCountryIso.value = country.countryCode;
  }

  void setSecondaryPhoneCountry(Country country) {
    secondaryPhoneCountryIso.value = country.countryCode;
  }

  static String _digitsOnly(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  /// Splits E.164 into (country, national). Defaults to IN if unknown.
  void _applyPhoneFromProfile(String raw, {required bool secondary}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    if (!trimmed.startsWith('+')) {
      (secondary ? secondaryPhoneController : phoneController).text = trimmed;
      return;
    }
    final digits = _digitsOnly(trimmed);
    if (digits.isEmpty) return;
    final service = CountryService();
    Country? match;
    var bestLen = 0;
    for (final c in service.getAll()) {
      final code = c.phoneCode;
      if (code.isEmpty) continue;
      if (digits.startsWith(code) && code.length > bestLen) {
        match = c;
        bestLen = code.length;
      }
    }
    if (match != null) {
      if (secondary) {
        secondaryPhoneCountryIso.value = match.countryCode;
        secondaryPhoneController.text = digits.substring(bestLen);
      } else {
        phoneCountryIso.value = match.countryCode;
        phoneController.text = digits.substring(bestLen);
      }
    } else {
      (secondary ? secondaryPhoneController : phoneController).text = digits;
    }
  }

  /// [nationalRaw] = subscriber number only (no country code). Returns e.g. `+919650456854`.
  static String composeInternationalPhone(
    String iso3166alpha2,
    String nationalRaw,
  ) {
    final c =
        CountryService().findByCode(iso3166alpha2) ??
        CountryService().findByCode('IN');
    final pc = (c?.phoneCode ?? '91').trim();
    final codeDigits = _digitsOnly(pc);
    final digits = _digitsOnly(nationalRaw);
    if (digits.isEmpty) return '';
    return '+$codeDigits$digits';
  }

  Future<void> loadProfile() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      await _api.getRequest(
        url: ApiUrl.profileMe,
        showSuccessToast: false,
        showErrorToast: false,
        onSuccess: (payload) {
          final response = payload['response'];
          if (response is! Map<String, dynamic>) return;
          final parsed = ProfileMeResponse.fromJson(response);
          final data = parsed.data;
          if (data == null) return;

          fullNameController.text = data.fullName;
          companyNameController.text = (data.companyName ?? '').trim();
          designationController.text = (data.designation ?? '').trim();
          websiteController.text = (data.website ?? '').trim();
          addressController.text = (data.address ?? '').trim();
          _applyPhoneFromProfile((data.phone ?? '').trim(), secondary: false);
          _applyPhoneFromProfile(
            (data.secondaryPhone ?? '').trim(),
            secondary: true,
          );
          emailController.text = (data.email).trim();
          secondaryEmailController.text = (data.secondaryEmail ?? '').trim();
          avatarUrl.value = (data.avatarUrl ?? '').trim();
        },
        onError: (message) {
          ToastService.error(
            (message?.isNotEmpty ?? false)
                ? message!
                : 'Failed to load profile',
          );
        },
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndUploadAvatar({required ImageSource source}) async {
    if (isUploadingAvatar.value) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1400,
    );
    if (picked == null) return;

    final file = File(picked.path);
    if (!await file.exists()) {
      ToastService.error('Selected image not found');
      return;
    }
    avatarUrl.value = picked.path;
  }

  Future<void> save() async {
    if (isSaving.value) return;

    final fullName = fullNameController.text.trim().replaceAll(
      RegExp(r'\\s+'),
      ' ',
    );
    final companyName = companyNameController.text.trim().replaceAll(
      RegExp(r'\\s+'),
      ' ',
    );
    final phone = composeInternationalPhone(
      phoneCountryIso.value,
      phoneController.text.trim(),
    );
    final secondaryPhone = composeInternationalPhone(
      secondaryPhoneCountryIso.value,
      secondaryPhoneController.text.trim(),
    );
    final designation = designationController.text.trim().replaceAll(
      RegExp(r'\\s+'),
      ' ',
    );
    final website = websiteController.text.trim();
    final address = addressController.text.trim().replaceAll(
      RegExp(r'\\s+'),
      ' ',
    );
    final secondaryEmail = secondaryEmailController.text.trim();

    if (fullName.length < 2) {
      ToastService.error('Please enter your full name');
      return;
    }

    isSaving.value = true;
    try {
      final avatarForSave = await _uploadProfilePhotoIfNeeded();
      if (avatarForSave == null) return;

      await _api.patchRequest(
        url: ApiUrl.createProfile,
        data: <String, dynamic>{
          'p_full_name': fullName,
          'p_phone': phone.trim().isEmpty ? null : phone,
          'p_avatar_url': avatarForSave.trim().isEmpty ? null : avatarForSave,
          'p_company_name': companyName.trim().isEmpty ? null : companyName,
          'p_designation': designation.isEmpty ? null : designation,
          'p_website': website.isEmpty ? null : website,
          'p_address': address.isEmpty ? null : address,
          'p_secondary_email': secondaryEmail.isEmpty ? null : secondaryEmail,
          'p_secondary_phone':
              secondaryPhone.trim().isEmpty ? null : secondaryPhone,
        },
        showSuccessToast: true,
        successToastMessage: 'Profile updated',
        showErrorToast: true,
        onSuccess: (_) {
          _session.completeProfile(
            name: fullName,
            emailAddress: _session.email.value,
          );
          try {
            Get.find<ProfileController>().fetchProfile(force: true);
          } catch (_) {}
          Get.back();
        },
        onError: (message) {
          final msg = message?.trim() ?? '';
          ToastService.error(msg.isNotEmpty ? msg : 'Failed to update profile');
        },
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<String?> _uploadProfilePhotoIfNeeded() async {
    final current = avatarUrl.value.trim();
    if (current.isEmpty) return current;
    final isRemote =
        current.startsWith('http://') || current.startsWith('https://');
    if (isRemote) return current;

    final token = _session.accessToken.value.trim();
    if (token.isEmpty) {
      await ToastService.error('Please sign in again');
      return null;
    }

    final file = File(current);
    if (!await file.exists()) {
      await ToastService.error('Selected image not found');
      return null;
    }

    isUploadingAvatar.value = true;
    try {
      final base = ApiUrl.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$base${ApiUrl.profilePhotoUpload}');
      final uploadResp = await sendMultipartFormData(
        uri: uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        textFields: const <String, String>{},
        fileFieldName: 'file',
        file: file,
      );

      if (uploadResp.statusCode < 200 || uploadResp.statusCode >= 300) {
        await ToastService.error(
          'Photo upload failed (HTTP ${uploadResp.statusCode})',
        );
        return null;
      }

      dynamic decoded;
      try {
        decoded = json.decode(uploadResp.bodyText.trim());
      } catch (_) {
        await ToastService.error('Invalid response from photo upload API');
        return null;
      }

      final publicUrl = _readPhotoUrlFromResponse(decoded);
      if (publicUrl.isEmpty) {
        await ToastService.error('No public URL returned from photo upload');
        return null;
      }
      avatarUrl.value = publicUrl;
      return publicUrl;
    } finally {
      isUploadingAvatar.value = false;
    }
  }

  String _readPhotoUrlFromResponse(dynamic decoded) {
    if (decoded is! Map) return '';
    final direct =
        decoded['public_url']?.toString().trim() ??
        decoded['publicUrl']?.toString().trim() ??
        decoded['cdnUrl']?.toString().trim() ??
        '';
    if (direct.isNotEmpty) return direct;
    final data = decoded['data'];
    if (data is Map) {
      return data['public_url']?.toString().trim() ??
          data['publicUrl']?.toString().trim() ??
          data['cdnUrl']?.toString().trim() ??
          data['url']?.toString().trim() ??
          '';
    }
    return '';
  }
}
