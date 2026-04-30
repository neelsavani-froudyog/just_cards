import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/models/contact_detail_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/confirm_dialog.dart';
import 'contact_details_controller.dart';
import 'contact_details_shimmer.dart';
import 'contact_notes/contact_notes_view.dart';

class ContactDetailsView extends GetView<ContactDetailsController> {
  const ContactDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text('Contact Details'),
        actions: [
          Obx(() {
            if (!controller.canShowContactOwnerActions) {
              return const SizedBox.shrink();
            }
            return PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppColors.ink.withValues(alpha: 0.92),
              ),
              color: AppColors.white,
              onSelected: (value) {
                if (value == 'edit') {
                  controller.openEditContact();
                } else if (value == 'delete') {
                  ConfirmDialog.show(
                    title: 'Delete contact?',
                    message:
                        'This will permanently delete this contact and related data. This cannot be undone.',
                    confirmText: 'Delete',
                    destructive: true,
                  ).then((ok) {
                    if (ok) controller.deleteContact();
                  });
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    'Edit contact',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.ink,
                        ),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete contact',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.ink,
                        ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const ContactDetailsShimmer();
          }
          final err = controller.errorText.value;
          if (err != null && err.trim().isNotEmpty) {
            return _ContactLoadError(
              message: err,
              onRetry: controller.fetchDetail,
            );
          }
          final d = controller.detail.value;
          if (d == null) {
            return _ContactLoadError(
              message: 'No contact data',
              onRetry: controller.fetchDetail,
            );
          }

          return Column(
            children: [
              Container(
                color: AppColors.white,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                child: Column(
                  children: [
                    _Header(detail: d),
                    const SizedBox(height: 12),
                    _QuickActions(
                      onCall: controller.onCallTap,
                      onEmail: controller.onEmailTap,
                      onWhatsApp: controller.onWhatsAppTap,
                      onShare: controller.shareContactDetails,
                    ),
                    const SizedBox(height: 12),
                    Obx(() {
                      final t = controller.tab.value;
                      return _TopTabs(
                        tab: t,
                        onSelect: controller.setTab,
                      );
                    }),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: switch (controller.tab.value) {
                      ContactDetailsTab.details =>
                        _DetailsTab(key: const ValueKey('details'), detail: d),
                      ContactDetailsTab.notes =>
                        const ContactNotesView(key: ValueKey('notes')),
                      ContactDetailsTab.attachments =>
                        _AttachmentsTab(key: const ValueKey('attachments')),
                    },
                  );
                }),
              ),
              Obx(() {
                final t = controller.tab.value;
                final saving = controller.isSaving.value;
                if (t == ContactDetailsTab.details) return const SizedBox.shrink();
                final showAttachmentSave = t == ContactDetailsTab.attachments && controller.hasLocalAttachments;
                return Container(
                  color: const Color(0xFFF5F7FB),
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Column(
                    children: [
                      if (t == ContactDetailsTab.attachments) ...[
                        const SizedBox.shrink(),
                      ],
                      if (t == ContactDetailsTab.notes || showAttachmentSave)
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: t == ContactDetailsTab.notes
                                ? () => showContactCreateNoteDialog(context)
                                : saving
                                    ? null
                                    : controller.saveChanges,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: t == ContactDetailsTab.notes
                                ? const Icon(Icons.note_add_rounded, color: AppColors.white)
                                : saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                                      )
                                    : const Icon(Icons.save_rounded, color: AppColors.white),
                            label: Text(
                              t == ContactDetailsTab.notes ? 'Create Note' : 'Save Changes',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          );
        }),
      ),
    );
  }

}

class _ContactLoadError extends StatelessWidget {
  const _ContactLoadError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.ink.withValues(alpha: 0.45)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.78),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

String _initialsFromName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final a = parts.isNotEmpty ? parts.first : '';
  final b = parts.length > 1 ? parts[1] : '';
  final i1 = a.isEmpty ? '' : a[0];
  final i2 = b.isEmpty ? '' : b[0];
  final s = (i1 + i2).toUpperCase();
  return s.isEmpty ? '?' : s;
}

String _formatDetailDate(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso.trim();
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final m = months[dt.month - 1];
  final day = dt.day.toString().padLeft(2, '0');
  return '$day-$m-${dt.year}';
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final ContactDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = detail.displayName;
    final initials = _initialsFromName(name);
    final subtitle = detail.headerSubtitle;
    final photo = detail.profilePhotoUrl?.trim();

    return Column(
      children: [
        SizedBox(
          width: 88,
          height: 88,
          child: ClipOval(
            child: photo != null && photo.isNotEmpty
                ? Image.network(
                    photo,
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _InitialsAvatar(initials: initials),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _InitialsAvatar(initials: initials);
                    },
                  )
                : _InitialsAvatar(initials: initials),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.contactWhatsApp,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: theme.textTheme.titleLarge?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onCall,
    required this.onEmail,
    required this.onWhatsApp,
    required this.onShare,
  });

  final Future<void> Function() onCall;
  final Future<void> Function() onEmail;
  final Future<void> Function() onWhatsApp;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionCircle(
          icon: Icons.call_rounded,
          iconAsset: 'assets/icons/ic_call.png',
          label: 'Call',
          onTap: () => onCall(),
          bgcolor: AppColors.contactCall,
        ),
        _ActionCircle(
          icon: Icons.email_rounded,
          iconAsset: 'assets/icons/ic_email.png',
          label: 'Email',
          onTap: () => onEmail(),
          bgcolor: AppColors.contactEmail,
        ),
        _ActionCircle(
          icon: Icons.chat_rounded,
          iconAsset: 'assets/icons/ic_whatsapp.png',
          label: 'WhatsApp',
          onTap: () => onWhatsApp(),
          bgcolor: AppColors.contactWhatsApp,
        ),
        _ActionCircle(
          icon: Icons.share_rounded,
          iconAsset: 'assets/icons/ic_share.png',
          label: 'Share',
          onTap: onShare,
          bgcolor: AppColors.contactShare,
        ),
      ],
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({
    required this.icon,
    this.iconAsset,
    required this.label,
    required this.onTap,
    required this.bgcolor,
  });

  final IconData icon;
  final String? iconAsset;
  final String label;
  final VoidCallback onTap;
  final Color bgcolor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, color: bgcolor),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _ActionIcon(asset: iconAsset, fallback: icon, color: AppColors.surface),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.asset, required this.fallback, required this.color});

  final String? asset;
  final IconData fallback;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final a = asset;
    if (a == null || a.trim().isEmpty) return Icon(fallback, color: color, size: 20);
    return Image.asset(
      a,
      color: color,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(fallback, color: color, size: 20),
    );
  }
}

class _TopTabs extends StatelessWidget {
  const _TopTabs({required this.tab, required this.onSelect});

  final ContactDetailsTab tab;
  final ValueChanged<ContactDetailsTab> onSelect;

  @override
  Widget build(BuildContext context) {
    Widget tabItem(ContactDetailsTab t, String label) {
      final active = tab == t;
      return Expanded(
        child: InkWell(
          onTap: () => onSelect(t),
          child: SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color:
                            active
                                ? AppColors.primary
                                : AppColors.ink.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (active)
                  Positioned(
                    bottom: 0,
                    left: 18,
                    right: 18,
                    child: Container(
                      height: 2.4,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(height: 1, color: AppColors.ink.withValues(alpha: 0.06)),
        Row(
          children: [
            tabItem(ContactDetailsTab.details, 'Details'),
            tabItem(ContactDetailsTab.notes, 'Notes'),
            tabItem(ContactDetailsTab.attachments, 'Attachments'),
          ],
        ),
      ],
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({super.key, required this.detail});

  final ContactDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[];

    void gap() {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
    }

    final phones = detail.phonesLine;
    if (phones.isNotEmpty) {
      gap();
      rows.add(_InfoRow(icon: Icons.phone_rounded, label: 'Phone', value: phones));
    }

    final emails = detail.emailsLine;
    if (emails.isNotEmpty) {
      gap();
      rows.add(_InfoRow(icon: Icons.email_rounded, label: 'Email', value: emails));
    }

    final web = detail.website?.trim() ?? '';
    if (web.isNotEmpty) {
      gap();
      rows.add(_InfoRow(icon: Icons.language_rounded, label: 'Website', value: web));
    }

    final addr = detail.address.trim();
    if (addr.isNotEmpty) {
      gap();
      rows.add(_InfoRow(icon: Icons.location_on_rounded, label: 'Address', value: addr));
    }

    final des = detail.designation.trim();
    if (des.isNotEmpty) {
      gap();
      rows.add(_InfoRow(icon: Icons.work_outline_rounded, label: 'Designation', value: des));
    }

    final org = detail.organization;
    if (org != null && org.name.trim().isNotEmpty) {
      gap();
      rows.add(_InfoRow(icon: Icons.apartment_rounded, label: 'Organization', value: org.name.trim()));
    }

    final ev = detail.event;
    if (ev != null && ev.name.trim().isNotEmpty) {
      gap();
      rows.add(_InfoRow(icon: Icons.event_rounded, label: 'Event', value: ev.name.trim()));
    }

    final cardUrl = detail.cardImgUrl?.trim();
    if (cardUrl != null && cardUrl.isNotEmpty) {
      gap();
      rows.add(
        Text(
          'Card image',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.55),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      );
      rows.add(const SizedBox(height: 6));
      rows.add(_CardImagePreview(url: cardUrl));
    }

    final created = detail.createdAt.trim();
    if (created.isNotEmpty) {
      gap();
      rows.add(
        Text(
          'Created on ${_formatDetailDate(created)}',
          style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.55),
                fontWeight: FontWeight.w700,
              ),
        ),
      );
    }

    if (rows.isEmpty) {
      return ListView(
        key: key,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        children: [
          Text(
            'No details to show',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return ListView(
      key: key,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      children: rows,
    );
  }
}

class _CardImagePreview extends StatelessWidget {
  const _CardImagePreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.credit_card_rounded,
              color: AppColors.white.withValues(alpha: 0.40),
              size: 54,
            ),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                ),
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFFFE7DB),
            ),
            child: Icon(icon, color: const Color(0xFFFF6B2D), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.50),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
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

class _AttachmentsTab extends GetView<ContactDetailsController> {
  const _AttachmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final photos = controller.photos;
      final docs = controller.docs;
      final isLoading = controller.isAttachmentsLoading.value;

      if (isLoading) {
        return const _AttachmentsLoadingShimmer();
      }

      return ListView(
        key: key,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        children: [
          Text(
            'PHOTOS',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.55),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _ThumbGrid(
            items: photos.toList(growable: false),
            tileBuilder: (_, index, item) => _ImageThumb(
              path: item,
              onDelete: () => _confirmDelete(
                context,
                onConfirm: () => controller.removePhotoAt(index),
              ),
            ),
            onAddTap: () => _showPhotoSourceSheet(context),
          ),
          const SizedBox(height: 14),
          Text(
            'PDF / DOCS',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.55),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          _ThumbGrid(
            items: docs.toList(growable: false),
            tileBuilder: (_, index, item) => _DocThumb(
              path: item,
              onTap: () => _openDocumentPreview(context, item),
              onDelete: () => _confirmDelete(
                context,
                onConfirm: () => controller.removeDocAt(index),
              ),
            ),
            onAddTap: controller.addPdfFromFiles,
          ),
        ],
      );
    });
  }

  Future<void> _confirmDelete(
    BuildContext context, {
    required Future<void> Function() onConfirm,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Delete attachment?',
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'This action removes the file from this attachments list.',
                textAlign: TextAlign.center,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.ink.withValues(alpha: 0.18)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
                              color: AppColors.ink.withValues(alpha: 0.80),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Delete',
                        style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                            ),
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
    if (shouldDelete == true) await onConfirm();
  }

  Future<void> _showPhotoSourceSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Gallery'),
                  subtitle: const Text('Select multiple images'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await controller.addPhotosFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Camera'),
                  subtitle: const Text('Open document scanner'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await controller.addPhotosFromCameraScanner();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openDocumentPreview(BuildContext context, String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return;
    final isRemote = trimmed.startsWith('http://') || trimmed.startsWith('https://');
    if (!isRemote) {
      Get.snackbar(
        'Preview unavailable',
        'Document preview is available after upload.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.to(() => _DocumentPreviewPage(url: trimmed));
  }
}

class _ThumbGrid extends StatelessWidget {
  const _ThumbGrid({
    required this.items,
    required this.tileBuilder,
    required this.onAddTap,
  });

  final List<String> items;
  final Widget Function(BuildContext context, int index, String item) tileBuilder;
  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    final tiles = items.length + 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 11,
        mainAxisSpacing: 11,
      ),
      itemBuilder: (context, index) {
        if (index == tiles - 1) return _AddThumb(onTap: onAddTap);
        return tileBuilder(context, index, items[index]);
      },
    );
  }
}

class _AddThumb extends StatelessWidget {
  const _AddThumb({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ink.withValues(alpha: 0.18), width: 1.5),
        ),
        child: Icon(Icons.add_rounded, color: AppColors.ink.withValues(alpha: 0.70)),
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb({
    required this.path,
    required this.onDelete,
  });

  final String path;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final trimmedPath = path.trim();
    final isNetworkImage = trimmedPath.startsWith('http://') || trimmedPath.startsWith('https://');
    final imageWidget = isNetworkImage
        ? Image.network(
            trimmedPath,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const _ThumbShimmer();
            },
            errorBuilder: (_, __, ___) =>
                Icon(Icons.image_rounded, color: AppColors.darkGrey.withValues(alpha: 0.45)),
          )
        : Image.file(
            File(trimmedPath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.image_rounded, color: AppColors.darkGrey.withValues(alpha: 0.45)),
          );

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (trimmedPath.isEmpty) return;
        showDialog<void>(
          context: context,
          builder: (_) => _FullImagePreviewDialog(
            path: trimmedPath,
            isNetworkImage: isNetworkImage,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: AppColors.ink.withValues(alpha: 0.06),
                child: imageWidget,
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: _DeleteBadge(onTap: onDelete),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentsLoadingShimmer extends StatelessWidget {
  const _AttachmentsLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      children: [
        Text(
          'PHOTOS',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.55),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        const _ShimmerThumbGrid(tileCount: 5),
        const SizedBox(height: 14),
        Text(
          'PDF / DOCS',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.55),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        const _ShimmerThumbGrid(tileCount: 5),
      ],
    );
  }
}

class _ShimmerThumbGrid extends StatelessWidget {
  const _ShimmerThumbGrid({required this.tileCount});

  final int tileCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tileCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (_, __) => const _ThumbShimmer(),
    );
  }
}

class _ThumbShimmer extends StatefulWidget {
  const _ThumbShimmer();

  @override
  State<_ThumbShimmer> createState() => _ThumbShimmerState();
}

class _ThumbShimmerState extends State<_ThumbShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final begin = -1.2 + (_controller.value * 2.4);
        final end = begin + 1.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment(begin, -0.3),
              end: Alignment(end, 0.3),
              colors: [
                AppColors.ink.withValues(alpha: 0.04),
                AppColors.ink.withValues(alpha: 0.10),
                AppColors.ink.withValues(alpha: 0.04),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FullImagePreviewDialog extends StatelessWidget {
  const _FullImagePreviewDialog({
    required this.path,
    required this.isNetworkImage,
  });

  final String path;
  final bool isNetworkImage;

  @override
  Widget build(BuildContext context) {
    final image = isNetworkImage
        ? Image.network(path, fit: BoxFit.contain)
        : Image.file(File(path), fit: BoxFit.contain);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 10,vertical: 25),
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(child: image),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                color: AppColors.white,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocThumb extends StatelessWidget {
  const _DocThumb({
    required this.path,
    required this.onTap,
    required this.onDelete,
  });

  final String path;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final lower = path.toLowerCase();
    final isPdf = lower.endsWith('.pdf');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: AppColors.ink.withValues(alpha: 0.06),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                  color: AppColors.darkGrey.withValues(alpha: 0.45),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: _DeleteBadge(onTap: onDelete),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentPreviewPage extends StatefulWidget {
  const _DocumentPreviewPage({required this.url});

  final String url;

  @override
  State<_DocumentPreviewPage> createState() => _DocumentPreviewPageState();
}

class _DocumentPreviewPageState extends State<_DocumentPreviewPage> {
  late final WebViewController _webController;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    final source = widget.url.trim();
    final lower = source.toLowerCase();
    final previewUrl = (lower.endsWith('.doc') || lower.endsWith('.docx'))
        ? 'https://view.officeapps.live.com/op/embed.aspx?src=${Uri.encodeComponent(source)}'
        : 'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(source)}';

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(previewUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Preview'),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: WebViewWidget(controller: _webController)),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _DeleteBadge extends StatelessWidget {
  const _DeleteBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.ink.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
        ),
      ),
    );
  }
}
