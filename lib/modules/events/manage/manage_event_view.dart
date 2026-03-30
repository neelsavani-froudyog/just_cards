import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_cards/core/services/document_scanner_service.dart';

import '../../../core/theme/app_colors.dart';
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
    final a = controller.args;
    final theme = Theme.of(context);

    return Obx(() {
      final canShowInvitesTab = controller.canShowInvitesTab;
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
              backgroundColor: const Color(0xFFF5F7FB),
              appBar: AppBar(
                backgroundColor: AppColors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Get.back(),
                ),
                title: const Text('Manage Event'),
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
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primaryLight.withValues(alpha: 0.35),
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.event_rounded, color: AppColors.ink.withValues(alpha: 0.75)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 8,
                                    children: [
                                      _InfoChip(
                                        icon: Icons.location_on_rounded,
                                        label: capitalizeWords(a.location),
                                        tint: AppColors.primary,
                                      ),
                                      _InfoChip(
                                        icon: Icons.group_rounded,
                                        label: '${a.membersCount} Members',
                                        tint: AppColors.primary,
                                      ),
                                      _InfoChip(
                                        icon: Icons.credit_card_rounded,
                                        label: '${a.cardsCount} Cards',
                                        tint: AppColors.primary,
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
                    color: AppColors.white,
                    child: TabBar(
                      onTap: controller.setSelectedTab,
                      labelColor: AppColors.ink,
                      unselectedLabelColor: AppColors.ink.withValues(alpha: 0.55),
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 2.4,
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
                        if (canShowInvitesTab) _InvitesTab(controller: controller),
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
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    onPressed: () async {
                      final images = await DocumentScannerService.scan(allowMultiple: false);
                      if (images.isNotEmpty) {
                        Get.snackbar('Scan complete', '${images.length} page(s) captured');
                      }
                      Get.back();
                    },
                    child: const Icon(Icons.badge_rounded),
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
  const _InfoChip({required this.icon, required this.label, required this.tint});

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

class _ContactsTab extends StatelessWidget {
  const _ContactsTab({required this.controller});

  final ManageEventController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = controller.isContactsLoading.value;
      final err = controller.contactsErrorText.value;
      final items = controller.contacts;

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
          if (isLoading)
            const Expanded(
              child: ManageEventContactsShimmerView(),
            )
          else if (items.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.60),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final c = items[index];
                  final title = c.fullName.trim().isNotEmpty
                      ? c.fullName.trim()
                      : '${c.firstName} ${c.lastName}'.trim().isNotEmpty
                          ? '${c.firstName} ${c.lastName}'.trim()
                          : 'Unknown';
                  final subtitle1 =
                      c.email1.trim().isNotEmpty ? c.email1.trim() : c.phone1.trim();
                  final subtitle2 = c.companyName.trim().isNotEmpty
                      ? c.companyName.trim()
                      : c.designation.trim();

                  return _PersonTile(
                    title: title,
                    subtitle1: subtitle1.isNotEmpty ? subtitle1 : '--',
                    subtitle2: subtitle2.isNotEmpty ? subtitle2 : '--',
                    status: null,
                    allowActions: false,
                  );
                },
              ),
            ),
        ],
      );
    });
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
    return Obx(() {
      if (controller.isMembersLoading.value) {
        return const ManageEventMembersShimmerView();
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
          return _PersonTile(
            title: m.name,
            subtitle1: m.email,
            subtitle2: m.role,
            status: m.status,
            allowActions: controller.canShowInvitesTab,
            onAdd: () {
              controller.resendInviteForMember(m);
            },
            onUpdate: () {
              final memberRole = m.role.toLowerCase();
              String selected = memberRole.contains('admin')
                  ? 'Admin'
                  : memberRole.contains('editor')
                      ? 'Editor'
                      : 'Viewer';

              final nameController = TextEditingController(text: m.name);
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
            onDelete: m.joinedAt == null
                ? null
                : () {
                    ConfirmDialog.show(
                      title: 'Delete member?',
                      message: 'Remove ${m.email} from event members?',
                      confirmText: 'Delete',
                      destructive: true,
                    ).then((ok) {
                      if (ok) controller.deleteMember(index);
                    });
                  },
          );
        },
      );
    });
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
                onPressed: busy ? null : controller.addInviteToLocalList,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    const Icon(Icons.add_circle_outline_rounded, color: AppColors.white),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: busy
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
                            const Icon(Icons.send_rounded, color: AppColors.white),
                          ],
                        ),
                ),
              );
            }),
          ),
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
        border: Border.all(color: AppColors.buttonColor.withValues(alpha: 0.55), width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invite.email, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink.withValues(alpha: 0.72)),
                    children: [
                      TextSpan(text: invite.role, style: TextStyle(color: AppColors.buttonColor)),
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
              child: Icon(Icons.close_rounded, color: AppColors.ink.withValues(alpha: 0.70)),
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
    this.allowActions = true,
    this.onAdd,
    this.onUpdate,
    this.onDelete,
  });

  final String title;
  final String subtitle1;
  final String subtitle2;
  final String? status;
  final bool allowActions;
  final VoidCallback? onAdd;
  final VoidCallback? onUpdate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(title);
    final theme = Theme.of(context);

    // Keep actions support for Members tab, but style card like Home contact tile.
    final isProtectedRole = _isOwnerOrAdmin(subtitle2);
    final canShowActions =
        allowActions && !isProtectedRole && (onUpdate != null || onDelete != null);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.040),
                blurRadius: 8,
                offset: const Offset(0, 3),
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
                  color: AppColors.accentTeal.withValues(alpha: 0.10),
                  border: Border.all(
                    color: AppColors.accentTeal.withValues(alpha: 0.60),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.70),
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
                    Text(
                      subtitle2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w600,
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
                )
              else
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final a = parts.isNotEmpty ? parts.first : '';
    final b = parts.length > 1 ? parts[1] : '';
    final i1 = a.isEmpty ? '' : a[0];
    final i2 = b.isEmpty ? '' : b[0];
    final result = (i1 + i2).toUpperCase();
    return result.isEmpty ? '—' : result;
  }

  

  bool _isOwnerOrAdmin(String role) {
    final v = role.toLowerCase();
    return v.contains('owner') || v.contains('admin');
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

String capitalizeWords(String text) {
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }