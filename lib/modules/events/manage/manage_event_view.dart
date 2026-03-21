import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_cards/core/services/document_scanner_service.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_search_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/confirm_dialog.dart';
import 'manage_event_controller.dart';

class ManageEventView extends GetView<ManageEventController> {
  const ManageEventView({super.key});

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
                              '${a.title} ${a.location}',
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
        floatingActionButton: FloatingActionButton(
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
        ),
      ),
    );
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
          child: CustomTextField(
            hint: 'Search...',
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.ink.withValues(alpha: 0.55)),
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
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
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

  final ManageEventController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
            onDelete: () {
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
                onPressed: busy ? null : controller.sendInvite,
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
                onPressed: busy ? null : controller.sendInvite,
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.55), width: 1.2),
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
                      TextSpan(text: invite.role, style: TextStyle(color: AppColors.primary)),
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
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.ink.withValues(alpha: 0.06),
            ),
            child: Icon(Icons.person_rounded, color: AppColors.ink.withValues(alpha: 0.55)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle1, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.ink.withValues(alpha: 0.80))),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      subtitle2,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _roleColor(subtitle2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (status != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        status!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.60),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, maxWidth: 30),
                visualDensity: VisualDensity.compact,
                onPressed: onUpdate,
                icon: Icon(Icons.edit_rounded, size: 20, color: AppColors.ink.withValues(alpha: 0.70)),
                tooltip: 'Update',
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, maxWidth: 30),
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    final v = role.toLowerCase();
    if (v.contains('admin')) return const Color(0xFFB42318);
    if (v.contains('editor')) return const Color(0xFF12B76A);
    return const Color(0xFF2E90FA);
  }
}

