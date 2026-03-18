import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import 'notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text('Notifications'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invitations',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  hint: 'Search organisation, role, invited by…',
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.ink.withValues(alpha: 0.55)),
                  borderRadius: 12,
                  filled: true,
                  fillColor: Colors.white,
                  borderColor: AppColors.ink.withValues(alpha: 0.10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  onChanged: controller.setQuery,
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final selected = controller.filter.value;
                  Widget chip(InviteFilter f, String label) {
                    final active = selected == f;
                    final count = controller.countFor(f);
                    return InkWell(
                      onTap: () => controller.setFilter(f),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary.withValues(alpha: 0.16) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active ? AppColors.primary.withValues(alpha: 0.55) : AppColors.ink.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: active ? AppColors.ink : AppColors.ink.withValues(alpha: 0.70),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: active ? AppColors.primary : AppColors.ink.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$count',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: active ? Colors.white : AppColors.ink.withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 46,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        chip(InviteFilter.all, 'All'),
                        const SizedBox(width: 10),
                        chip(InviteFilter.pending, 'Pending'),
                        const SizedBox(width: 10),
                        chip(InviteFilter.accepted, 'Accepted'),
                        const SizedBox(width: 10),
                        chip(InviteFilter.declined, 'Declined'),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final items = controller.filtered;
              if (items.isEmpty) {
                return _EmptyInvites();
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final inv = items[index];
                  return _InviteCard(invite: inv);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _EmptyInvites extends StatelessWidget {
  const _EmptyInvites();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.75),
                    AppColors.primary.withValues(alpha: 0.18),
                  ],
                ),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Icon(
                Icons.notifications_off_rounded,
                size: 46,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No invitations',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When someone invites you to an organisation, it will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.invite});

  final OrganizationInvite invite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final status = invite.status;
    final statusText = switch (status) {
      InviteStatus.pending => 'Pending',
      InviteStatus.accepted => 'Accepted',
      InviteStatus.declined => 'Declined',
    };

    final statusColor = switch (status) {
      InviteStatus.pending => AppColors.primary,
      InviteStatus.accepted => AppColors.primaryDark,
      InviteStatus.declined => AppColors.ink.withValues(alpha: 0.55),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Get.toNamed(
            Routes.joinOrganization,
            arguments: {
              'orgName': invite.orgName,
              'role': invite.role,
              'invitedBy': invite.invitedBy,
            },
          );
        },
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0.75),
                      AppColors.primary.withValues(alpha: 0.22),
                    ],
                  ),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                ),
                child: Icon(Icons.apartment_rounded, color: AppColors.ink.withValues(alpha: 0.80)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            invite.orgName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _StatusPill(text: statusText, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invited by ${invite.invitedBy} • ${invite.timeAgo}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.badge_rounded, size: 16, color: AppColors.ink.withValues(alpha: 0.55)),
                        const SizedBox(width: 6),
                        Text(
                          invite.role,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

