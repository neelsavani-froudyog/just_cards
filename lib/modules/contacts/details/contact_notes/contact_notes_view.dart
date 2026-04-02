import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/models/contact_note_api_model.dart';
import '../../../../core/services/toast_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../widgets/custom_text_field.dart';
import '../contact_details_controller.dart';
import 'contact_notes_shimmer.dart';

String _formatNoteTimestamp(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso.trim();
  const months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final m = months[dt.month - 1];
  final day = dt.day.toString().padLeft(2, '0');
  final t =
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  return '$day $m ${dt.year}, $t';
}

/// Notes list for a contact (separate module). Uses [ContactDetailsController].
class ContactNotesView extends GetView<ContactDetailsController> {
  const ContactNotesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.isNotesLoading.value) {
        return ContactNotesShimmer(key: key);
      }
      final err = controller.notesErrorText.value;
      if (err != null && err.trim().isNotEmpty) {
        return Center(
          key: key,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 40, color: AppColors.ink.withValues(alpha: 0.45)),
                const SizedBox(height: 10),
                Text(
                  err,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => controller.fetchNotes(force: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      final notes = controller.contactNotes;
      if (notes.isEmpty) {
        return Center(
          key: key,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
                  ),
                  child: Icon(Icons.sticky_note_2_outlined, size: 40, color: AppColors.ink.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 14),
                Text(
                  'No notes yet',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap Create Note to add a note.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.62),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        key: key,
        color: AppColors.primary,
        onRefresh: () => controller.fetchNotes(force: true),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          itemCount: notes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final n = notes[index];
            final showActions = controller.canManageNote(n);
            return _ContactNoteCard(
              note: n,
              showActions: showActions,
              onEdit: () => _onEditNote(context, n),
              onDelete: () => _onDeleteNote(context, n),
            );
          },
        ),
      );
    });
  }
}

class _ContactNoteCard extends StatelessWidget {
  const _ContactNoteCard({
    required this.note,
    required this.showActions,
    required this.onEdit,
    required this.onDelete,
  });

  final ContactNoteApiItem note;
  final bool showActions;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _authorLine(ContactNoteAuthor a) {
    final name = a.fullName.trim();
    if (name.isNotEmpty) return name;
    final mail = a.email.trim();
    if (mail.isNotEmpty) return mail;
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = note.author.email.trim().isNotEmpty && note.author.fullName.trim().isNotEmpty
        ? note.author.email.trim()
        : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.noteText,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'created by: $sub',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.52),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (note.createdAt.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'created at: ${_formatNoteTimestamp(note.createdAt)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showActions)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.edit_outlined, color: AppColors.ink.withValues(alpha: 0.72)),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_outline_rounded, color: AppColors.ink.withValues(alpha: 0.72)),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
        ],
      ),
    );
  }
}

void showContactCreateNoteDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const _CreateNoteDialog(),
  );
}

Future<void> _onEditNote(BuildContext context, ContactNoteApiItem item) async {
  showDialog<void>(
    context: context,
    builder: (ctx) => _CreateNoteDialog(
      initialText: item.noteText,
      isEditMode: true,
      editNoteId: item.id,
      editVisibility: item.visibility,
    ),
  );
}

Future<void> _onDeleteNote(BuildContext context, ContactNoteApiItem item) async {
  final go = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: AppColors.ink.withValues(alpha: 0.48),
    builder: (ctx) => _DeleteNoteConfirmDialog(note: item),
  );
  if (go == true && context.mounted) {
    await Get.find<ContactDetailsController>().deleteContactNote(item.id);
  }
}

class _DeleteNoteConfirmDialog extends StatelessWidget {
  const _DeleteNoteConfirmDialog({required this.note});

  final ContactNoteApiItem note;

  static const int _previewMaxChars = 120;

  String _previewText() {
    final t = note.noteText.trim();
    if (t.length <= _previewMaxChars) return t;
    return '${t.substring(0, _previewMaxChars).trim()}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _previewText();

    return Dialog(
      backgroundColor: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.ink.withValues(alpha: 0.08)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withValues(alpha: 0.10),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.22),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 36,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Delete this note?',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'This will remove the note for everyone who can see it. You can’t undo this action.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.58),
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink.withValues(alpha: 0.78),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.ink.withValues(alpha: 0.18)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Delete',
                      style: theme.textTheme.titleSmall?.copyWith(
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
    );
  }
}

class _CreateNoteDialog extends StatefulWidget {
  const _CreateNoteDialog({
    this.initialText = '',
    this.isEditMode = false,
    this.editNoteId,
    this.editVisibility,
  });

  final String initialText;
  final bool isEditMode;
  final String? editNoteId;
  final String? editVisibility;

  @override
  State<_CreateNoteDialog> createState() => _CreateNoteDialogState();
}

class _CreateNoteDialogState extends State<_CreateNoteDialog> {
  late final TextEditingController _noteCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final text = _noteCtrl.text.trim();
    if (widget.isEditMode) {
      final nid = widget.editNoteId?.trim() ?? '';
      if (nid.isEmpty) {
        await ToastService.error('Invalid note');
        return;
      }
      if (text.isEmpty) {
        await ToastService.info('Please enter a note');
        return;
      }
      if (text.length > ContactDetailsController.maxNoteLength) {
        await ToastService.info(
          'Note is too long (max ${ContactDetailsController.maxNoteLength} characters)',
        );
        return;
      }
      setState(() => _submitting = true);
      try {
        final c = Get.find<ContactDetailsController>();
        final vis = widget.editVisibility?.trim() ?? '';
        final ok = await c.updateContactNote(
          noteId: nid,
          text: text,
          visibility: vis,
        );
        if (mounted && ok) Navigator.of(context).pop();
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }
    if (text.isEmpty) {
      await ToastService.info('Please enter a note');
      return;
    }
    if (text.length > ContactDetailsController.maxNoteLength) {
      await ToastService.info(
        'Note is too long (max ${ContactDetailsController.maxNoteLength} characters)',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final c = Get.find<ContactDetailsController>();
      final ok = await c.saveContactNote(text);
      if (mounted && ok) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.isEditMode ? 'Edit Note' : 'Create Note';
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Notes',
              hint: 'Write your note…',
              controller: _noteCtrl,
              minLines: 4,
              maxLines: 8,
              maxLength: 600,
              filled: true,
              fillColor: AppColors.white,
              borderRadius: 14,
              borderColor: AppColors.ink.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AppColors.ink.withValues(alpha: 0.22)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Cancel',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _onSave,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                          )
                        : Text(
                            widget.isEditMode ? 'Update' : 'Save',
                            style: theme.textTheme.titleSmall?.copyWith(
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
    );
  }
}
