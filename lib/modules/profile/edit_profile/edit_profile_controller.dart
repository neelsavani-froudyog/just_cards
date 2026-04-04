import 'dart:convert';
import 'dart:io';

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
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final avatarUrl = ''.obs;

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
    phoneController.dispose();
    emailController.dispose();
    super.onClose();
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
          phoneController.text = (data.phone ?? '').trim();
          emailController.text = (data.email).trim();
          avatarUrl.value = (data.avatarUrl ?? '').trim();
        },
        onError: (message) {
          ToastService.error((message?.isNotEmpty ?? false) ? message! : 'Failed to load profile');
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

    final fullName = fullNameController.text.trim().replaceAll(RegExp(r'\\s+'), ' ');
    final companyName = companyNameController.text.trim().replaceAll(RegExp(r'\\s+'), ' ');

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
          'p_phone': phoneController.text.trim(),
          'p_avatar_url': avatarForSave,
          'p_company_name': companyName.isEmpty ? null : companyName,
        },
        showSuccessToast: true,
        successToastMessage: 'Profile updated',
        showErrorToast: true,
        onSuccess: (_) {
          _session.completeProfile(name: fullName, emailAddress: _session.email.value);
          try {
            Get.find<ProfileController>().fetchProfile();
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
    final isRemote = current.startsWith('http://') || current.startsWith('https://');
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
        await ToastService.error('Photo upload failed (HTTP ${uploadResp.statusCode})');
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
    final direct = decoded['public_url']?.toString().trim() ??
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
