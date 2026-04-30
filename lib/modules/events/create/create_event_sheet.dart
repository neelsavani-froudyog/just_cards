import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_search_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import 'create_event_controller.dart';

class CreateEventSheet extends StatelessWidget {
  const CreateEventSheet({super.key});

  static Future<dynamic> open() {
    return Get.bottomSheet(
      const CreateEventSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final maxSheetHeight = media.size.height * 0.86;

    return GetBuilder<CreateEventController>(
      init: CreateEventController(),
      global: false,
      builder: (c) {
        return SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: keyboardInset > 0 ? 0.84 : 0.78,
            minChildSize: 0.62,
            maxChildSize: 0.86,
            builder: (context, scrollController) {
              return Container(
                constraints: BoxConstraints(maxHeight: maxSheetHeight),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    // FocusManager.instance.primaryFocus?.unfocus();
                    return false;
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                        child: Column(
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
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.event_available_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Create New Event',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              color: AppColors.ink,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Add an event to group scans and contacts.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppColors.ink.withValues(
                                                alpha: 0.55,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: Get.back,
                                  borderRadius: BorderRadius.circular(999),
                                  child: Ink(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.ink.withValues(
                                        alpha: 0.06,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: AppColors.ink.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.ink.withValues(alpha: 0.06),
                      ),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
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
                              controller: c.nameController,
                              hint: 'e.g. Electronica Expo',
                              borderRadius: 12,
                              filled: true,
                              fillColor: const Color(0xFFF5F7FB),
                              borderColor: AppColors.ink.withValues(
                                alpha: 0.10,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
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
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.danger,
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _SmallField(
                                    label: 'DATE',
                                    child: CustomTextField(
                                      controller: c.dateController,
                                      readOnly: true,
                                      onTap: () => c.pickDate(context),
                                      borderRadius: 12,
                                      filled: true,
                                      fillColor: const Color(0xFFF5F7FB),
                                      borderColor: AppColors.ink.withValues(
                                        alpha: 0.10,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.calendar_today_rounded,
                                        size: 18,
                                        color: AppColors.ink.withValues(
                                          alpha: 0.55,
                                        ),
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
                                      controller: c.locationController,
                                      hint: 'Greater Noida, UP',
                                      borderRadius: 12,
                                      filled: true,
                                      fillColor: const Color(0xFFF5F7FB),
                                      borderColor: AppColors.ink.withValues(
                                        alpha: 0.10,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.location_on_rounded,
                                        size: 18,
                                        color: AppColors.ink.withValues(
                                          alpha: 0.55,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      onChanged:
                                          (_) =>
                                              c.locationErrorText.value = null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Obx(() {
                              final err = c.locationErrorText.value;
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
                              controller: c.notesController,
                              hint: 'Optional notes…',
                              minLines: 4,
                              maxLines: 4,
                              borderRadius: 12,
                              filled: true,
                              fillColor: const Color(0xFFF5F7FB),
                              borderColor: AppColors.ink.withValues(
                                alpha: 0.10,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
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
                                  c.isOrganizationsLoading.value;
                              return CustomSearchDropdown<String>(
                                dropdownMaxHeight: 220,
                                items: c.organizations,
                                selectedItem: c.selectedOrganization.value,
                                hintText: 'None',
                                showSearchBox: false,
                                itemAsString: (s) => s,
                                onChanged: c.setOrganization,
                                enabled: !loadingOrganizations,
                                bgColor: const Color(0xFFF5F7FB),
                                borderColor: AppColors.ink.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: 12,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                showShadow: false,
                                searchHintText: 'Search organization',
                              );
                            }),
                            SizedBox(height: 14 + media.padding.bottom),
                          ],
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Container(
                          padding: EdgeInsets.fromLTRB(
                            18,
                            10,
                            18,
                            12 + (keyboardInset > 0 ? 0 : 0),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            border: Border(
                              top: BorderSide(
                                color: AppColors.ink.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      c.isSaving.value
                                          ? null
                                          : () => Get.back(),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text('Cancel'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.ink,
                                    side: BorderSide(
                                      color: AppColors.ink.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Obx(() {
                                  final busy = c.isSaving.value;
                                  return ElevatedButton.icon(
                                    onPressed: busy ? null : c.save,
                                    icon:
                                        busy
                                            ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.white,
                                              ),
                                            )
                                            : const Icon(Icons.check_rounded),
                                    label: Text(
                                      busy ? 'Saving...' : 'Save Event',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
