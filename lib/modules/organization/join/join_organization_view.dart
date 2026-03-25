import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import 'join_organization_controller.dart';

class JoinOrganizationView extends GetView<JoinOrganizationController> {
  const JoinOrganizationView({super.key});

  List<_AbilitySpec> _abilitiesForRole(String roleRaw) {
    final role = roleRaw.trim().toLowerCase();

    // Viewer
    if (role.contains('viewer')) {
      return const [
        _AbilitySpec(
          icon: Icons.contacts_rounded,
          title: 'Contacts view',
          subtitle: 'Browse and search shared contacts in the organisation',
        ),
        _AbilitySpec(
          icon: Icons.event_rounded,
          title: 'Events view',
          subtitle: 'View organisation events you have access to',
        ),
        _AbilitySpec(
          icon: Icons.visibility_rounded,
          title: 'View shared contacts',
          subtitle: "Access the team’s shared business card database",
        ),
      ];
    }

    // Editor
    if (role.contains('editor')) {
      return const [
        _AbilitySpec(
          icon: Icons.document_scanner_rounded,
          title: 'Card scan & add contacts',
          subtitle: 'Scan business cards and add contacts to shared lists',
        ),
        _AbilitySpec(
          icon: Icons.edit_rounded,
          title: 'Edit contact details',
          subtitle: 'Update and refine information on shared contacts',
        ),
        _AbilitySpec(
          icon: Icons.visibility_rounded,
          title: 'View shared contacts',
          subtitle: "Access the team’s shared business card database",
        ),
      ];
    }

    // Admin (default)
    return const [
      _AbilitySpec(
        icon: Icons.document_scanner_rounded,
        title: 'Card scan & add contacts',
        subtitle: 'Scan business cards and add contacts to shared lists',
      ),
      _AbilitySpec(
        icon: Icons.edit_rounded,
        title: 'Edit contact details',
        subtitle: 'Update and refine information on shared contacts',
      ),
      _AbilitySpec(
        icon: Icons.visibility_rounded,
        title: 'View shared contacts',
        subtitle: "Access the team’s shared business card database",
      ),
      _AbilitySpec(
        icon: Icons.ios_share_rounded,
        title: 'Contact export',
        subtitle: 'Export shared contacts when needed',
      ),
      _AbilitySpec(
        icon: Icons.add_circle_outline_rounded,
        title: 'New event create',
        subtitle: 'Create new events for your organisation',
      ),
      _AbilitySpec(
        icon: Icons.person_add_alt_rounded,
        title: 'New member invite',
        subtitle: 'Invite members and manage organisation access',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = controller.args;
    final abilities = _abilitiesForRole(a.role);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text('Join Organization'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primaryLight.withValues(alpha: 0.85),
                            AppColors.primary.withValues(alpha: 0.25),
                          ],
                        ),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
                      ),
                      child: Icon(Icons.apartment_rounded, size: 40, color: AppColors.ink.withValues(alpha: 0.78)),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      a.orgName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Invited as ${a.role}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Invited by ${a.invitedBy}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 24),
                    Text(
                      "WHAT YOU’LL BE ABLE TO DO",
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...abilities.expand(
                      (a) => [
                        _AbilityTile(
                          icon: a.icon,
                          title: a.title,
                          subtitle: a.subtitle,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.ink.withValues(alpha: 0.06),
                            ),
                            child: Icon(Icons.info_outline_rounded, color: AppColors.ink.withValues(alpha: 0.70)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Only contacts shared with the organisation will be visible to you.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.70),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Obx(() {
                      final busy = controller.isWorking.value;
                      return FilledButton(
                        onPressed: busy ? null : controller.acceptAndJoin,
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
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                                )
                              : Row(
                                  key: const ValueKey('label'),
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Accept & Join',
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
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Obx(() {
                      final busy = controller.isWorking.value;
                      return OutlinedButton(
                        onPressed: busy ? null : controller.decline,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.ink.withValues(alpha: 0.18)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Decline Invitation',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.80),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, color: AppColors.ink.withValues(alpha: 0.55), size: 18),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AbilityTile extends StatelessWidget {
  const _AbilityTile({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withValues(alpha: 0.45),
            ),
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
        ],
      ),
    );
  }
}

class _AbilitySpec {
  const _AbilitySpec({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

