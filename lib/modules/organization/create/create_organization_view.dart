import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/custom_search_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import 'create_organization_controller.dart';

class CreateOrganizationView extends GetView<CreateOrganizationController> {
  const CreateOrganizationView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('Create Organization', style: theme.textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel(
                      label: 'Organization Name',
                      required: true,
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: controller.organizationNameController,
                      hint: 'e.g. Electronica Expo ..',
                      inputType: TextInputType.text,
                      borderRadius: 10,
                      filled: true,
                      fillColor: AppColors.white,
                      borderColor: AppColors.ink.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      onChanged: (_) => controller.errorText.value = null,
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel(
                      label: 'Industry',
                      optional: true,
                    ),
                    const SizedBox(height: 8),
                    _DropdownField(
                      value: controller.selectedIndustry,
                      hint: 'Select industry',
                      items: controller.industries,
                      onChanged: controller.setIndustry,
                    ),
                    Obx(() {
                      final showCustomIndustry =
                          controller.selectedIndustry.value == 'Other';
                      if (!showCustomIndustry) {
                        return const SizedBox(height: 14);
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          const _FieldLabel(
                            label: 'Industry Name',
                            required: true,
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: controller.otherIndustryController,
                            hint: 'Enter industry name',
                            inputType: TextInputType.text,
                            borderRadius: 10,
                            filled: true,
                            fillColor: AppColors.white,
                            borderColor: AppColors.ink.withValues(alpha: 0.08),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            onChanged: (_) => controller.errorText.value = null,
                          ),
                          const SizedBox(height: 14),
                        ],
                      );
                    }),
                    const _FieldLabel(label: 'Your Role'),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: controller.roleController,
                      hint: 'Owner',
                      readOnly: true,
                      enabled: false,
                      borderRadius: 10,
                      filled: true,
                      fillColor: AppColors.white,
                      borderColor: AppColors.ink.withValues(alpha: 0.08),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      textStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Organization Settings', style: AppTextStyles.sectionTitle(context)),
                    const SizedBox(height: 10),
                    _SettingsCard(controller: controller),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: Obx(() {
                  final busy = controller.isSubmitting.value;
                  return FilledButton(
                    onPressed: busy ? null : controller.submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: busy
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                            )
                          : Row(
                              key: const ValueKey('label'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create Organization',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward_rounded, color: AppColors.white, size: 18),
                              ],
                            ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.required = false, this.optional = false});

  final String label;
  final bool required;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.70),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (required)
            TextSpan(
              text: ' *',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (optional)
            TextSpan(
              text: ' (Optional)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final RxnString value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return CustomSearchDropdown<String>(
        items: items,
        selectedItem: value.value,
        hintText: hint,
        showSearchBox: true,
        itemAsString: (s) => s,
        onChanged: onChanged,
        bgColor: AppColors.white,
        borderColor: AppColors.ink.withValues(alpha: 0.08),
        borderRadius: 10,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      );
    });
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.controller});

  final CreateOrganizationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _SettingTile(
            title: 'Private by default',
            subtitle: 'New Contacts are hidden from other members by default',
            value: controller.isPrivateByDefault,
          ),
          const _Divider(),
          _SettingTile(
            title: 'Export allowed',
            subtitle: 'Allow org members to export contacts to CSV/Excel',
            value: controller.isExportAllowed,
          ),
          const _Divider(),
          _SettingTile(
            title: 'Admin approval',
            subtitle: 'Require admin approval for new member joining',
            value: controller.isAdminApprovalRequired,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 18, color: AppColors.ink.withValues(alpha: 0.08)),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final RxBool value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Obx(() {
            return CupertinoSwitch(
              value: value.value,
              onChanged: (v) => value.value = v,
              activeTrackColor: AppColors.buttonColor,
            );
          }),
        ],
      ),
    );
  }
}

