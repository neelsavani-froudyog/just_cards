import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_text_field.dart';
import 'notifications_controller.dart';
import 'notifications_model.dart';
import 'notifications_shimmer_view.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
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
            color: AppColors.white,
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
                  fillColor: AppColors.white,
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
                          color: active ? AppColors.primary.withValues(alpha: 0.16) : AppColors.white,
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
                                  color: active ? AppColors.white : AppColors.ink.withValues(alpha: 0.75),
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
              // Show shimmer during filter/search refresh even if old data exists.
              if (controller.isLoading.value) {
                return const NotificationsShimmerView();
              }
              if (controller.errorText.value != null &&
                  controller.notifications.isEmpty) {
                return _ErrorState(
                  message: controller.errorText.value!,
                  onRetry: () => controller.fetchNotifications(reset: true),
                );
              }

              final items = controller.notifications;
              if (items.isEmpty) {
                return const _EmptyInvites();
              }
              return NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.pixels >= n.metrics.maxScrollExtent - 220) {
                    controller.loadMore();
                  }
                  return false;
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                  itemCount:
                      items.length + (controller.isLoadingMore.value ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index >= items.length) {
                      return Container(
                        height: 56,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }
                    final item = items[index];
                    return _NotificationCard(item: item);
                  },
                ),
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

// (Old mock invite card removed; the screen now renders `_NotificationCard`.)

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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final AppNotificationItem item;

  String _timeAgo() {
    final created = DateTime.tryParse(item.createdAt);
    if (created == null) return '';
    final diff = DateTime.now().toUtc().difference(created.toUtc());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final status = item.actionStatus.toLowerCase();
    final statusText = status.isNotEmpty ? status : 'pending';
    final statusColor = switch (statusText) {
      'accepted' => AppColors.primaryDark,
      'declined' => AppColors.ink.withValues(alpha: 0.55),
      _ => AppColors.primary,
    };

    final orgName =
        item.organizationName ?? item.payload.organizationName ?? 'Organization';

    final entityType = item.entityType.toLowerCase();
    final notificationType = item.notificationType.toLowerCase();
    final isEventInvite = entityType.contains('event') || notificationType.contains('event');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final shouldRefresh = await Get.toNamed(
            isEventInvite ? Routes.joinEvent : Routes.joinOrganization,
            arguments: isEventInvite
                ? <String, dynamic>{
                    'eventName': item.payload.eventName,
                    'role': item.role,
                    'invitedBy': item.invitedByName ?? '',
                    // Prefer payload inviteId; fall back to notification entityId.
                    'inviteId': item.payload.inviteId ?? item.entityId,
                    'eventId': item.entityId,
                  }
                : <String, dynamic>{
                    'orgName': orgName,
                    'role': item.role,
                    'invitedBy': item.invitedByName ?? '',
                    'inviteId': item.payload.inviteId,
                    'organizationId': item.payload.organizationId,
                  },
          );
          if (shouldRefresh == true) {
            Get.find<NotificationsController>().fetchNotifications(reset: true);
          }
        },
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.white,
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
                  border:
                      Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: AppColors.ink.withValues(alpha: 0.80),
                ),
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
                            item.title.isNotEmpty ? item.title : 'Notification',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _StatusPill(text: statusText, color: statusColor),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isEventInvite ? item.payload.eventName ?? "" : orgName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.82),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.badge_rounded,
                            size: 16,
                            color: AppColors.ink.withValues(alpha: 0.55)),
                        const SizedBox(width: 6),
                        Text(
                          item.role,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '• ${_timeAgo()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (!item.isSeen) ...[
                          const Spacer(),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 44, color: AppColors.danger),
            const SizedBox(height: 10),
            Text(
              'Couldn’t load notifications',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

