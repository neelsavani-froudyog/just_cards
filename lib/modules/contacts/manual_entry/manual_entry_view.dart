import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_search_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import 'manual_entry_controller.dart';

class ManualEntryView extends GetView<ManualEntryController> {
  const ManualEntryView({super.key});

  Widget _cardHeader() {
    final radius = BorderRadius.circular(20);

    Widget child() {
      if (controller.hasCardImage) {
        return Obx(
          () => ClipRRect(
            borderRadius: radius,
            child: Image.file(
              File(controller.cardImagePath.value!),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        );
      }

      return Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppColors.darkGrey.withValues(alpha: 0.50),
              AppColors.darkGrey.withValues(alpha: 0.25),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.credit_card_rounded,
          size: 56,
          color: AppColors.white.withValues(alpha: 0.92),
        ),
      );
    }

    return Stack(
      children: [
        child(),
        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            color: AppColors.darkGrey,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: controller.pickCardImage,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.photo_camera_rounded, color: AppColors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _section({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
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
                child: Icon(icon, color: AppColors.darkGrey, size: 18),
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
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    IconData? suffixIcon,
    VoidCallback? onTap,
    TextInputType inputType = TextInputType.text,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      readOnly: readOnly,
      inputType: inputType,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      cursorColor: AppColors.darkGrey.withValues(alpha: 0.65),
      fillColor: const Color(0xFFF5F7FB),
      borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
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
      onTap: onTap,
      suffixIcon: suffixIcon == null
          ? null
          : Icon(suffixIcon, color: AppColors.darkGrey.withValues(alpha: 0.55)),
    );
  }

  Widget _tags(BuildContext context) {
    final theme = Theme.of(context);

    Widget chip(String text, {required bool selected}) {
      return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: InkWell(
          onTap: () => controller.toggleTag(text),
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

    return Obx(
      () => Wrap(
        children: [
          ...controller.selectedTags.map((t) => chip(t, selected: true)),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: InkWell(
              onTap: controller.openAddTagDialog,
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
      ),
    );
  }

  Widget _salutationDropdown(BuildContext context) {
    return Obx(
      () => CustomSearchDropdown<String>(
        items: controller.salutations,
        selectedItem: controller.salutation.value,
        hintText: 'Select salutation',
        label: 'Salutation',
        showSearchBox: false,
        itemAsString: (s) => s,
        onChanged: (v) {
          if (v != null) controller.salutation.value = v;
        },
        bgColor: const Color(0xFFF5F7FB),
        borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }

  Widget _organizationDropdown(BuildContext context) {
    return Obx(
      () => CustomSearchDropdown<String>(
        items: controller.organizations,
        selectedItem: controller.selectedOrganization.value,
        hintText: 'Select organization',
        label: 'Add to Organisation',
        showSearchBox: false,
        itemAsString: (s) => s,
        onChanged: controller.setOrganization,
        bgColor: const Color(0xFFF5F7FB),
        borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }

  Widget _eventDropdown(BuildContext context) {
    return Obx(
      () => CustomSearchDropdown<String>(
        items: controller.events,
        selectedItem: controller.selectedEvent.value,
        hintText: 'Select event',
        label: 'Associate with Event',
        showSearchBox: false,
        itemAsString: (s) => s,
        onChanged: controller.setEvent,
        bgColor: const Color(0xFFF5F7FB),
        borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }

  Widget _shareToggle(BuildContext context) {
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
          Obx(
            () => CupertinoSwitch(
              value: controller.shareWithOrganization.value,
              activeColor: activeGreen,
              onChanged: (value) => controller.shareWithOrganization.value = value,
            ),
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
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => OutlinedButton.icon(
                  onPressed: controller.isSaving.value ? null : () => Get.back(),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkGrey,
                    side: BorderSide(
                      color: AppColors.darkGrey.withValues(alpha: 0.18),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.isSaving.value ? null : controller.saveContact,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    controller.isSaving.value ? 'Saving...' : 'Save Contact',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGrey,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
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
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.darkGrey,
          onPressed: () => Get.back(),
        ),
        title: const Text('Manual Entry'),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardHeader(),
                    const SizedBox(height: 16),
                    _section(
                      context: context,
                      icon: Icons.person_rounded,
                      title: 'Contact Details',
                      child: Column(
                        children: [
                          _salutationDropdown(context),
                          const SizedBox(height: 14),
                          _field(
                            context: context,
                            label: 'First Name',
                            controller: controller.firstNameCtrl,
                            hint: 'First Name',
                          ),
                          const SizedBox(height: 14),
                          _field(
                            context: context,
                            label: 'Last Name',
                            controller: controller.lastNameCtrl,
                            hint: 'Last Name',
                          ),
                          const SizedBox(height: 14),
                          _field(
                            context: context,
                            label: 'Job Title',
                            controller: controller.jobTitleCtrl,
                            hint: 'Designation',
                          ),
                          const SizedBox(height: 14),
                          _field(
                            context: context,
                            label: 'Company',
                            controller: controller.companyCtrl,
                            hint: 'Company Name',
                          ),
                          const SizedBox(height: 14),
                          _field(
                            context: context,
                            label: 'Mobile',
                            controller: controller.mobileCtrl,
                            hint: 'Phone Number 1 ...',
                            inputType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            context: context,
                            label: 'Phone',
                            controller: controller.phoneCtrl,
                            hint: 'Phone number 2',
                            inputType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            context: context,
                            label: 'Primary Email',
                            controller: controller.primaryEmailCtrl,
                            hint: 'Email',
                            inputType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            context: context,
                            label: 'Secondary Email',
                            controller: controller.secondaryEmailCtrl,
                            hint: 'Email',
                            inputType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _section(
                      context: context,
                      icon: Icons.apartment_rounded,
                      title: 'Organization',
                      child: _organizationDropdown(context),
                    ),
                    const SizedBox(height: 18),
                    _section(
                      context: context,
                      icon: Icons.sell_rounded,
                      title: 'Event & Tags',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _eventDropdown(context),
                          const SizedBox(height: 14),
                          Text(
                            'Tags',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.darkGrey.withValues(alpha: 0.72),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 8),
                          _tags(context),
                          const SizedBox(height: 14),
                          _shareToggle(context),
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
