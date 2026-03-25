import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/custom_search_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import '../../events/manage/manage_event_controller.dart'
    show EventPerson, SentInvite;
import 'organization_detail_controller.dart';
import 'organization_members_shimmer_view.dart';

class OrganizationDetailView extends GetView<OrganizationDetailController> {
  const OrganizationDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = controller.args;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: DefaultTabController(
      length: 3,
      initialIndex: a.initialTab,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);
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
                'Organisation Detail',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.lightHubInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.lightHubInk.withValues(alpha: 0.92),
                  ),
                  color: AppColors.lightHubSurface,
                  onSelected: (value) {
                    if (value == 'settings') {
                      Get.toNamed(
                        Routes.organizationSettings,
                        arguments: <String, dynamic>{
                          'organizationId': a.organizationId,
                          'name': a.name,
                          'industry': a.industry,
                        },
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'settings',
                      child: Text(
                        'Organization settings',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.lightHubInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OrgHeader(controller: controller),
                _EventsSection(controller: controller),
                Container(
                  color: AppColors.lightHubSurface,
                  child: TabBar(
                    controller: tabController,
                    labelColor: AppColors.lightHubInk,
                    unselectedLabelColor: AppColors.lightHubMuted,
                    indicatorColor: AppColors.lightHubInk,
                    indicatorWeight: 2.8,
                    labelStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Contacts'),
                      Tab(text: 'Members'),
                      Tab(text: 'Invites'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      _ContactsTab(controller: controller),
                      _MembersTab(controller: controller),
                      _InvitesTab(controller: controller),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ));
  }
}

class _OrgHeader extends StatelessWidget {
  const _OrgHeader({required this.controller});

  final OrganizationDetailController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = controller.args;

    return Container(
      width: double.infinity,
      color: AppColors.lightHubSurface,
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withValues(alpha: 0.38),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.apartment_rounded,
              color: AppColors.lightHubInk.withValues(alpha: 0.78),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.lightHubInk,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
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
  const _StatRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.lightHubMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
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
        color: AppColors.lightHubSurface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: controller.toggleEventsExpanded,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        'Events',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.lightHubInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.lightHubMuted,
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
              crossFadeState: expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 220),
              firstChild: Obx(() {
                final events = controller.orgEvents;
                return SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final e = events[index];
                      return _EventCard(preview: e);
                    },
                  ),
                );
              }),
              secondChild: Container()
            ),
          ],
        ),
      );
    });
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.preview});

  final OrgEventPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 150,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.lightHubSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightHubBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            preview.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.lightHubMuted,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const Spacer(),
          Text(
            '${preview.contactCount}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.lightHubInk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
      color: AppColors.lightHubBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: CustomTextField(
              controller: controller.searchController,
              hint: 'Search...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.lightHubMuted,
              ),
              borderRadius: 12,
              filled: true,
              fillColor: AppColors.lightHubSurface,
              borderColor: AppColors.lightHubBorder,
              textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightHubInk,
                  ),
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightHubHint,
                  ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              cursorColor: AppColors.lightHubBlue,
              onChanged: controller.setSearch,
            ),
          ),
          Expanded(
            child: Obx(() {
              final list = controller.filteredContacts;
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = list[index];
                  return _PersonTile(person: p);
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({required this.person});

  final EventPerson person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.lightHubSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightHubBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightHubAvatarFill,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_rounded,
              size: 22,
              color: AppColors.lightHubMuted,
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
                    color: AppColors.lightHubInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  person.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.lightHubMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  person.companyOrRole,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.lightHubBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.lightHubMuted,
          ),
        ],
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({required this.controller});

  final OrganizationDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isMembersLoading.value) {
        return const OrganizationMembersShimmerView();
      }
      if (controller.members.isEmpty) {
        return Center(
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
                  const SizedBox(height: 14),
                  FilledButton.tonal(
                    onPressed: controller.fetchMembers,
                    style: FilledButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
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
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 90),
        itemCount: controller.members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final m = controller.members[index];
          final canDelete =
              (m.joinedAt != null && m.joinedAt!.trim().isNotEmpty);
          return MemberTile(
            title: m.fullName,
            subtitle1: m.email,
            subtitle2: m.role,
            status: m.status,
            onAdd: () {
              // controller.resendInviteForMember(m);
            },
            onUpdate: () {
              final memberRole = m.role.toLowerCase();
              String selected = memberRole.contains('admin')
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
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Email',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Assign Role',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                    FilledButton(
                      onPressed: () {
                        controller.updateMemberRole(index, selected);
                        Get.back();
                      },
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ).whenComplete(() {
                nameController.dispose();
                emailController.dispose();
              });
            },
            onDelete: canDelete
                ? () {
                    ConfirmDialog.show(
                      title: 'Delete member?',
                      message: 'Remove ${m.email} from event members?',
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
    });
  }
}


class MemberTile extends StatelessWidget {
  const MemberTile({
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
    required this.status,
    this.onAdd,
    this.onUpdate,
    this.onDelete,
  });

  final String title;
  final String subtitle1;
  final String subtitle2;
  final String? status;
  final VoidCallback? onAdd;
  final VoidCallback? onUpdate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProtectedRole = _isOwnerOrAdmin(subtitle2);
    final canShowActions =
        !isProtectedRole && (onUpdate != null || onDelete != null);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.09)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.ink.withValues(alpha: 0.06),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_rounded,
              size: 21,
              color: AppColors.ink.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 10),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Text(
                        subtitle2,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _roleColor(subtitle2),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (status != null && status != 'accepted') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        child: Text(
                          status!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.60),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          if (canShowActions)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onUpdate != null)
                  _ActionButton(
                    icon: Icons.edit_rounded,
                    color: AppColors.ink.withValues(alpha: 0.68),
                    tooltip: 'Update',
                    onTap: onUpdate!,
                  ),
                if (onDelete != null) ...[
                  const SizedBox(width: 6),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    tooltip: 'Delete',
                    onTap: onDelete!,
                  ),
                ],
              ],
            ),
        ],
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
}

class _InvitesTab extends StatelessWidget {
  const _InvitesTab({required this.controller});

  final OrganizationDetailController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: AppColors.lightHubBg,
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
                color: AppColors.lightHubMuted,
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
              fillColor: AppColors.lightHubSurface,
              borderColor: AppColors.lightHubBorder,
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.lightHubInk,
              ),
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.lightHubHint,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              cursorColor: AppColors.lightHubBlue,
            ),
            const SizedBox(height: 14),
            Text(
              'Assign Role',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.lightHubMuted,
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
                bgColor: AppColors.lightHubSurface,
                borderColor: AppColors.lightHubBorder,
                borderRadius: 12,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                    backgroundColor: AppColors.lightHubFab,
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
                color: AppColors.lightHubMuted,
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
              fillColor: AppColors.lightHubSurface,
              borderColor: AppColors.lightHubBorder,
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.lightHubInk,
              ),
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.lightHubHint,
              ),
              cursorColor: AppColors.lightHubBlue,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: Obx(() {
                final busy = controller.isInviting.value;
                return FilledButton(
                  onPressed: busy ? null : controller.sendInvites,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: busy
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
                            const Icon(Icons.send_rounded,
                                color: AppColors.white, size: 18),
                          ],
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
                    color: AppColors.lightHubInk,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.buttonColor,
                    ),
                    children: [
                      TextSpan(text: '${invite.role} '),
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
                color: AppColors.lightHubInk.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: AppColors.lightHubMuted,
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
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}
