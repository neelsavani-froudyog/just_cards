import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_cards/modules/organization/detail/organization_events_model.dart';
import 'package:just_cards/core/services/document_scanner_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/custom_search_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import '../../events/manage/manage_event_controller.dart'
    show EventPerson, SentInvite;
import 'organization_detail_controller.dart';
import 'organization_contacts_shimmer_view.dart';
import 'organization_members_shimmer_view.dart';

class OrganizationDetailView extends GetView<OrganizationDetailController> {
  const OrganizationDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = controller.args;

    return Obx(() {
        final canManageOrganization = controller.canManageOrganization;
        final canShowDownloadContactsAction =
            controller.canShowDownloadContactsAction;
        final tabCount = canManageOrganization ? 3 : 2;
        final maxIndex = tabCount - 1;
        final safeIndex = controller.selectedTabIndex.value.clamp(0, maxIndex);
        return DefaultTabController(
          key: ValueKey<String>('org-detail-tabs-$tabCount-$safeIndex'),
          length: tabCount,
          initialIndex: safeIndex,
          child: Builder(
            builder: (context) {
              final tabController = DefaultTabController.of(context);
              return Scaffold(
                backgroundColor: AppColors.background,
                appBar: AppBar(
                  backgroundColor: AppColors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.ink,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Get.back(),
                  ),
                  title: Text(
                    'Organization Detail',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  actions:
                      (canManageOrganization || canShowDownloadContactsAction)
                          ? [
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: AppColors.ink.withValues(alpha: 0.92),
                              ),
                              color: AppColors.white,
                              onSelected: (value) {
                                if (value == 'download_contacts') {
                                  controller.exportOrganizationContactsCsv();
                                } else if (value == 'edit') {
                                  Get.toNamed(
                                    Routes.editOrganization,
                                    arguments: <String, dynamic>{
                                      'organizationId': a.organizationId,
                                      'name': a.name,
                                      'industry': a.industry,
                                      'role': a.role,
                                      'isActive': a.isActive,
                                    },
                                  )?.then((result) {
                                    if (result is Map) {
                                      controller.applyOrganizationEditResult(
                                        result,
                                      );
                                    }
                                  });
                                } else if (value == 'delete') {
                                  ConfirmDialog.show(
                                    title: 'Delete organization?',
                                    message:
                                        'This will permanently delete the organization and related data. This cannot be undone.',
                                    confirmText: 'Delete',
                                    destructive: true,
                                  ).then((ok) {
                                    if (ok) controller.deleteOrganization();
                                  });
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    if (canShowDownloadContactsAction)
                                      PopupMenuItem(
                                        value: 'download_contacts',
                                        child: Text(
                                          'Download Contacts',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color: AppColors.ink,
                                              ),
                                        ),
                                      ),
                                    if (canManageOrganization)
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text(
                                          'Edit Organization',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color: AppColors.ink,
                                              ),
                                        ),
                                      ),
                                    if (canManageOrganization)
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Delete Organization',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color: AppColors.ink,
                                              ),
                                        ),
                                      ),
                                  ],
                            ),
                          ]
                          : const [],
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OrgHeader(controller: controller),
                    _EventsSection(controller: controller),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.ink.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      child: TabBar(
                        onTap: controller.setSelectedTab,
                        controller: tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.ink.withValues(alpha: 0.45),
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 2.4,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: UnderlineTabIndicator(
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2.4,
                          ),
                          insets: const EdgeInsets.symmetric(horizontal: 22),
                        ),
                        labelStyle: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                        tabs: [
                          const Tab(text: 'Contacts'),
                          const Tab(text: 'Members'),
                          if (canManageOrganization) const Tab(text: 'Invites'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: tabController,
                        children: [
                          _ContactsTab(controller: controller),
                          _MembersTab(controller: controller),
                          if (canManageOrganization)
                            _InvitesTab(controller: controller),
                        ],
                      ),
                    ),
                  ],
                ),
                floatingActionButton: AnimatedBuilder(
                  animation: tabController.animation!,
                  builder: (context, _) {
                    if (tabController.index != 0) {
                      return const SizedBox.shrink();
                    }
                    return FloatingActionButton(
                      heroTag: 'organization_detail_scan_fab',
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.white,
                      onPressed: () async {
                        final images = await DocumentScannerService.scan(
                          allowMultiple: false,
                        );
                        if (images.isEmpty) return;
                        final result = await Get.toNamed(
                          Routes.scanResult,
                          arguments: <String, dynamic>{
                            'images': images,
                            'organizationId': controller.args.organizationId,
                            'organizationName': controller.args.name,
                            'lockOrganization': true,
                          },
                        );
                        if (result == true) {
                          await controller.fetchContacts(reset: true);
                          await controller.fetchOrganizationEvents();
                        }
                      },
                      child: const Icon(Icons.badge_outlined),
                    );
                  },
                ),
              );
            },
          ),
        );
      });
  }
}

class _OrgHeader extends StatelessWidget {
  const _OrgHeader({required this.controller});

  final OrganizationDetailController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.background,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.home_outlined,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  return Text(
                    controller.organizationDisplayName.value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Obx(() {
                  return Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      _StatRow(
                        icon: Icons.group_rounded,
                        label: '${controller.membersCount} Members',
                      ),
                      _StatRow(
                        icon: Icons.done_all_rounded,
                        label:
                            '${controller.pendingInvitesCount} Pending invites',
                      ),
                      _StatRow(
                        icon: Icons.calendar_month_rounded,
                        label: '${controller.eventsCount} Events',
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.ink.withValues(alpha: 0.55);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _EventsSection extends StatelessWidget {
  const _EventsSection({required this.controller});

  final OrganizationDetailController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final expanded = controller.eventsExpanded.value;
      return Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border(
            top: BorderSide(color: AppColors.ink.withValues(alpha: 0.06)),
            bottom: BorderSide(color: AppColors.ink.withValues(alpha: 0.06)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.toggleEventsExpanded,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Events',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.ink.withValues(alpha: 0.45),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeOutCubic,
              sizeCurve: Curves.easeOutCubic,
              crossFadeState:
                  expanded
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 220),
              firstChild: Obx(() {
                final isLoading = controller.isEventsLoading.value;
                final events = controller.orgEvents;

                if (isLoading) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      ),
                    ),
                  );
                }

                if (events.isEmpty) {
                  return SizedBox(
                    height: 120,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(
                                  alpha: 0.10,
                                ),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.event_busy_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No events found',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.eventsErrorText.value ??
                                  'Create your first event to get started.',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.60),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Container(
                  color: AppColors.background,
                  height: 120,
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final e = events[index];
                      return _EventCard(event: e);
                    },
                  ),
                );
              }),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      );
    });
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final OrganizationEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // Navigate to Manage Event when an event card is tapped.
          Get.toNamed(
            Routes.manageEvent,
            arguments: <String, dynamic>{
              'eventId': event.eventId,
              'title': event.eventName.isNotEmpty ? event.eventName : 'Event',
              'location':
                  event.locationText.isNotEmpty ? event.locationText : '—',
              'eventDate': event.eventDate,
              'type': event.type.isNotEmpty ? event.type : 'member',
              'member_role': event.memberRole.isNotEmpty
                  ? event.memberRole
                  : Get.find<OrganizationDetailController>().args.role,
              'createdBy': event.createdBy,
              'organizationId':
                  Get.find<OrganizationDetailController>().args.organizationId,
              'membersCount': event.memberCount,
              'cardsCount': event.contactCount,
              // Use org role for permissions in Manage Event UI.
              'role': Get.find<OrganizationDetailController>().args.role,
            },
          );
        },
        child: Ink(
          width: 210,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.eventName.isNotEmpty ? event.eventName : 'Event',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: AppColors.ink.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.locationText.isNotEmpty ? event.locationText : '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${event.contactCount} Contacts',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactsTab extends StatelessWidget {
  const _ContactsTab({required this.controller});

  final OrganizationDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      controller: controller.searchController,
                      hint: 'Search...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.ink.withValues(alpha: 0.45),
                      ),
                      borderRadius: 12,
                      filled: true,
                      fillColor: AppColors.white,
                      borderColor: AppColors.ink.withValues(alpha: 0.10),
                      textStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.ink),
                      hintStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.ink.withValues(alpha: 0.35)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      cursorColor: AppColors.primary,
                      onChanged: controller.setSearch,
                    ),
                  ],
                ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.fetchContacts(reset: true),
              child: Obx(() {
                final isLoading = controller.isContactsLoading.value;
                final err = controller.contactsErrorText.value;
                final items = controller.contacts;

                if (isLoading) {
                  return const OrganizationContactsShimmerView();
                }

                if (items.isEmpty) {
                  final hasSearch =
                      controller.searchQuery.value.trim().isNotEmpty;
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.ink.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.person_search_rounded,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No contacts found',
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                            ).textTheme.titleMedium?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              err ??
                                  (hasSearch
                                      ? 'Try a different search keyword.'
                                      : 'Contacts will appear here once cards are added to this organization.'),
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.60),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final c = items[index];
                    final title =
                        c.fullName.trim().isNotEmpty
                            ? c.fullName.trim()
                            : '${c.firstName} ${c.lastName}'.trim().isNotEmpty
                            ? '${c.firstName} ${c.lastName}'.trim()
                            : 'Unknown';
                    final subtitle1 =
                        c.email1.trim().isNotEmpty
                            ? c.email1.trim()
                            : c.phone1.trim();
                    final subtitle2 =
                        c.companyName.trim().isNotEmpty
                            ? c.companyName.trim()
                            : c.designation.trim();

                    return _PersonTile(
                      person: EventPerson(
                        name: title,
                        email: subtitle1.isNotEmpty ? subtitle1 : '--',
                        companyOrRole: subtitle2.isNotEmpty ? subtitle2 : '--',
                      ),
                      onTap: () async {
                        final id = c.id.trim();
                        if (id.isEmpty) return;
                        final result = await Get.toNamed(
                          Routes.contactDetails,
                          arguments: id,
                        );
                        if (result == Routes.contactDeletedPopResult) {
                          await controller.fetchContacts(reset: true);
                          await controller.fetchOrganizationEvents();
                        }
                      },
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person, this.onTap});

  final EventPerson person;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(person.name);
    final avatarColor = _avatarColorFor('${person.name}|${person.email}|$initials');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarColor,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      person.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      person.companyOrRole,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.ink.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _avatarColorFor(String seed) {
    const palette = <Color>[
      Color(0xFF0A66C2),
      Color(0xFF7B2FC7),
      Color(0xFF0D8A4E),
      Color(0xFFC47A00),
      Color(0xFF0D6C8A),
      Color(0xFFB00020),
    ];
    if (seed.trim().isEmpty) return palette.first;
    var hash = 0;
    for (final c in seed.codeUnits) {
      hash = 0x1fffffff & (hash + c);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return palette[hash.abs() % palette.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final a = parts.isNotEmpty ? parts.first : '';
    final b = parts.length > 1 ? parts[1] : '';
    final i1 = a.isEmpty ? '' : a[0];
    final i2 = b.isEmpty ? '' : b[0];
    final result = (i1 + i2).toUpperCase();
    return result.isEmpty ? '—' : result;
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({required this.controller});

  final OrganizationDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        onRefresh: controller.fetchMembers,
        child: Obx(() {
        if (controller.isMembersLoading.value) {
          return const OrganizationMembersShimmerView();
        }
        if (controller.members.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.ink.withValues(alpha: 0.06)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.group_off_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No members found',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.membersErrorText.value ??
                          'Members will appear here once users join this event.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.60),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            18,
            14,
            18,
            16 + MediaQuery.of(context).padding.bottom,
          ),
          itemCount: controller.members.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final m = controller.members[index];
            final canDelete =
                (m.joinedAt != null && m.joinedAt!.trim().isNotEmpty);
            final status = (m.status ?? '').toLowerCase().trim();
            final isActive = status == 'accepted' || status == 'active';
            return MemberTile(
              title: m.fullName,
              subtitle1: m.email,
              subtitle2: m.role,
              avatarUrl: m.avatarUrl,
              status: m.status,
              allowActions: controller.canManageOrganization,
              onAdd:
                  (m.status ?? '').toLowerCase().trim().contains('pending')
                      ? () => controller.resendInviteForMember(m)
                      : null,
              onUpdate: () {
                final memberRole = m.role.toLowerCase();
                String selected =
                    memberRole.contains('admin')
                        ? 'Admin'
                        : memberRole.contains('editor')
                        ? 'Editor'
                        : 'Viewer';

                final nameController = TextEditingController(text: m.fullName);
                final emailController = TextEditingController(text: m.email);

                Get.dialog<void>(
                  AlertDialog(
                    title: const Text('Update Member'),
                    content: StatefulBuilder(
                      builder: (context, setState) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Name',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.70),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: nameController,
                              hint: 'Name',
                              readOnly: true,
                              enabled: false,
                              borderRadius: 12,
                              filled: true,
                              fillColor: AppColors.white,
                              borderColor: AppColors.ink.withValues(alpha: 0.10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Email',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.70),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CustomTextField(
                              controller: emailController,
                              hint: 'Email',
                              readOnly: true,
                              enabled: false,
                              borderRadius: 12,
                              filled: true,
                              fillColor: AppColors.white,
                              borderColor: AppColors.ink.withValues(alpha: 0.10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Assign Role',
                              style: Theme.of(
                                context,
                              ).textTheme.labelLarge?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.70),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CustomSearchDropdown<String>(
                              items: controller.roles,
                              selectedItem: selected,
                              hintText: 'Select role',
                              showSearchBox: false,
                              itemAsString: (s) => s,
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => selected = v);
                              },
                              bgColor: AppColors.white,
                              borderColor: AppColors.ink.withValues(alpha: 0.10),
                              borderRadius: 12,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                      Obx(
                        () => FilledButton(
                          onPressed:
                              controller.isUpdatingMemberRole.value
                                  ? null
                                  : () async {
                                    final didUpdate =
                                        await controller.updateMemberRole(
                                          m,
                                          selected,
                                        );
                                    if (didUpdate) {
                                      Get.back();
                                    }
                                  },
                          child: Text(
                            controller.isUpdatingMemberRole.value
                                ? 'Updating...'
                                : 'Update',
                          ),
                        ),
                      ),
                    ],
                  ),
                ).whenComplete(() {
                  nameController.dispose();
                  emailController.dispose();
                });
              },
              onDelete:
                  (canDelete && isActive)
                      ? () {
                        ConfirmDialog.show(
                          title: 'Delete member?',
                          message: 'Remove ${m.email} from organization members?',
                          confirmText: 'Delete',
                          destructive: true,
                        ).then((ok) {
                          if (ok) controller.deleteMember(index);
                        });
                      }
                      : null,
            );
          },
        );
      }),
      ),
    );
  }
}

class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
    required this.avatarUrl,
    required this.status,
    this.allowActions = true,
    this.onAdd,
    this.onUpdate,
    this.onDelete,
  });

  final String title;
  final String subtitle1;
  final String subtitle2;
  final String? avatarUrl;
  final String? status;
  final bool allowActions;
  final VoidCallback? onAdd;
  final VoidCallback? onUpdate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(title);
    final avatarColor = _avatarColorFor('$title|$subtitle1|$initials');
    final isProtectedRole = _isOwnerOrAdmin(subtitle2);
    final canShowActions =
        allowActions &&
        !isProtectedRole &&
        (onUpdate != null || onDelete != null);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarColor,
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    (avatarUrl?.trim().isNotEmpty ?? false)
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.network(
                            avatarUrl!.trim(),
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Center(
                                  child: Text(
                                    initials,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ),
                          ),
                        )
                        : Center(
                          child: Text(
                            initials,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 8,
                      runSpacing: 0,
                      children: [
                        _Pill(
                          text: capitalizeWords(subtitle2),
                          bg: _rolePillBg(subtitle2),
                          fg: _rolePillFg(subtitle2),
                        ),
                        if (status != null)
                          _Pill(
                            text: _statusLabel(status!),
                            bg: _statusPillBg(status!),
                            fg: _statusPillFg(status!),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (canShowActions)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onAdd != null) ...[
                      _ActionButton(
                        icon: Icons.undo_rounded,
                        color: AppColors.ink.withValues(alpha: 0.68),
                        tooltip: 'Rollback',
                        onTap: onAdd!,
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (onUpdate != null)
                      _ActionButton(
                        icon: Icons.edit_outlined,
                        color: AppColors.ink.withValues(alpha: 0.68),
                        tooltip: 'Update',
                        onTap: onUpdate!,
                      ),
                    if (onDelete != null) ...[
                      const SizedBox(width: 6),
                      _ActionButton(
                        icon: Icons.delete_outline,
                        color: AppColors.danger,
                        tooltip: 'Delete',
                        onTap: onDelete!,
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final a = parts.isNotEmpty ? parts.first : '';
    final b = parts.length > 1 ? parts[1] : '';
    final i1 = a.isEmpty ? '' : a[0];
    final i2 = b.isEmpty ? '' : b[0];
    final result = (i1 + i2).toUpperCase();
    return result.isEmpty ? '—' : result;
  }

  String capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Color _roleColor(String role) {
    final v = role.toLowerCase();
    if (v.contains('admin') || v.contains('owner')) {
      return const Color(0xFFB42318);
    }
    if (v.contains('editor')) return const Color(0xFF12B76A);
    return const Color(0xFF2E90FA);
  }

  bool _isOwnerOrAdmin(String role) {
    final v = role.toLowerCase();
    return v.contains('owner');
  }

  Color _avatarColorFor(String seed) {
    const palette = <Color>[
      Color(0xFF0A66C2),
      Color(0xFF7B2FC7),
      Color(0xFF0D8A4E),
      Color(0xFFC47A00),
      Color(0xFF0D6C8A),
      Color(0xFFB00020),
    ];
    if (seed.trim().isEmpty) return palette.first;
    final idx = seed.codeUnits.fold<int>(0, (a, b) => (a + b) % palette.length);
    return palette[idx];
  }

  Color _rolePillBg(String role) {
    final r = role.toLowerCase();
    if (r.contains('owner')) return const Color(0xFFF59E0B).withValues(alpha: 0.16);
    if (r.contains('admin')) return const Color(0xFFF59E0B).withValues(alpha: 0.16);
    if (r.contains('editor')) return const Color(0xFF2563EB).withValues(alpha: 0.12);
    return AppColors.ink.withValues(alpha: 0.06);
  }

  Color _rolePillFg(String role) {
    final r = role.toLowerCase();
    if (r.contains('owner')) return const Color(0xFFB45309);
    if (r.contains('admin')) return const Color(0xFFB45309);
    if (r.contains('editor')) return const Color(0xFF1D4ED8);
    return AppColors.ink.withValues(alpha: 0.60);
  }

  String _statusLabel(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'accepted') return 'Active';
    return capitalizeWords(status);
  }

  Color _statusPillBg(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'accepted') return const Color(0xFF22C55E).withValues(alpha: 0.14);
    if (s.contains('pending')) return const Color(0xFFF59E0B).withValues(alpha: 0.16);
    return AppColors.ink.withValues(alpha: 0.06);
  }

  Color _statusPillFg(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'accepted') return const Color(0xFF15803D);
    if (s.contains('pending')) return const Color(0xFFB45309);
    return AppColors.ink.withValues(alpha: 0.60);
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _InvitesTab extends StatelessWidget {
  const _InvitesTab({required this.controller});

  final OrganizationDetailController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              if (controller.sentInvites.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  ...controller.sentInvites.map(
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SentInvitePill(
                        invite: i,
                        onRemove: () async {
                          final ok = await ConfirmDialog.show(
                            title: 'Delete invite?',
                            message: 'Remove invite for ${i.email}?',
                            confirmText: 'Delete',
                          );
                          if (ok) controller.removeInvite(i);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              );
            }),
            Text(
              'Add Members email *',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: controller.inviteEmailController,
              hint: 'Email ...',
              inputType: TextInputType.emailAddress,
              borderRadius: 12,
              filled: true,
              fillColor: AppColors.white,
              borderColor: AppColors.ink.withValues(alpha: 0.10),
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
              ),
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.35),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              cursorColor: AppColors.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'Assign Role',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              return CustomSearchDropdown<String>(
                items: controller.roles,
                selectedItem: controller.inviteRole.value,
                hintText: 'Select role',
                showSearchBox: false,
                itemAsString: (s) => s,
                onChanged: controller.setInviteRole,
                bgColor: AppColors.white,
                borderColor: AppColors.ink.withValues(alpha: 0.10),
                borderRadius: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
              );
            }),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              child: Obx(() {
                final busy = controller.isInviting.value;
                return FilledButton(
                  onPressed: busy ? null : controller.sendInvite,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        busy ? 'Adding...' : 'Add',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            Text(
              'Message (Optional)',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.55),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              controller: controller.inviteMessageController,
              hint: 'Add personal note to the invite ....',
              minLines: 5,
              maxLines: 5,
              borderRadius: 12,
              filled: true,
              fillColor: AppColors.white,
              borderColor: AppColors.ink.withValues(alpha: 0.10),
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
              ),
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.35),
              ),
              cursorColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.sentInvites.isEmpty)
                return const SizedBox.shrink();
              final busy = controller.isInviting.value;
              return SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : controller.sendInvites,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child:
                      busy
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Send Invite',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.send_rounded,
                                color: AppColors.white,
                                size: 18,
                              ),
                            ],
                          ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SentInvitePill extends StatelessWidget {
  const _SentInvitePill({required this.invite, required this.onRemove});

  final SentInvite invite;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.buttonColor.withValues(alpha: 0.45),
          width: 1.1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.email,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.buttonColor,
                    ),
                    children: [TextSpan(text: '${invite.role} ')],
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: AppColors.ink.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
