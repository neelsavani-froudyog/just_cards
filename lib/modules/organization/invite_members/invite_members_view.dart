import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/custom_search_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/confirm_dialog.dart';
import 'invite_members_controller.dart';

class InviteMembersView extends GetView<InviteMembersController> {
  const InviteMembersView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text('Invite Members'),
        actions: [
          TextButton(
            onPressed: controller.skipForNow,
            child: Text(
              'Skip for now',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: Obx(() {
                  final busy = controller.isInviting.value;
                  return FilledButton(
                    onPressed: busy ? null : controller.sendInvites,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
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
                              children: [
                                Text(
                                  'Send Invites',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: AppColors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  );
                }),
              ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.55),
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
                      TextSpan(text: invite.role),
                      const TextSpan(text: '   '),
                      TextSpan(
                        text: invite.status,
                        style: TextStyle(color: AppColors.primary),
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
