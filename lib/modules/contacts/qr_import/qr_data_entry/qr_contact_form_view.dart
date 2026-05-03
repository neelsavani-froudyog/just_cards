import 'dart:io';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_cards/modules/contacts/qr_import/qr_data_entry/qr_contact_controller.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/custom_search_dropdown.dart';
import '../../../../widgets/custom_text_field.dart';

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

class QrContactFormView extends GetView<QrContactController> {
  const QrContactFormView({super.key});

  Widget _cardHeader() {
    final radius = BorderRadius.circular(16);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.pickCardImage,
        borderRadius: radius,
        child: Obx(() {
          final imagePath = controller.cardImagePath.value;
          final hasImage = imagePath != null && imagePath.isNotEmpty;

          return Stack(
            children: [
              if (hasImage)
                ClipRRect(
                  borderRadius: radius,
                  child: Image.file(
                    File(imagePath),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.fill,
                    errorBuilder: (_, __, ___) {
                      return _manualCardPlaceholder(radius);
                    },
                  ),
                )
              else
                _manualCardPlaceholder(radius),
              Positioned(
                right: 12,
                bottom: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.16),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _manualCardPlaceholder(BorderRadius radius) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: AppColors.ink.withValues(alpha: 0.04),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.credit_card_rounded,
        size: 56,
        color: AppColors.ink.withValues(alpha: 0.22),
      ),
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
                child: Icon(icon, color: AppColors.primary, size: 18),
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
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    IconData? suffixIcon,
    VoidCallback? onTap,
    TextInputType inputType = TextInputType.text,
    int? maxLength,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hint: hint,
      maxLength: maxLength,
      readOnly: readOnly,
      inputType: inputType,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      cursorColor: AppColors.ink.withValues(alpha: 0.65),
      fillColor: const Color(0xFFF5F7FB),
      borderColor: AppColors.ink.withValues(alpha: 0.10),
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
      onTap: onTap,
      suffixIcon:
          suffixIcon == null
              ? null
              : Icon(suffixIcon, color: AppColors.ink.withValues(alpha: 0.55)),
    );
  }

  void _openCountryPicker(BuildContext context, {required bool isPhone1}) {
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
        if (isPhone1) {
          controller.setPhone1Country(c);
        } else {
          controller.setPhone2Country(c);
        }
      },
    );
  }

  Widget _phoneFieldWithCountry({
    required BuildContext context,
    required String label,
    required TextEditingController textController,
    required String hint,
    required bool isPhone1,
  }) {
    final theme = Theme.of(context);
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
        Obx(() {
          final iso =
              isPhone1
                  ? controller.phone1CountryIso.value
                  : controller.phone2CountryIso.value;
          final country = Country.tryParse(iso) ?? Country.parse('IN');
          final isIndiaCode = country.phoneCode == '91';
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openCountryPicker(context, isPhone1: isPhone1),
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
          );
        }),
      ],
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

    return Obx(
      () => Wrap(
        children: [
          ...controller.selectedTags.map((t) => chip(t, selected: true)),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: InkWell(
              onTap: controller.openAddTagDialog,
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
        borderColor: AppColors.ink.withValues(alpha: 0.10),
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
        borderColor: AppColors.ink.withValues(alpha: 0.10),
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
        borderColor: AppColors.ink.withValues(alpha: 0.10),
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }

  Widget _shareToggle(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.10)),
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
          Obx(
            () => CupertinoSwitch(
              value: controller.shareWithOrganization.value,
              activeTrackColor: AppColors.primary,
              onChanged:
                  (value) => controller.shareWithOrganization.value = value,
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
            top: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => OutlinedButton.icon(
                  onPressed:
                      controller.isSaving.value ? null : () => Get.back(),
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(
                () => ElevatedButton.icon(
                  onPressed:
                      controller.isSaving.value ? null : controller.saveContact,
                  icon: const Icon(Icons.check_rounded),
                  label: Text(
                    controller.isSaving.value ? 'Saving...' : 'Save Contact',
                  ),
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
        title: Text(controller.qrImportTitle),
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
                    _cardHeader(),
                    const SizedBox(height: 8),
                    Text(
                      'Business card image (optional)',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                            label: 'Full Name',
                            controller: controller.fullNameCtrl,
                            hint: 'Full name',
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
                            label: 'Designation',
                            controller: controller.jobTitleCtrl,
                            hint: 'Designation',
                          ),
                           const SizedBox(height: 14),
                          _phoneFieldWithCountry(
                            context: context,
                            label: 'Mobile',
                            textController: controller.mobileCtrl,
                            hint: 'Phone Number 1 ...',
                            isPhone1: true,
                          ),
                          const SizedBox(height: 14),
                          _phoneFieldWithCountry(
                            context: context,
                            label: 'Phone',
                            textController: controller.phoneCtrl,
                            hint: 'Phone number 2',
                            isPhone1: false,
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
                          const SizedBox(height: 14),
                          _field(
                            context: context,
                            label: 'Website',
                            controller: controller.websiteCtrl,
                            hint: 'Website',
                            inputType: TextInputType.url,
                          ),
                          const SizedBox(height: 14),
                          _field(
                            context: context,
                            label: 'Address',
                            controller: controller.addressCtrl,
                            hint: 'Address',
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
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(
                              color: AppColors.ink.withValues(alpha: 0.72),
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
