import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/custom_search_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import 'manage_organization_controller.dart';

class ManageOrganizationView extends GetView<ManageOrganizationController> {
  const ManageOrganizationView({super.key});

  @override
  Widget build(BuildContext context) {
    final a = controller.args;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Get.back(),
          ),
          title: const Text('Organisation Settings'),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryLight.withValues(alpha: 0.35),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.apartment_rounded,
                          color: AppColors.ink.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _InfoChip(
                                  icon: Icons.group_rounded,
                                  label: '${a.membersCount} Members',
                                  tint: const Color(0xFF1D4ED8),
                                ),
                                _InfoChip(
                                  icon: Icons.done_all_rounded,
                                  label: '${a.pendingInvites} Pending invites',
                                  tint: AppColors.ink,
                                ),
                                _InfoChip(
                                  icon: Icons.calendar_month_outlined,
                                  label: '${a.eventsCount} Events',
                                  tint: AppColors.ink,
                                ),
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
              width: double.infinity,
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(18, 12, 0, 8),
              child: Obx(() {
                final expanded = controller.isEventsExpanded.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: controller.toggleEventsExpanded,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 18, bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Events',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            AnimatedRotation(
                              turns: expanded ? 0 : 0.5,
                              duration: const Duration(milliseconds: 180),
                              child: Icon(
                                Icons.expand_less_rounded,
                                color: AppColors.ink.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: expanded
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 18, bottom: 8),
                          itemCount: controller.events.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            if (index == controller.events.length) {
                              return const _AddEventCard();
                            }
                            final event = controller.events[index];
                            return _EventCard(event: event);
                          },
                        ),
                      ),
                      secondChild: const SizedBox.shrink(),
                    ),
                  ],
                );
              }),
            ),
            Container(
              color: AppColors.white,
              child: TabBar(
                labelColor: AppColors.ink,
                unselectedLabelColor: AppColors.ink.withValues(alpha: 0.55),
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.4,
                tabs: const [
                  Tab(text: 'Contacts'),
                  Tab(text: 'Members'),
                  Tab(text: 'Invites'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ContactsTab(controller: controller),
                  _MembersTab(controller: controller),
                  _InvitesTab(controller: controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        Icon(icon, size: 18, color: tint),
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

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final OrganizationEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              '${event.count}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEventCard extends StatelessWidget {
  const _AddEventCard();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.snackbar('Event', 'Add event coming soon'),
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        width: 110,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.ink),
            ),
            const SizedBox(height: 10),
            Text(
              'Add Event',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactsTab extends StatelessWidget {
  const _ContactsTab({required this.controller});

  final ManageOrganizationController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: CustomTextField(
            hint: 'Search...',
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.ink.withValues(alpha: 0.55),
            ),
            borderRadius: 12,
            filled: true,
            fillColor: AppColors.white,
            borderColor: AppColors.ink.withValues(alpha: 0.10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            onChanged: controller.setSearch,
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
            itemCount: controller.contacts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = controller.contacts[index];
              return _PersonTile(
                title: p.name,
                subtitle1: p.email,
                subtitle2: p.companyOrRole,
                status: null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({required this.controller});

  final ManageOrganizationController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        itemCount: controller.members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final m = controller.members[index];
          return _PersonTile(
            title: m.name,
            subtitle1: m.email,
            subtitle2: m.role,
            status: m.status,
          );
        },
      );
    });
  }
}

class _InvitesTab extends StatelessWidget {
  const _InvitesTab({required this.controller});

  final ManageOrganizationController controller;

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
                  (invite) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _SentInvitePill(
                      invite: invite,
                      onRemove: () async {
                        final ok = await ConfirmDialog.show(
                          title: 'Delete invite?',
                          message: 'Remove invite for ${invite.email}?',
                          confirmText: 'Delete',
                        );
                        if (ok) controller.removeInvite(invite);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            );
          }),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.ink.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
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
                    return FilledButton.tonal(
                      onPressed: busy ? null : controller.sendInvite,
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
              ],
            ),
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}

class _SentInvitePill extends StatelessWidget {
  const _SentInvitePill({required this.invite, required this.onRemove});

  final OrganizationInvitePill invite;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4ADE80).withValues(alpha: 0.80),
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
                        style: const TextStyle(color: AppColors.ink),
                      ),
                      const TextSpan(text: '  '),
                      TextSpan(
                        text: invite.status,
                        style: const TextStyle(color: Color(0xFF22C55E)),
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
                color: const Color(0xFF64748B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: AppColors.white),
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
    required this.status,
  });

  final String title;
  final String subtitle1;
  final String subtitle2;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = subtitle2.toLowerCase().contains('admin')
        ? const Color(0xFFFF5A47)
        : subtitle2.toLowerCase().contains('editor')
        ? const Color(0xFF22C55E)
        : const Color(0xFF2563EB);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.person_outline_rounded,
              color: AppColors.ink.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle1,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      subtitle2,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: roleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        status!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.ink.withValues(alpha: 0.78),
          ),
        ],
      ),
    );
  }
}
