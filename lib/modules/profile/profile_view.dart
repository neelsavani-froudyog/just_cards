import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_cards/routes/app_routes.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/confirm_dialog.dart';

import 'profile_controller.dart';
import 'profile_shimmer_view.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: false,
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.ink.withValues(alpha: 0.06),
          ),
        ),
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
                  'ACCOUNT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.42),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
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
                    onTap: () => Get.toNamed(Routes.editProfile),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'GENERAL',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.42),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                18,
                0,
                18,
                16 + MediaQuery.of(context).padding.bottom,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _SettingTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Support',
                    onTap: () => Get.toNamed(Routes.support),
                  ),
                  _SettingTile(
                    icon: Icons.policy_outlined,
                    title: 'Terms of Service',
                    onTap: () => Get.toNamed(Routes.termsConditions),
                  ),
                  _SettingTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => Get.toNamed(Routes.privacyPolicy),
                  ),
                  _SettingTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About Us',
                    onTap: () => Get.toNamed(Routes.aboutUs),
                  ),
                  _SettingTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    danger: true,
                    onTap: () {
                      ConfirmDialog.show(
                        title: 'Log out?',
                        message: 'You will need to sign in again to access your account.',
                        confirmText: 'Logout',
                        destructive: true,
                      ).then((ok) {
                        if (ok) controller.onLogout();
                      });
                    },
                  ),
                  _SettingTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Account',
                    danger: true,
                    onTap: () {
                      ConfirmDialog.show(
                        title: 'Delete account?',
                        message:
                            'This will permanently delete your account and data. This cannot be undone.',
                        confirmText: 'Delete',
                        destructive: true,
                      ).then((ok) {
                        if (ok) controller.deleteAccount();
                      });
                    },
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

  Color _avatarColorFor(String seed) {
    const palette = <Color>[
      Color(0xFF0D8A4E),
      Color(0xFF0A66C2),
      Color(0xFF7B2FC7),
      Color(0xFFC47A00),
      Color(0xFF0D6C8A),
      Color(0xFFB00020),
    ];
    if (seed.trim().isEmpty) return palette.first;
    final idx = seed.codeUnits.fold<int>(0, (a, b) => (a + b) % palette.length);
    return palette[idx];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const ProfileHeaderShimmerCard();
      }
      final avatarUrl = controller.profileMe.value?.data?.avatarUrl?.trim() ?? '';
      final name = controller.displayName.value.trim();
      final email = controller.email.value.trim();
      final initials = name.isEmpty ? 'U' : name.characters.first.toUpperCase();
      final avatarBg = _avatarColorFor('$name|$email');

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarBg,
                border: Border.all(color: AppColors.primary,width: 2)
              ),
              child: ClipOval(
                child: avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            initials,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initials,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.displayName.value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          letterSpacing: -0.2,
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.email.value,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.62),
                          fontWeight: FontWeight.w600,
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
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.white,
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.04)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.04),
                blurRadius: 2,
                offset: const Offset(0, 1),
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
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.background,
                  ),
                  child: Icon(
                    icon,
                    color: danger
                        ? const Color(0xFFB42318)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.ink.withValues(alpha: 0.28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
