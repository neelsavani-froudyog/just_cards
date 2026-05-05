import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_cards/core/services/document_scanner_service.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/custom_search_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/confirm_dialog.dart';
import 'manage_event_controller.dart';
import 'manage_event_members_shimmer_view.dart';
import 'manage_event_contacts_shimmer_view.dart';

class ManageEventView extends GetView<ManageEventController> {
  const ManageEventView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final canShowInvitesTab = controller.canShowInvitesTab;
      final canShowEventOwnerActions = controller.canShowEventOwnerActions;
      final tabCount = canShowInvitesTab ? 3 : 2;
      final maxIndex = tabCount - 1;
      final safeIndex = controller.selectedTabIndex.value.clamp(0, maxIndex);

      return DefaultTabController(
        key: ValueKey<String>('manage-event-tabs-$tabCount-$safeIndex'),
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
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Get.back(),
                ),
                title: const Text('Manage Event'),
                actions: (canShowEventOwnerActions ||
                            controller.canShowDownloadContactsAction)
                          ? [
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_vert_rounded,
                                color: AppColors.ink.withValues(alpha: 0.92),
                              ),
                              color: AppColors.white,
                              onSelected: (value) {
                                if (value == 'download_contacts') {
                                  controller.exportEventContactsCsvGuarded();
                                } else if (value == 'edit') {
                                  Get.toNamed(
                                    Routes.editEvent,
                                    arguments: <String, dynamic>{
                                      'eventId': controller.args.eventId,
                                      'title': controller.eventTitle.value,
                                      'location': controller.eventLocation.value,
                                      'eventDate': controller.eventDateIso.value,
                                      'notes': controller.eventNotes.value,
                                      'organizationId':
                                          controller.eventOrganizationId.value,
                                    },
                                  )?.then((result) {
                                    if (result is Map) {
                                      controller.applyEventEditResult(result);
                                    }
                                  });
                                } else if (value == 'delete') {
                                  ConfirmDialog.show(
                                    title: 'Delete event?',
                                    message:
                                        'This will permanently delete the event and related data. This cannot be undone.',
                                    confirmText: 'Delete',
                                    destructive: true,
                                  ).then((ok) {
                                    if (ok) controller.deleteEvent();
                                  });
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    if (controller.canShowDownloadContactsAction)
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
                                    if (canShowEventOwnerActions)
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text(
                                          'Edit Event',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                color: AppColors.ink,
                                              ),
                                        ),
                                      ),
                                    if (canShowEventOwnerActions)
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Delete Event',
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
                children: [
                  Container(
                    color: AppColors.white,
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: AppColors.background,
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.event_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Obx(() {
                                    return Text(
                                      controller.eventTitle.value,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                        color: AppColors.ink,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 8,
                                    children: [
                                      Obx(() {
                                        return _InfoChip(
                                          icon: Icons.location_on_rounded,
                                          label: capitalizeWords(
                                            controller.eventLocation.value,
                                          ),
                                          tint: AppColors.ink.withValues(alpha: 0.55),
                                        );
                                      }),
                                      Obx(() {
                                        final membersCount =
                                            controller.joinedMembersCount;
                                        return _InfoChip(
                                          icon: Icons.group_rounded,
                                          label: '$membersCount Members',
                                          tint: AppColors.ink.withValues(alpha: 0.55),
                                        );
                                      }),
                                      Obx(() {
                                        final total =
                                            controller
                                                .eventCardsTotalCount
                                                .value;
                                        final text =
                                            total != null
                                                ? total.toString()
                                                : '--';
                                        return _InfoChip(
                                          icon: Icons.credit_card_rounded,
                                          label: '$text Cards',
                                          tint: AppColors.ink.withValues(alpha: 0.55),
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: AppColors.white,
                    child: TabBar(
                      onTap: controller.setSelectedTab,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.ink.withValues(alpha: 0.45),
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 2.4,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(color: AppColors.primary, width: 2.4),
                        insets: EdgeInsets.symmetric(horizontal: 22),
                      ),
                      tabs: [
                        const Tab(text: 'Contacts'),
                        const Tab(text: 'Members'),
                        if (canShowInvitesTab) const Tab(text: 'Invites'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _ContactsTab(controller: controller),
                        _MembersTab(controller: controller),
                        if (canShowInvitesTab)
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
                    heroTag: 'manage_event_scan_fab',
                    backgroundColor: AppColors.ink,
                    foregroundColor: AppColors.white,
                    onPressed: () async {
                      final images = await DocumentScannerService.scan(
                        allowMultiple: false,
                      );
                      if (images.isEmpty) return;
                      final orgId =
                          controller.eventOrganizationId.value?.trim() ?? '';
                          log('orgId: $orgId');
                      final result = await Get.toNamed(
                        Routes.scanResult,
                        arguments: <String, dynamic>{
                          'images': images,
                          'eventId': controller.args.eventId,
                          'eventTitle': controller.eventTitle.value,
                          'organizationId': orgId.isEmpty ? null : orgId,
                          'lockEvent': true,
                          'lockOrganization': orgId.isNotEmpty,
                        },
                      );
                      if (result == true) {
                        await controller.fetchContacts(reset: true);
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: tint),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: tint,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ContactsTab extends StatelessWidget {
  const _ContactsTab({required this.controller});

  final ManageEventController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                hint: 'Search...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.ink.withValues(alpha: 0.45),
                ),
                borderRadius: 12,
                filled: true,
                fillColor: AppColors.white,
                borderColor: AppColors.ink.withValues(alpha: 0.10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(
                      height: 500,
                      child: ManageEventContactsShimmerView(),
                    ),
                  ],
                );
              }

              if (items.isEmpty) {
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
                          color: AppColors.ink.withValues(alpha: 0.08),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ink.withValues(alpha: 0.03),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
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
                                (controller.searchQuery.value.trim().isNotEmpty
                                    ? 'Try a different search keyword.'
                                    : 'Contacts will appear here once cards are added to this event.'),
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
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
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
                    title: title,
                    subtitle1: subtitle1.isNotEmpty ? subtitle1 : '--',
                    subtitle2: subtitle2.isNotEmpty ? subtitle2 : '--',
                    status: null,
                    allowActions: false,
                    isMember: false,
                    onTap: () async {
                      final id = c.id.trim();
                      if (id.isEmpty) return;
                      final result = await Get.toNamed(
                        Routes.contactDetails,
                        arguments: id,
                      );
                      if (result == Routes.contactDeletedPopResult) {
                        await controller.fetchContacts(reset: true);
                      }
                    },
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _MembersTab extends StatefulWidget {
  const _MembersTab({required this.controller});

  final ManageEventController controller;

  @override
  State<_MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<_MembersTab> {
  TabController? _tabController;
  bool _listenerAttached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tabController ??= DefaultTabController.of(context);
    if (_listenerAttached) return;
    _listenerAttached = true;
    _tabController!.addListener(_handleTabChange);
    _handleTabChange(); // fetch if members tab is already visible
  }

  void _handleTabChange() {
    if (_tabController == null) return;
    if (_tabController!.index == 1 && !_tabController!.indexIsChanging) {
      widget.controller.fetchMembers();
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_handleTabChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 12),
        Expanded(
          child: Obx(() {
            Future<void> onRefresh() => controller.fetchMembers();
            if (controller.isMembersLoading.value) {
              return RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(
                      height: 500,
                      child: ManageEventMembersShimmerView(),
                    ),
                  ],
                ),
              );
            }
            if (controller.members.isEmpty) {
              return RefreshIndicator(
                onRefresh: onRefresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: 500,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.10,
                                    ),
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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  controller.membersErrorText.value ??
                                      'Members will appear here once users join this event.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.ink.withValues(alpha: 0.60),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FilledButton.tonal(
                                  onPressed: controller.fetchMembers,
                                  style: FilledButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    backgroundColor: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Refresh'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  18,
                  0,
                  18,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                itemCount: controller.members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final m = controller.members[index];
                  final status = (m.status ?? '').trim().toLowerCase();
                  final isPendingInvite =
                      status == 'pending' ||
                      (m.joinedAt == null && status != 'accepted');
                  final isActive = status == 'accepted' || status == 'active';
                  return _PersonTile(
                    title: m.name,
                    subtitle1: m.email,
                    subtitle2: m.role,
                    avatarUrl: m.avatarUrl,
                    status: m.status,
                    isMember: true,
                    allowActions: controller.canShowInvitesTab,
                    onAdd:
                        isPendingInvite
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

                      final nameController = TextEditingController(text: m.name);
                      final emailController = TextEditingController(
                        text: m.email,
                      );

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
                                      color: AppColors.ink.withValues(
                                        alpha: 0.70,
                                      ),
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
                                    'Email',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge?.copyWith(
                                      color: AppColors.ink.withValues(
                                        alpha: 0.70,
                                      ),
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
                                    'Assign Role',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelLarge?.copyWith(
                                      color: AppColors.ink.withValues(
                                        alpha: 0.70,
                                      ),
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
                                    borderColor: AppColors.ink.withValues(
                                      alpha: 0.10,
                                    ),
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
                        isActive
                            ? () {
                              ConfirmDialog.show(
                                title: 'Delete member?',
                                message:
                                    'Remove ${m.email} from event members?',
                                confirmText: 'Delete',
                                destructive: true,
                              ).then((ok) {
                                if (ok) controller.deleteMember(index);
                              });
                            }
                            : null,
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _InvitesTab extends StatelessWidget {
  const _InvitesTab({required this.controller});

  final ManageEventController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            if (controller.sentInvites.isEmpty) return const SizedBox.shrink();
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
              color: AppColors.ink.withValues(alpha: 0.70),
              fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          const SizedBox(height: 14),
          Text(
            'Assign Role',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.70),
              fontWeight: FontWeight.w600,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            );
          }),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: Obx(() {
              final busy = controller.isInviting.value;
              return FilledButton.tonal(
                onPressed: busy ? null : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  controller.addInviteToLocalList();},
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
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
              color: AppColors.ink.withValues(alpha: 0.70),
              fontWeight: FontWeight.w600,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (controller.sentInvites.isEmpty) return const SizedBox.shrink();
            final busy = controller.isInviting.value;
            return SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    busy
                        ? null
                        : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          controller.sendInvites();
                        },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child:
                      busy
                          ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                          : Row(
                            key: const ValueKey('label'),
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
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
                              ),
                            ],
                          ),
                ),
              ),
            );
          }),
        ],
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.buttonColor.withValues(alpha: 0.55),
          width: 1.2,
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
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.72),
                    ),
                    children: [
                      TextSpan(
                        text: invite.role,
                        style: TextStyle(color: AppColors.buttonColor),
                      ),
                    ],
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
                color: AppColors.ink.withValues(alpha: 0.70),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
    this.avatarUrl,
    required this.status,
    required this.isMember,
    this.allowActions = true,
    this.onAdd,
    this.onUpdate,
    this.onDelete,
    this.deleteIcon = Icons.delete_outline_rounded,
    this.deleteTooltip = 'Delete',
    this.onTap,
  });

  final String title;
  final String subtitle1;
  final String subtitle2;
  final String? avatarUrl;
  final String? status;
  final bool allowActions;
  final bool isMember;
  final VoidCallback? onAdd;
  final VoidCallback? onUpdate;
  final VoidCallback? onDelete;
  final IconData deleteIcon;
  final String deleteTooltip;
  final VoidCallback? onTap;

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

  String _statusLabel(String? status) {
    final s = (status ?? '').toLowerCase().trim();
    if (s == 'accepted') return 'Active';
    return capitalizeWords(status ?? '');
  }

  Color _rolePillBg(String role) {
    final r = role.toLowerCase();
    if (r.contains('owner') || r.contains('admin')) {
      return const Color(0xFFF59E0B).withValues(alpha: 0.16);
    }
    if (r.contains('editor')) {
      return const Color(0xFF2563EB).withValues(alpha: 0.12);
    }
    return AppColors.ink.withValues(alpha: 0.06);
  }

  Color _rolePillFg(String role) {
    final r = role.toLowerCase();
    if (r.contains('owner') || r.contains('admin')) return const Color(0xFFB45309);
    if (r.contains('editor')) return const Color(0xFF1D4ED8);
    return AppColors.ink.withValues(alpha: 0.60);
  }

  Color _statusPillBg(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'accepted' || s == 'active') {
      return const Color(0xFF22C55E).withValues(alpha: 0.14);
    }
    if (s.contains('pending')) {
      return const Color(0xFFF59E0B).withValues(alpha: 0.16);
    }
    return AppColors.ink.withValues(alpha: 0.06);
  }

  Color _statusPillFg(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'accepted' || s == 'active') return const Color(0xFF15803D);
    if (s.contains('pending')) return const Color(0xFFB45309);
    return AppColors.ink.withValues(alpha: 0.60);
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials(title);
    final theme = Theme.of(context);
    final avatarColor = _avatarColorFor('$title|$subtitle1|$initials');

    // Keep actions support for Members tab, but style card like Home contact tile.
    final isProtectedRole = _isOwnerOrAdmin(subtitle2);
    final canShowActions =
        allowActions &&
        !isProtectedRole &&
        (onUpdate != null || onDelete != null);

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
                clipBehavior: Clip.antiAlias,
                child: (avatarUrl?.trim().isNotEmpty ?? false)
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child:  Image.network(
                        avatarUrl!.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(
                            initials,
                            style: theme.textTheme.titleMedium?.copyWith(
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
                    if (isMember)
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
                              text: _statusLabel(status),
                              bg: _statusPillBg(status!),
                              fg: _statusPillFg(status!),
                            ),
                        ],
                      )
                    else
                      Text(
                        capitalizeWords(subtitle2),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
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
                        tooltip: deleteTooltip,
                        onTap: onDelete!,
                      ),
                    ],
                  ],
                )
              else
              if (!isMember)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.ink.withValues(alpha: 0.30),
                ),
            ],
          ),
        ),
      ),
    );
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

String capitalizeWords(String text) {
  return text
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}
