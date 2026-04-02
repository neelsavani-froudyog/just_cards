import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/contact_detail_model.dart';
import '../../../core/theme/app_colors.dart';
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
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: const Text('Contact Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
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
                      onShare: controller.onShareTap,
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
                return Container(
                  color: const Color(0xFFF5F7FB),
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Column(
                    children: [
                      if (t == ContactDetailsTab.attachments) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: saving ? null : controller.addAttachment,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.ink.withValues(alpha: 0.18)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: Icon(Icons.add_rounded, color: AppColors.ink.withValues(alpha: 0.80)),
                            label: Text(
                              'Add Attachment',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.80),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
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
          width: 62,
          height: 62,
          child: ClipOval(
            child: photo != null && photo.isNotEmpty
                ? Image.network(
                    photo,
                    width: 62,
                    height: 62,
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
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
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
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight.withValues(alpha: 0.95),
            AppColors.primary.withValues(alpha: 0.20),
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: theme.textTheme.titleLarge?.copyWith(
          color: AppColors.ink,
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
    Widget chip(ContactDetailsTab t, String label) {
      final active = tab == t;
      return Expanded(
        child: InkWell(
          onTap: () => onSelect(t),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? AppColors.primary.withValues(alpha: 0.40) : AppColors.ink.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: active ? AppColors.ink : AppColors.ink.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(ContactDetailsTab.details, 'Details'),
        const SizedBox(width: 10),
        chip(ContactDetailsTab.notes, 'Notes'),
        const SizedBox(width: 10),
        chip(ContactDetailsTab.attachments, 'Attachments'),
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
      rows.add(const SizedBox(height: 4));
      rows.add(
        Text(
          'Created on',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.55),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      );
      rows.add(const SizedBox(height: 6));
      rows.add(
        Text(
          _formatDetailDate(created),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.78),
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
            color: AppColors.ink.withValues(alpha: 0.06),
            alignment: Alignment.center,
            child: Icon(Icons.broken_image_outlined, color: AppColors.ink.withValues(alpha: 0.35)),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: AppColors.ink.withValues(alpha: 0.06),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryLight.withValues(alpha: 0.45),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.55),
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
      final hasAny = photos.isNotEmpty || docs.isNotEmpty;

      if (!hasAny) {
        return Center(
          key: key,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Icon(Icons.attach_file_rounded, size: 44, color: AppColors.ink.withValues(alpha: 0.70)),
                ),
                const SizedBox(height: 14),
                Text(
                  'No Attachments yet',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep all your contact-related files, photos,\ndocuments in one place for easy access',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView(
        key: key,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        children: [
          if (photos.isNotEmpty) ...[
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
              tileBuilder: (_, __) => const _ImageThumb(),
            ),
            const SizedBox(height: 14),
          ],
          if (docs.isNotEmpty) ...[
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
              tileBuilder: (_, __) => const _DocThumb(),
            ),
          ],
        ],
      );
    });
  }
}

class _ThumbGrid extends StatelessWidget {
  const _ThumbGrid({required this.items, required this.tileBuilder});

  final List<String> items;
  final Widget Function(BuildContext context, int index) tileBuilder;

  @override
  Widget build(BuildContext context) {
    final tiles = items.length + 1; // + add tile
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        if (index == tiles - 1) return const _AddThumb();
        return tileBuilder(context, index);
      },
    );
  }
}

class _AddThumb extends StatelessWidget {
  const _AddThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.18), width: 1.5),
      ),
      child: Icon(Icons.add_rounded, color: AppColors.ink.withValues(alpha: 0.70)),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  const _ImageThumb();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: AppColors.ink.withValues(alpha: 0.06),
        child: Icon(Icons.image_rounded, color: AppColors.darkGrey.withValues(alpha: 0.45)),
      ),
    );
  }
}

class _DocThumb extends StatelessWidget {
  const _DocThumb();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: AppColors.ink.withValues(alpha: 0.06),
        child: Icon(Icons.picture_as_pdf_rounded, color: AppColors.darkGrey.withValues(alpha: 0.45)),
      ),
    );
  }
}