import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_cards/routes/app_routes.dart';

import '../../core/services/toast_service.dart';
import '../../core/theme/app_colors.dart';

import 'profile_controller.dart';
import 'profile_shimmer_view.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              sliver: SliverToBoxAdapter(child: _HeaderCard(controller: controller)),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Account',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w800,
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
                    onTap: () => ToastService.info('Coming soon'),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'General',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _SettingTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Support',
                    onTap: () => ToastService.info('Coming soon'),
                  ),
                  _SettingTile(
                    icon: Icons.policy_outlined,
                    title: 'Terms of Service',
                    onTap: () => ToastService.info('Coming soon'),
                  ),
                  _SettingTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: controller.onPrivacyPolicy,
                  ),
                  _SettingTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    danger: true,
                    onTap: () {
                      controller.onLogout();
                    },
                  ),
                  _SettingTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Account',
                    danger: true,
                    onTap: () => ToastService.info('Coming soon'),
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const ProfileHeaderShimmerCard();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.020),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
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
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.ink,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.displayName.value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          letterSpacing: -0.2,
                          color: AppColors.ink,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.email.value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
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
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: AppColors.white,
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.020),
                blurRadius: 10,
                offset: const Offset(0, 5),
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
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.accentTeal.withValues(alpha: 0.10),
                  ),
                  child: Icon(icon, color: AppColors.ink.withValues(alpha: 0.80)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: titleColor,
                        ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.ink.withValues(alpha: 0.35)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
