import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_search_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import 'edit_event_controller.dart';

class EditEventView extends GetView<EditEventController> {
  const EditEventView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          'Edit Event',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'EVENT NAME *',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: controller.nameController,
                hint: 'e.g. Electronica Expo',
                borderRadius: 12,
                filled: true,
                fillColor: const Color(0xFFF5F7FB),
                borderColor: AppColors.ink.withValues(alpha: 0.10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onChanged: (_) => controller.errorText.value = null,
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SmallField(
                      label: 'DATE',
                      child: CustomTextField(
                        controller: controller.dateController,
                        readOnly: true,
                        onTap: () => controller.pickDate(context),
                        borderRadius: 12,
                        filled: true,
                        fillColor: const Color(0xFFF5F7FB),
                        borderColor: AppColors.ink.withValues(alpha: 0.10),
                        prefixIcon: Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppColors.ink.withValues(alpha: 0.55),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SmallField(
                      label: 'LOCATION',
                      child: CustomTextField(
                        controller: controller.locationController,
                        hint: 'Greater Noida, UP',
                        borderRadius: 12,
                        filled: true,
                        fillColor: const Color(0xFFF5F7FB),
                        borderColor: AppColors.ink.withValues(alpha: 0.10),
                        prefixIcon: Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: AppColors.ink.withValues(alpha: 0.55),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        onChanged: (_) =>
                            controller.locationErrorText.value = null,
                      ),
                    ),
                  ),
                ],
              ),
              Obx(() {
                final err = controller.locationErrorText.value;
                if (err == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      err,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 14),
              Text(
                'NOTES',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: controller.notesController,
                hint: 'e.g. Electronica Expo 2026',
                minLines: 4,
                maxLines: 4,
                borderRadius: 12,
                filled: true,
                fillColor: const Color(0xFFF5F7FB),
                borderColor: AppColors.ink.withValues(alpha: 0.10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              const SizedBox(height: 14),
              Text(
                'Organization (Optional)',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.60),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() {
                final loadingOrganizations =
                    controller.isOrganizationsLoading.value;
                return CustomSearchDropdown<String>(
                  dropdownMaxHeight: 100,
                  items: controller.organizations,
                  selectedItem: controller.selectedOrganization.value,
                  hintText: 'None',
                  showSearchBox: false,
                  itemAsString: (s) => s,
                  onChanged: controller.setOrganization,
                  enabled: !loadingOrganizations,
                  bgColor: const Color(0xFFF5F7FB),
                  borderColor: AppColors.ink.withValues(alpha: 0.10),
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  showShadow: true,
                  searchHintText: 'Search organization',
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Obx(() {
                  final busy = controller.isSaving.value;
                  return FilledButton(
                    onPressed: busy ? null : controller.save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: busy
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              'Update Event',
                              key: const ValueKey('label'),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  const _SmallField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.55),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
