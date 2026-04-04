import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_field.dart';
import 'edit_contact_controller.dart';

class EditContactView extends GetView<EditContactController> {
  const EditContactView({super.key});

  static const _fill = Color(0xFFF5F7FB);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.darkGrey,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Edit Contact',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.darkGrey,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final err = controller.errorText.value;
          if (err != null && err.trim().isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      err,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.darkGrey.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: controller.fetchContact,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    16,
                    18,
                    // Extra scroll extent when keyboard overlaps (e.g. focus on lower fields).
                    24 + (keyboardInset > 0 ? keyboardInset - 60 : 0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(context, 'First name'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: controller.firstNameCtrl,
                        hint: 'First name',
                        borderRadius: 12,
                        filled: true,
                        fillColor: _fill,
                        borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label(context, 'Last name'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: controller.lastNameCtrl,
                        hint: 'Last name',
                        borderRadius: 12,
                        filled: true,
                        fillColor: _fill,
                        borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label(context, 'Email 1'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: controller.email1Ctrl,
                        hint: 'Email',
                        inputType: TextInputType.emailAddress,
                        borderRadius: 12,
                        filled: true,
                        fillColor: _fill,
                        borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label(context, 'Email 2'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: controller.email2Ctrl,
                        hint: 'Email (optional)',
                        inputType: TextInputType.emailAddress,
                        borderRadius: 12,
                        filled: true,
                        fillColor: _fill,
                        borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label(context, 'Phone 1'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: controller.phone1Ctrl,
                        hint: 'Mobile / primary phone',
                        inputType: TextInputType.phone,
                        borderRadius: 12,
                        filled: true,
                        fillColor: _fill,
                        borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label(context, 'Phone 2'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: controller.phone2Ctrl,
                        hint: 'Secondary phone (optional)',
                        inputType: TextInputType.phone,
                        borderRadius: 12,
                        filled: true,
                        fillColor: _fill,
                        borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label(context, 'Address'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: controller.addressCtrl,
                        hint: 'Address',
                        minLines: 2,
                        maxLines: 4,
                        borderRadius: 12,
                        filled: true,
                        fillColor: _fill,
                        borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label(context, 'Designation'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: controller.designationCtrl,
                        hint: 'Job title / designation',
                        borderRadius: 12,
                        filled: true,
                        fillColor: _fill,
                        borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label(context, 'Company name'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: controller.companyCtrl,
                        hint: 'Company name',
                        borderRadius: 12,
                        filled: true,
                        fillColor: _fill,
                        borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label(context, 'Website'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: controller.websiteCtrl,
                        hint: 'Website',
                        inputType: TextInputType.url,
                        borderRadius: 12,
                        filled: true,
                        fillColor: _fill,
                        borderColor: AppColors.darkGrey.withValues(alpha: 0.10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    top: BorderSide(
                      color: AppColors.darkGrey.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
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
                        child: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : Text(
                                'Save changes',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.darkGrey.withValues(alpha: 0.72),
            fontWeight: FontWeight.w800,
          ),
    );
  }
}
