import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_search_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import 'create_event_controller.dart';

class CreateEventSheet extends StatelessWidget {
  const CreateEventSheet({super.key});

  static void open() {
    Get.bottomSheet(
      const CreateEventSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<CreateEventController>(
      init: CreateEventController(),
      global: false,
      builder: (c) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Create New Event',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: Get.back,
                        borderRadius: BorderRadius.circular(999),
                        child: Ink(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.ink.withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded, color: AppColors.ink.withValues(alpha: 0.75)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                    controller: c.nameController,
                    hint: 'e.g. Electronica Expo 2026',
                    borderRadius: 12,
                    filled: true,
                    fillColor: const Color(0xFFF5F7FB),
                    borderColor: AppColors.ink.withValues(alpha: 0.10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    onChanged: (_) => c.errorText.value = null,
                  ),
                  const SizedBox(height: 10),
                  Obx(() {
                    final err = c.errorText.value;
                    if (err == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        err,
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.danger),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _SmallField(
                          label: 'DATE',
                          child: Obx(() {
                            return CustomTextField(
                              hint: c.dateLabel,
                              readOnly: true,
                              onTap: () => c.pickDate(context),
                              borderRadius: 12,
                              filled: true,
                              fillColor: const Color(0xFFF5F7FB),
                              borderColor: AppColors.ink.withValues(alpha: 0.10),
                              prefixIcon: Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.ink.withValues(alpha: 0.55)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SmallField(
                          label: 'LOCATION',
                          child: CustomTextField(
                            controller: c.locationController,
                            hint: 'Greater Noida, UP',
                            borderRadius: 12,
                            filled: true,
                            fillColor: const Color(0xFFF5F7FB),
                            borderColor: AppColors.ink.withValues(alpha: 0.10),
                            prefixIcon: Icon(Icons.location_on_rounded, size: 18, color: AppColors.ink.withValues(alpha: 0.55)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                    controller: c.notesController,
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
                    return CustomSearchDropdown<String>(
                      items: c.organizations,
                      selectedItem: c.selectedOrganization.value,
                      hintText: 'None',
                      showSearchBox: false,
                      itemAsString: (s) => s,
                      onChanged: c.setOrganization,
                      bgColor: const Color(0xFFF5F7FB),
                      borderColor: AppColors.ink.withValues(alpha: 0.10),
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    );
                  }),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Obx(() {
                      final busy = c.isSaving.value;
                      return FilledButton(
                        onPressed: busy ? null : c.save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: busy
                              ? const SizedBox(
                                  key: ValueKey('loading'),
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  'Save Event',
                                  key: const ValueKey('label'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
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
      },
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

