import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:country_picker/country_picker.dart';
import 'package:get/get.dart';
import 'package:just_cards/routes/app_routes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/custom_text_field.dart';

import 'profile_controller.dart';
import 'profile_model.dart';
import 'profile_shimmer_view.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.ink.withValues(alpha: 0.06),
          ),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              sliver: SliverToBoxAdapter(
                child: _HeaderCard(controller: controller),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'ACCOUNT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.42),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 6),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _SettingTile(
                    icon: Icons.groups_2_outlined,
                    title: 'Organizations',
                    onTap: () => Get.toNamed(Routes.manageOrganization),
                  ),
                  // _SettingTile(
                  //   icon: Icons.public_rounded,
                  //   title: 'Country',
                  //   onTap: () => ToastService.info('Coming soon'),
                  // ),
                  // _SettingTile(
                  //   icon: Icons.notifications_none_rounded,
                  //   title: 'Notification Settings',
                  //   onTap: () => ToastService.info('Coming soon'),
                  // ),
                  _SettingTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    onTap: () async {
                      await Get.toNamed(Routes.editProfile);
                      await controller.fetchProfile(force: true);
                    },
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'GENERAL',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.42),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                18,
                0,
                18,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _SettingTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Support',
                    onTap: () => Get.toNamed(Routes.support),
                  ),
                  _SettingTile(
                    icon: Icons.policy_outlined,
                    title: 'Terms of Service',
                    onTap: () => Get.toNamed(Routes.termsConditions),
                  ),
                  _SettingTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => Get.toNamed(Routes.privacyPolicy),
                  ),
                  _SettingTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About Us',
                    onTap: () => Get.toNamed(Routes.aboutUs),
                  ),
                  _SettingTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    danger: true,
                    onTap: () {
                      ConfirmDialog.show(
                        title: 'Log out?',
                        message:
                            'You will need to sign in again to access your account.',
                        confirmText: 'Logout',
                        destructive: true,
                      ).then((ok) {
                        if (ok) controller.onLogout();
                      });
                    },
                  ),
                  _SettingTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Account',
                    danger: true,
                    onTap: () {
                      ConfirmDialog.show(
                        title: 'Delete account?',
                        message:
                            'This will permanently delete your account and data. This cannot be undone.',
                        confirmText: 'Delete',
                        destructive: true,
                      ).then((ok) {
                        if (ok) controller.deleteAccount();
                      });
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.controller});

  final ProfileController controller;

  Color _avatarColorFor(String seed) {
    const palette = <Color>[
      Color(0xFF0D8A4E),
      Color(0xFF0A66C2),
      Color(0xFF7B2FC7),
      Color(0xFFC47A00),
      Color(0xFF0D6C8A),
      Color(0xFFB00020),
    ];
    if (seed.trim().isEmpty) return palette.first;
    final idx = seed.codeUnits.fold<int>(0, (a, b) => (a + b) % palette.length);
    return palette[idx];
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      initState: (state) {
         controller.fetchProfile();
      },
      builder: (controller) {
        if (controller.isLoading.value) {
          return const ProfileHeaderShimmerCard();
        }
        final avatarUrl =
            controller.profileMe.value?.data?.avatarUrl?.trim() ?? '';
        final name = controller.displayName.value.trim();
        final email = controller.email.value.trim();
        final initials =
            name.isEmpty ? 'U' : name.characters.first.toUpperCase();
        final avatarBg = _avatarColorFor('$name|$email');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.04)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarBg,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: ClipOval(
                  child:
                      avatarUrl.isNotEmpty
                          ? Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Center(
                                  child: Text(
                                    initials,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                          )
                          : Center(
                            child: Text(
                              initials,
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.displayName.value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        letterSpacing: -0.2,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.email.value,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderActionIcon(
                    icon: Icons.qr_code,
                    tooltip: 'My VCF QR',
                    onTap: () => _MyVCardQrFlow.open(controller),
                  ),
                  const SizedBox(width: 6),
                  _HeaderActionIcon(
                    icon: Icons.badge_outlined,
                    tooltip: 'Scan Card',
                    onTap: () => _MyBusinessCardFlow.open(controller),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MyVCardQrFlow {
  static Future<void> open(ProfileController controller) async {
    await controller.fetchProfile(silent: true, force: true);
    final data = controller.profileMe.value?.data;

    if (data != null && _hasAllRequiredProfileFields(data)) {
      await Get.dialog<void>(
        _VCardQrDialog(vcf: _vCardFromProfile(data), title: data.fullName.trim()),
      );
      return;
    }

    final initial = _VCardFormState(
      fullName: (data?.fullName ?? controller.displayName.value).trim(),
      designation: (data?.designation ?? '').trim(),
      companyName: (data?.companyName ?? '').trim(),
      emailPrimary: (data?.email ?? controller.email.value).trim(),
      emailSecondary: (data?.secondaryEmail ?? '').trim(),
      phone1CountryIso: 'IN',
      phone2CountryIso: 'IN',
      phonePrimary: _MyVCardQrFlow._nationalFromE164((data?.phone ?? '').trim()),
      phoneSecondary:
          _MyVCardQrFlow._nationalFromE164((data?.secondaryPhone ?? '').trim()),
      address: (data?.address ?? '').trim(),
      website: (data?.website ?? '').trim(),
    );

    final filled = await Get.dialog<_VCardFormState>(
      _VCardFieldsDialog(initial: initial),
      barrierDismissible: false,
    );
    if (filled == null) return;

    final missing = filled.missingFields;
    if (missing.isNotEmpty) {
      await Get.dialog<void>(
        AlertDialog(
          title: const Text('Missing fields'),
          content: Text('Please fill: ${missing.join(', ')}'),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final avatarUrl = data?.avatarUrl?.trim() ?? '';
    final patchOk = await _patchProfile(
      controller: controller,
      state: filled,
      avatarUrl: avatarUrl,
    );
    if (!patchOk) return;

    await Get.dialog<void>(
      _VCardQrDialog(vcf: filled.toVCard(), title: filled.fullName.trim()),
    );
  }

  static Future<bool> _patchProfile({
    required ProfileController controller,
    required _VCardFormState state,
    required String avatarUrl,
  }) async {
    Get.dialog<void>(
      const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        child: Center(
          child: SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      barrierDismissible: false,
    );
    try {
      return await controller.updateProfileVcfDetails(
        fullName: state.fullName,
        phone: state._fullPhone(state.phone1CountryIso, state.phonePrimary),
        avatarUrl: avatarUrl,
        companyName: state.companyName,
        designation: state.designation,
        address: state.address,
        website: state.website,
        secondaryEmail: state.emailSecondary,
        secondaryPhone: state._fullPhone(
          state.phone2CountryIso,
          state.phoneSecondary,
        ),
      );
    } finally {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }
  }

  static bool _hasAllRequiredProfileFields(ProfileData data) {
    return data.fullName.trim().isNotEmpty &&
        (data.designation ?? '').trim().isNotEmpty &&
        (data.companyName ?? '').trim().isNotEmpty &&
        data.email.trim().isNotEmpty &&
        (data.phone ?? '').trim().isNotEmpty;
  }

  static String _vCardFromProfile(ProfileData data) {
    final fullName = data.fullName.trim();
    final designation = (data.designation ?? '').trim();
    final company = (data.companyName ?? '').trim();
    final email1 = data.email.trim();
    final email2 = (data.secondaryEmail ?? '').trim();
    final phone1 = (data.phone ?? '').trim();
    final phone2 = (data.secondaryPhone ?? '').trim();
    final address = (data.address ?? '').trim();
    final website = (data.website ?? '').trim();

    String esc(String v) => _VCardFormState._escape(v);

    return <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN:${esc(fullName)}',
      if (company.isNotEmpty) 'ORG:${esc(company)}',
      if (designation.isNotEmpty) 'TITLE:${esc(designation)}',
      if (email1.isNotEmpty) 'EMAIL;TYPE=INTERNET:${esc(email1)}',
      if (email2.isNotEmpty) 'EMAIL;TYPE=INTERNET:${esc(email2)}',
      if (phone1.isNotEmpty) 'TEL;TYPE=CELL:${esc(phone1)}',
      if (phone2.isNotEmpty) 'TEL;TYPE=CELL:${esc(phone2)}',
      if (address.isNotEmpty) 'ADR;TYPE=WORK:;;${esc(address)};;;;',
      if (website.isNotEmpty) 'URL:${esc(website)}',
      'END:VCARD',
    ].join('\n');
  }

  static String _nationalFromE164(String e164) {
    final trimmed = e164.trim();
    if (!trimmed.startsWith('+')) return trimmed;
    // Best-effort: for India, strip +91 when present.
    if (trimmed.startsWith('+91')) {
      return trimmed.substring(3).replaceAll(RegExp(r'[^\d]'), '');
    }
    return trimmed.replaceAll(RegExp(r'[^\d]'), '');
  }
}

class _VCardFormState {
  _VCardFormState({
    required this.fullName,
    required this.designation,
    required this.companyName,
    required this.emailPrimary,
    required this.emailSecondary,
    required this.phone1CountryIso,
    required this.phone2CountryIso,
    required this.phonePrimary,
    required this.phoneSecondary,
    required this.address,
    required this.website,
  });

  final String fullName;
  final String designation;
  final String companyName;
  final String emailPrimary;
  final String emailSecondary;
  final String phone1CountryIso;
  final String phone2CountryIso;
  final String phonePrimary;
  final String phoneSecondary;
  final String address;
  final String website;

  List<String> get missingFields {
    final missing = <String>[];
    if (fullName.trim().isEmpty) missing.add('Full Name');
    if (designation.trim().isEmpty) missing.add('Designation');
    if (companyName.trim().isEmpty) missing.add('Company Name');
    if (emailPrimary.trim().isEmpty) missing.add('Primary Email');
    if (phonePrimary.trim().isEmpty) missing.add('Primary Phone Number');
    return missing;
  }

  static String _normalizePhone(String raw) {
    return raw.trim().replaceAll(RegExp(r'[^\d]'), '');
  }

  String _fullPhone(String iso3166alpha2, String nationalNumber) {
    final c = Country.tryParse(iso3166alpha2);
    final pc = (c?.phoneCode ?? '91').trim();
    final codeDigits = pc.replaceAll(RegExp(r'\D'), '');
    final digits = _normalizePhone(nationalNumber);
    if (digits.isEmpty) return '';
    return '+$codeDigits$digits';
  }

  String toVCard() {
    final email1 = emailPrimary.trim();
    final email2 = emailSecondary.trim();
    final phone1 = _fullPhone(phone1CountryIso, phonePrimary);
    final phone2 = _fullPhone(phone2CountryIso, phoneSecondary);

    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'FN:${_escape(fullName)}',
      if (companyName.trim().isNotEmpty) 'ORG:${_escape(companyName)}',
      if (designation.trim().isNotEmpty) 'TITLE:${_escape(designation)}',
      if (email1.isNotEmpty) 'EMAIL;TYPE=INTERNET:${_escape(email1)}',
      if (email2.isNotEmpty) 'EMAIL;TYPE=INTERNET:${_escape(email2)}',
      if (phone1.isNotEmpty) 'TEL;TYPE=CELL:${_escape(phone1)}',
      if (phone2.isNotEmpty) 'TEL;TYPE=CELL:${_escape(phone2)}',
      if (address.trim().isNotEmpty) 'ADR;TYPE=WORK:;;${_escape(address)};;;;',
      if (website.trim().isNotEmpty) 'URL:${_escape(website)}',
      'END:VCARD',
    ];
    return lines.join('\n');
  }

  static String _escape(String v) {
    return v
        .replaceAll('\\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\n', r'\n');
  }
}

class _MyBusinessCardFlow {
  static Future<void> open(ProfileController controller) async {
    await controller.fetchProfile(silent: true, force: true);
    final data = controller.profileMe.value?.data;

    if (data != null && _hasAllRequiredFields(data)) {
      await _BusinessCardSheet.open(data);
      return;
    }

    final initial = _VCardFormState(
      fullName: (data?.fullName ?? controller.displayName.value).trim(),
      designation: (data?.designation ?? '').trim(),
      companyName: (data?.companyName ?? '').trim(),
      emailPrimary: (data?.email ?? controller.email.value).trim(),
      emailSecondary: (data?.secondaryEmail ?? '').trim(),
      phone1CountryIso: 'IN',
      phone2CountryIso: 'IN',
      phonePrimary: _MyVCardQrFlow._nationalFromE164((data?.phone ?? '').trim()),
      phoneSecondary:
          _MyVCardQrFlow._nationalFromE164((data?.secondaryPhone ?? '').trim()),
      address: (data?.address ?? '').trim(),
      website: (data?.website ?? '').trim(),
    );

    final filled = await Get.dialog<_VCardFormState>(
      _VCardFieldsDialog(initial: initial),
      barrierDismissible: false,
    );
    if (filled == null) return;

    final missing = _missingBusinessCardFields(filled);
    if (missing.isNotEmpty) {
      await Get.dialog<void>(
        AlertDialog(
          title: const Text('Missing fields'),
          content: Text('Please fill: ${missing.join(', ')}'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final avatarUrl = data?.avatarUrl?.trim() ?? '';
    final patchOk = await _MyVCardQrFlow._patchProfile(
      controller: controller,
      state: filled,
      avatarUrl: avatarUrl,
    );
    if (!patchOk) return;

    final latest = controller.profileMe.value?.data ?? data;
    if (latest != null) {
      await _BusinessCardSheet.open(latest);
    }
  }

  static bool _hasAllRequiredFields(ProfileData data) =>
      _missingBusinessCardFields(
        _VCardFormState(
          fullName: data.fullName.trim(),
          designation: (data.designation ?? '').trim(),
          companyName: (data.companyName ?? '').trim(),
          emailPrimary: data.email.trim(),
          emailSecondary: (data.secondaryEmail ?? '').trim(),
          phone1CountryIso: 'IN',
          phone2CountryIso: 'IN',
          phonePrimary: _MyVCardQrFlow._nationalFromE164((data.phone ?? '').trim()),
          phoneSecondary:
              _MyVCardQrFlow._nationalFromE164((data.secondaryPhone ?? '').trim()),
          address: (data.address ?? '').trim(),
          website: (data.website ?? '').trim(),
        ),
      ).isEmpty;

  static List<String> _missingBusinessCardFields(_VCardFormState s) {
    final missing = <String>[];
    if (s.fullName.trim().isEmpty) missing.add('Full name');
    if (s.designation.trim().isEmpty) missing.add('Designation');
    if (s.companyName.trim().isEmpty) missing.add('Company name');
    if (s.emailPrimary.trim().isEmpty) missing.add('Email');
    if (s.phonePrimary.trim().isEmpty) missing.add('Phone');
    return missing;
  }
}

class _VCardFieldsDialog extends StatefulWidget {
  const _VCardFieldsDialog({required this.initial});

  final _VCardFormState initial;

  @override
  State<_VCardFieldsDialog> createState() => _VCardFieldsDialogState();
}

class _VCardFieldsDialogState extends State<_VCardFieldsDialog> {
  late final TextEditingController _fullName;
  late final TextEditingController _designation;
  late final TextEditingController _company;
  late final TextEditingController _emailPrimary;
  late final TextEditingController _emailSecondary;
  late final TextEditingController _phonePrimary;
  late final TextEditingController _phoneSecondary;
  late final TextEditingController _address;
  late final TextEditingController _website;

  late String _phone1Iso;
  late String _phone2Iso;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: widget.initial.fullName);
    _designation = TextEditingController(text: widget.initial.designation);
    _company = TextEditingController(text: widget.initial.companyName);
    _emailPrimary = TextEditingController(text: widget.initial.emailPrimary);
    _emailSecondary = TextEditingController(
      text: widget.initial.emailSecondary,
    );
    _phonePrimary = TextEditingController(text: widget.initial.phonePrimary);
    _phoneSecondary = TextEditingController(
      text: widget.initial.phoneSecondary,
    );
    _address = TextEditingController(text: widget.initial.address);
    _website = TextEditingController(text: widget.initial.website);
    _phone1Iso = widget.initial.phone1CountryIso;
    _phone2Iso = widget.initial.phone2CountryIso;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _designation.dispose();
    _company.dispose();
    _emailPrimary.dispose();
    _emailSecondary.dispose();
    _phonePrimary.dispose();
    _phoneSecondary.dispose();
    _address.dispose();
    _website.dispose();
    super.dispose();
  }

  void _submit() {
    final state = _VCardFormState(
      fullName: _fullName.text,
      designation: _designation.text,
      companyName: _company.text,
      emailPrimary: _emailPrimary.text,
      emailSecondary: _emailSecondary.text,
      phone1CountryIso: _phone1Iso,
      phone2CountryIso: _phone2Iso,
      phonePrimary: _phonePrimary.text,
      phoneSecondary: _phoneSecondary.text,
      address: _address.text,
      website: _website.text,
    );
    Get.back(result: state);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
      contentPadding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'My Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.62,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Used to generate your vCard QR.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _VCardField(
                label: 'Full Name',
                hintText: 'e.g. Neel Savani',
                icon: Icons.person_outline_rounded,
                controller: _fullName,
                textInputAction: TextInputAction.next,
              ),
              _VCardField(
                label: 'Designation',
                hintText: 'e.g. Sales Manager',
                icon: Icons.badge_outlined,
                controller: _designation,
                textInputAction: TextInputAction.next,
              ),
              _VCardField(
                label: 'Company Name',
                hintText: 'e.g. Orvion Infotech',
                icon: Icons.business_rounded,
                controller: _company,
                textInputAction: TextInputAction.next,
              ),
              _VCardField(
                label: 'Primary Email',
                hintText: 'email@example.com',
                icon: Icons.alternate_email_rounded,
                controller: _emailPrimary,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              _VCardField(
                label: 'Secondary Email (optional)',
                hintText: 'email2@example.com',
                icon: Icons.alternate_email_rounded,
                controller: _emailSecondary,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              _PhoneRow(
                label: 'Phone Number',
                iso: _phone1Iso,
                onIsoChanged: (v) => setState(() => _phone1Iso = v),
                controller: _phonePrimary,
              ),
              _PhoneRow(
                label: 'Secondary Phone (optional)',
                iso: _phone2Iso,
                onIsoChanged: (v) => setState(() => _phone2Iso = v),
                controller: _phoneSecondary,
              ),
              _VCardField(
                label: 'Address (optional)',
                hintText: 'Office / Home address',
                icon: Icons.location_on_outlined,
                controller: _address,
                maxLines: 2,
                textInputAction: TextInputAction.newline,
              ),
              _VCardField(
                label: 'Website (optional)',
                hintText: 'https://example.com',
                icon: Icons.public_rounded,
                controller: _website,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(foregroundColor: AppColors.ink),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.qr_code_2_rounded, size: 18),
          label: const Text('Generate QR'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

class _VCardField extends StatelessWidget {
  const _VCardField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final effectiveKeyboardType =
        (maxLines > 1)
            ? TextInputType.multiline
            : (keyboardType ?? TextInputType.text);
    final effectiveAction =
        (maxLines > 1)
            ? (textInputAction ?? TextInputAction.newline)
            : textInputAction;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CustomTextField(
        controller: controller,
        label: label,
        hint: hintText,
        inputType: effectiveKeyboardType,
        maxLines: maxLines,
        textInputAction: effectiveAction,
        fillColor: AppColors.background.withValues(alpha: 0.70),
        borderColor: AppColors.ink.withValues(alpha: 0.10),
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        prefixIcon: Icon(
          icon,
          size: 20,
          color: AppColors.ink.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({
    required this.label,
    required this.iso,
    required this.onIsoChanged,
    required this.controller,
  });

  final String label;
  final String iso; // ISO 3166-1 alpha-2
  final ValueChanged<String> onIsoChanged;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final c = Country.tryParse(iso) ?? Country.tryParse('IN');
    final dial = '+${(c?.phoneCode ?? '91').trim()}';
    final flag = c?.flagEmoji ?? '🇮🇳';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CustomTextField(
        controller: controller,
        label: label,
        hint: 'Phone number',
        inputType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        fillColor: AppColors.background.withValues(alpha: 0.70),
        borderColor: AppColors.ink.withValues(alpha: 0.10),
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        prefixIcon: InkWell(
          onTap: () {
            showCountryPicker(
              context: context,
              showPhoneCode: true,
              onSelect: (country) => onIsoChanged(country.countryCode),
            );
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
            ),
            child: Text(
              '$flag $dial',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.78),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VCardQrDialog extends StatelessWidget {
  const _VCardQrDialog({required this.vcf, required this.title});

  final String vcf;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.isNotEmpty ? title : 'My QR',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.ink.withValues(alpha: 0.08),
                ),
              ),
              child: QrImageView(
                data: vcf,
                version: QrVersions.auto,
                size: 240,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Scan to import my contact (vCard)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.62),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessCardSheet extends StatefulWidget {
  const _BusinessCardSheet({required this.data});

  final ProfileData data;

  static Future<void> open(ProfileData data) {
    return Get.bottomSheet<void>(
      _BusinessCardSheet(data: data),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<_BusinessCardSheet> createState() => _BusinessCardSheetState();
}

class _BusinessCardSheetState extends State<_BusinessCardSheet> {
  final GlobalKey _cardKey = GlobalKey();
  var _isSharing = false;

  Future<void> _shareCardImage(String vcf) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      final cardContext = _cardKey.currentContext;
      if (cardContext == null || !cardContext.mounted) return;

      final boundary = cardContext.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final view = ui.PlatformDispatcher.instance.views.first;
      final ratio = view.devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: ratio.clamp(2.0, 3.0));
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData?.buffer.asUint8List();
      if (pngBytes == null || pngBytes.isEmpty) return;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/business_card_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes, flush: true);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppColors.ink.withValues(alpha: 0.72)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              trimmed,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final name = data.fullName.trim();
    final designation = (data.designation ?? '').trim();
    final company = (data.companyName ?? '').trim();
    final email = data.email.trim();
    final secondaryEmail = (data.secondaryEmail ?? '').trim();
    final phone = (data.phone ?? '').trim();
    final secondaryPhone = (data.secondaryPhone ?? '').trim();
    final address = (data.address ?? '').trim();
    final website = (data.website ?? '').trim();
    final avatarUrl = (data.avatarUrl ?? '').trim();
    final vcf = _MyVCardQrFlow._vCardFromProfile(data);

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your Digital Business Card',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: RepaintBoundary(
                key: _cardKey,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.14),
                        AppColors.primary.withValues(alpha: 0.06),
                      ],
                    ),
                    border: Border.all(color: AppColors.ink.withValues(alpha: 0.10)),
                  ),
                  child: AspectRatio(
                    // Real-ish business card ratio (~3.5in x 2in => 1.75)
                    aspectRatio: 7 / 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.white.withValues(alpha: 0.65),
                                      backgroundImage: avatarUrl.startsWith('http')
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                      child: avatarUrl.startsWith('http')
                                          ? null
                                          : Icon(
                                              Icons.person_rounded,
                                              size: 24,
                                              color: AppColors.ink.withValues(alpha: 0.45),
                                            ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name.isNotEmpty ? name : '—',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  color: AppColors.ink,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                          if (designation.isNotEmpty)
                                            Text(
                                              designation,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.ink.withValues(alpha: 0.62),
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          if (company.isNotEmpty)
                                            Text(
                                              company,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelSmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.ink.withValues(alpha: 0.62),
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                _infoRow(
                                  context,
                                  icon: Icons.call_rounded,
                                  text: secondaryPhone.trim().isEmpty
                                      ? phone
                                      : '$phone, $secondaryPhone',
                                ),
                                _infoRow(
                                  context,
                                  icon: Icons.alternate_email_rounded,
                                  text: secondaryEmail.trim().isEmpty
                                      ? email
                                      : '$email, $secondaryEmail',
                                ),
                                _infoRow(
                                  context,
                                  icon: Icons.location_on_outlined,
                                  text: address,
                                ),
                                _infoRow(context, icon: Icons.public_rounded, text: website),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 82,
                            height: 82,
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.70),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.ink.withValues(alpha: 0.10)),
                            ),
                            child: QrImageView(
                              data: vcf,
                              version: QrVersions.auto,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSharing ? null : () => _shareCardImage(vcf),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: _isSharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.share_rounded),
                label: Text(
                  _isSharing ? 'Preparing…' : 'Share',
                  style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _HeaderActionIcon extends StatelessWidget {
  const _HeaderActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: AppColors.primary.withValues(alpha: 0.14),
          highlightColor: AppColors.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              color: AppColors.ink.withValues(alpha: 0.72),
              size: 23,
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final titleColor = danger ? const Color(0xFFB42318) : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.white,
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.04)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.background,
                  ),
                  child: Icon(
                    icon,
                    color: danger ? const Color(0xFFB42318) : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.ink.withValues(alpha: 0.28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
