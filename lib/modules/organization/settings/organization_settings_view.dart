import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import 'organization_settings_controller.dart';

class OrganizationSettingsView extends GetView<OrganizationSettingsController> {
  const OrganizationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = controller.args;

    return Scaffold(
      backgroundColor: AppColors.lightHubBg,
      appBar: AppBar(
        backgroundColor: AppColors.lightHubSurface,
        elevation: 0,
        foregroundColor: AppColors.lightHubInk,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Organization Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.lightHubInk,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.lightHubInk,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.industry?.isNotEmpty == true ? a.industry! : 'General',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.lightHubMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Policies',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.lightHubInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightHubSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.lightHubBorder),
                      ),
                      child: Column(
                        children: [
                          _SettingTile(
                            title: 'Private by default',
                            subtitle:
                                'New contacts are hidden from other members by default',
                            value: controller.isPrivateByDefault,
                          ),
                          Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: AppColors.lightHubBorder,
                          ),
                          _SettingTile(
                            title: 'Export allowed',
                            subtitle:
                                'Allow members to export contacts to CSV/Excel',
                            value: controller.isExportAllowed,
                          ),
                          Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: AppColors.lightHubBorder,
                          ),
                          _SettingTile(
                            title: 'Admin approval',
                            subtitle:
                                'Require admin approval for new members joining',
                            value: controller.isAdminApprovalRequired,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Obx(() {
                final busy = controller.isSaving.value;
                return SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : controller.save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: busy
                          ? const SizedBox(
                              key: ValueKey('l'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.white,
                              ),
                            )
                          : Text(
                              key: const ValueKey('t'),
                              'Save changes',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.lightHubInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.lightHubMuted,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
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
