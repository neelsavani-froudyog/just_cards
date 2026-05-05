import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../../core/theme/app_colors.dart';
import 'edit_profile_controller.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        title: const Text('Edit Profile'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Column(
                  children: [
                    _HeaderCard(controller: controller),
                    const SizedBox(height: 14),
                    _FormCard(controller: controller),
                  ],
                ),
              ),
            ),
            _BottomBar(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.controller});

  final EditProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.020),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _AvatarPicker(controller: controller),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Photo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap to change your photo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.controller});

  final EditProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final url = controller.avatarUrl.value.trim();
      final uploading = controller.isUploadingAvatar.value;

      return InkWell(
        onTap:
            uploading
                ? null
                : () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  backgroundColor: AppColors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                  ),
                  builder:
                      (_) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SheetTile(
                                icon: Icons.photo_library_outlined,
                                title: 'Choose from gallery',
                                onTap: () {
                                  Get.back();
                                  controller.pickAndUploadAvatar(
                                    source: ImageSource.gallery,
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _SheetTile(
                                icon: Icons.photo_camera_outlined,
                                title: 'Take a photo',
                                onTap: () {
                                  Get.back();
                                  controller.pickAndUploadAvatar(
                                    source: ImageSource.camera,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
        borderRadius: BorderRadius.circular(999),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.75),
                  width: 3,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.primaryLight.withValues(alpha: 0.24),
                  ],
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  url.isEmpty
                      ? const Icon(
                        Icons.person_rounded,
                        color: AppColors.ink,
                        size: 34,
                      )
                      : (url.startsWith('http://') ||
                          url.startsWith('https://'))
                      ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: AppColors.ink,
                              size: 34,
                            ),
                      )
                      : Image.file(
                        File(url),
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => const Icon(
                              Icons.person_rounded,
                              color: AppColors.ink,
                              size: 34,
                            ),
                      ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color:
                    uploading
                        ? AppColors.ink.withValues(alpha: 0.15)
                        : AppColors.ink,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 3),
              ),
              child:
                  uploading
                      ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      )
                      : const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: AppColors.white,
                      ),
            ),
          ],
        ),
      );
    });
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.controller});

  final EditProfileController controller;

  void _openCountryPicker(
    BuildContext context, {
    required void Function(Country) onSelect,
  }) {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      favorite: const <String>['IN', 'US', 'NZ'],
      searchAutofocus: false,
      countryListTheme: CountryListThemeData(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      onSelect: onSelect,
    );
  }

  Widget _phoneFieldWithCountry(
    BuildContext context, {
    required bool enabled,
    required String label,
    required RxString isoRx,
    required TextEditingController textController,
    required void Function(Country) onCountrySelect,
    required String hintText,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.70),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final iso = isoRx.value;
          final country =
              CountryService().findByCode(iso) ??
              CountryService().findByCode('IN');
          final phoneCode = country?.phoneCode ?? '91';
          final flag = country?.flagEmoji ?? '🇮🇳';
          return Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      enabled
                          ? () => _openCountryPicker(
                            context,
                            onSelect: onCountrySelect,
                          )
                          : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fieldFill.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.ink.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Text(
                          '+$phoneCode',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.90),
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
                child: TextField(
                  controller: textController,
                  enabled: enabled,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(hintText: hintText),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.018),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Obx(() {
        final loading = controller.isLoading.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Full name',
              child: TextField(
                controller: controller.fullNameController,
                enabled: !loading,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(hintText: 'Enter your full name'),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Company name',
              child: TextField(
                controller: controller.companyNameController,
                enabled: !loading,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  hintText: 'Enter company name (optional)',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Designation',
              child: TextField(
                controller: controller.designationController,
                enabled: !loading,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  hintText: 'Enter designation (optional)',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _phoneFieldWithCountry(
              context,
              enabled: !loading,
              label: 'Phone',
              isoRx: controller.phoneCountryIso,
              textController: controller.phoneController,
              onCountrySelect: controller.setPhoneCountry,
              hintText: 'Enter phone number',
            ),
            const SizedBox(height: 12),
            _phoneFieldWithCountry(
              context,
              enabled: !loading,
              label: 'Secondary phone (optional)',
              isoRx: controller.secondaryPhoneCountryIso,
              textController: controller.secondaryPhoneController,
              onCountrySelect: controller.setSecondaryPhoneCountry,
              hintText: 'Enter secondary phone number',
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Email',
              child: TextField(
                controller: controller.emailController,
                enabled: false,
                decoration: _inputDecoration(hintText: '—'),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Secondary email (optional)',
              child: TextField(
                controller: controller.secondaryEmailController,
                enabled: !loading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(hintText: 'Enter secondary email'),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Website (optional)',
              child: TextField(
                controller: controller.websiteController,
                enabled: !loading,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  hintText: 'https://example.com',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Address (optional)',
              child: TextField(
                controller: controller.addressController,
                enabled: !loading,
                maxLines: 2,
                textInputAction: TextInputAction.newline,
                decoration: _inputDecoration(
                  hintText: 'Enter address (optional)',
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: AppColors.fieldFill.withValues(alpha: 0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.ink.withValues(alpha: 0.06)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.60),
          width: 1.2,
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.70),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller});

  final EditProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.ink.withValues(alpha: 0.06)),
        ),
      ),
      child: Obx(() {
        final saving = controller.isSaving.value;
        final uploading = controller.isUploadingAvatar.value;

        return SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (saving || uploading) ? null : controller.save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child:
                saving
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                    : const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
          ),
        );
      }),
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.primary.withValues(alpha: 0.06),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.white,
                border: Border.all(
                  color: AppColors.ink.withValues(alpha: 0.06),
                ),
              ),
              child: Icon(icon, color: AppColors.ink.withValues(alpha: 0.85)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.ink.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}
