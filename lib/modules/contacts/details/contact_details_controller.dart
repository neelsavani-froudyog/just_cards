import 'dart:io';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_listing_urls.dart';
import '../../../core/models/contact_detail_model.dart';
import '../../../core/models/contact_note_api_model.dart';
import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_session_service.dart';
import '../../../core/services/create_contact_service.dart';
import '../../../core/services/document_scanner_service.dart';
import '../../../core/services/http_sender_io.dart';
import '../../../core/services/toast_service.dart';
import '../../../routes/app_routes.dart';

enum ContactDetailsTab { details, notes, attachments }

class ContactDetailsController extends GetxController {
  static const int maxNoteLength = 600;
  static const int _maxImageBytes = 2 * 1024 * 1024; // 2 MB
  static const int _maxPdfBytes = 50 * 1024 * 1024; // 50 MB
  static const int _uploadBatchSize = 3;

  late final ApiService _apiService;
  final ImagePicker _imagePicker = ImagePicker();

  final tab = ContactDetailsTab.details.obs;
  final isSaving = false.obs;
  final isLoading = true.obs;
  final detail = Rxn<ContactDetail>();
  final errorText = RxnString();

  final contactNotes = <ContactNoteApiItem>[].obs;
  final isNotesLoading = false.obs;
  final notesErrorText = RxnString();

  final photos = <String>[].obs;
  final docs = <String>[].obs;
  final isAttachmentsLoading = false.obs;
  final attachmentsErrorText = RxnString();
  final _apiAttachmentIdByPath = <String, String>{};

  String? _contactId;
  String? _cachedProfileUserId;

  /// Drives AppBar owner menu; kept in sync with [_cachedProfileUserId].
  final profileUserId = RxnString();

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _contactId = _readContactId();
    if (_contactId == null || _contactId!.isEmpty) {
      isLoading.value = false;
      errorText.value = 'Missing contact id';
      return;
    }
    fetchDetail();
    Future<void>.microtask(_resolveCurrentUserId);
  }

  /// Edit / delete AppBar menu when `owner_user_id` matches logged-in user.
  bool get canShowContactOwnerActions {
    final d = detail.value;
    if (d == null) return false;
    final owner = d.ownerUserId?.trim() ?? '';
    final me = profileUserId.value?.trim() ?? '';
    if (owner.isEmpty || me.isEmpty) return false;
    return owner == me;
  }

  Future<void> openEditContact() async {
    final id = _contactId?.trim() ?? '';
    if (id.isEmpty) return;
    final updated = await Get.toNamed(
      Routes.editContact,
      arguments: <String, dynamic>{'contactId': id},
    );
    if (updated == true) {
      await fetchDetail();
    }
  }

  final isDeletingContact = false.obs;

  Future<void> deleteContact() async {
    if (isDeletingContact.value) return;
    final id = _contactId?.trim() ?? '';
    if (id.isEmpty) {
      ToastService.error('Contact not available');
      return;
    }

    isDeletingContact.value = true;
    try {
      final result =
          await Get.find<CreateContactService>().deleteContact(contactId: id);
      if (result.success) {
        await ToastService.success(result.message ?? 'Contact deleted');
        Get.back(result: Routes.contactDeletedPopResult);
      } else {
        await ToastService.error(result.message ?? 'Failed to delete contact');
      }
    } finally {
      isDeletingContact.value = false;
    }
  }

  /// Returns `true` if the note was created on the server.
  Future<bool> saveContactNote(String text) async {
    final contactId = _contactId?.trim() ?? '';
    if (contactId.isEmpty) {
      await ToastService.error('Contact not available. Go back and open the contact again.');
      return false;
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await ToastService.info('Please enter a note');
      return false;
    }
    if (trimmed.length > maxNoteLength) {
      await ToastService.info('Note is too long (max $maxNoteLength characters)');
      return false;
    }

    final visibility = _pVisibilityForNote();

    var saved = false;
    await _apiService.postRequest(
      url: ApiUrl.contactNotes,
      data: <String, dynamic>{
        'p_contact_id': contactId,
        'p_note_text': trimmed,
        'p_visibility': visibility,
      },
      showSuccessToast: false,
      showErrorToast: false,
      onSuccess: (payload) {
        final raw = payload['response'];
        if (raw is! Map<String, dynamic>) {
          ToastService.error('Invalid response from server');
          return;
        }
        if (raw['ok'] != true) {
          final msg = raw['message']?.toString().trim();
          ToastService.error(
            msg != null && msg.isNotEmpty ? msg : 'Could not save note',
          );
          return;
        }
        final okMsg = raw['message']?.toString().trim();
        ToastService.success(
          okMsg != null && okMsg.isNotEmpty ? okMsg : 'Note saved',
        );
        saved = true;
      },
      onError: (message) {
        ToastService.error(
          message.trim().isNotEmpty ? message : 'Could not save note',
        );
      },
    );

    if (saved) {
      await fetchNotes(force: true);
    }
    return saved;
  }

  /// PATCH `/contacts/notes` — on success refreshes notes via [fetchNotes].
  Future<bool> updateContactNote({
    required String noteId,
    required String text,
    required String visibility,
  }) async {
    final nid = noteId.trim();
    if (nid.isEmpty) {
      await ToastService.error('Invalid note');
      return false;
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await ToastService.info('Please enter a note');
      return false;
    }
    if (trimmed.length > maxNoteLength) {
      await ToastService.info('Note is too long (max $maxNoteLength characters)');
      return false;
    }

    final vis = visibility.trim();
    final pVisibility = vis.isNotEmpty ? vis : _pVisibilityForNote();

    var updated = false;
    await _apiService.patchRequest(
      url: ApiUrl.contactNotes,
      data: <String, dynamic>{
        'p_note_id': nid,
        'p_note_text': trimmed,
        'p_visibility': pVisibility,
      },
      showSuccessToast: false,
      showErrorToast: false,
      onSuccess: (payload) {
        final raw = payload['response'];
        if (raw is! Map<String, dynamic>) {
          ToastService.error('Invalid response from server');
          return;
        }
        if (raw['ok'] != true) {
          final msg = raw['message']?.toString().trim();
          ToastService.error(
            msg != null && msg.isNotEmpty ? msg : 'Could not update note',
          );
          return;
        }
        final okMsg = raw['message']?.toString().trim();
        ToastService.success(
          okMsg != null && okMsg.isNotEmpty ? okMsg : 'Note updated',
        );
        updated = true;
      },
      onError: (message) {
        ToastService.error(
          message?.trim().isNotEmpty == true ? message!.trim() : 'Could not update note',
        );
      },
    );

    if (updated) {
      await fetchNotes(force: true);
    }
    return updated;
  }

  Future<void> fetchNotes({bool force = false}) async {
    final contactId = _contactId?.trim() ?? '';
    if (contactId.isEmpty) return;
    if (isNotesLoading.value && !force) return;

    isNotesLoading.value = true;
    notesErrorText.value = null;

    await _resolveCurrentUserId();

    await _apiService.getRequest(
      url: ApiUrl.contactNotes,
      queryParameters: <String, dynamic>{'p_contact_id': contactId},
      showSuccessToast: false,
      showErrorToast: false,
      onSuccess: (payload) {
        final raw = payload['response'];
        if (raw is! Map<String, dynamic>) {
          notesErrorText.value = 'Invalid notes response';
          contactNotes.clear();
          return;
        }
        if (raw['ok'] != true) {
          final msg = raw['message']?.toString().trim();
          notesErrorText.value =
              msg != null && msg.isNotEmpty ? msg : 'Could not load notes';
          contactNotes.clear();
          return;
        }
        final listRaw = raw['data'];
        if (listRaw is! List) {
          contactNotes.clear();
          return;
        }
        final parsed = <ContactNoteApiItem>[];
        for (final item in listRaw) {
          if (item is Map<String, dynamic>) {
            parsed.add(ContactNoteApiItem.fromJson(item));
          } else if (item is Map) {
            parsed.add(ContactNoteApiItem.fromJson(Map<String, dynamic>.from(item)));
          }
        }
        contactNotes.assignAll(parsed);
        notesErrorText.value = null;
      },
      onError: (message) {
        notesErrorText.value =
            message?.trim().isNotEmpty == true ? message!.trim() : 'Could not load notes';
        contactNotes.clear();
      },
    );

    isNotesLoading.value = false;
  }

  Future<void> _resolveCurrentUserId() async {
    final existing = _cachedProfileUserId?.trim() ?? '';
    if (existing.isNotEmpty) {
      profileUserId.value = existing;
      return;
    }
    final id = await Get.find<CreateContactService>().fetchProfileUserId();
    _cachedProfileUserId = id?.trim();
    profileUserId.value = _cachedProfileUserId;
  }

  bool canManageNote(ContactNoteApiItem note) {
    final me = _cachedProfileUserId?.trim() ?? '';
    final author = note.author.id.trim();
    return me.isNotEmpty && author.isNotEmpty && me == author;
  }

  /// DELETE `/contacts/notes` with `p_note_id` — on success refreshes notes.
  Future<void> deleteContactNote(String noteId) async {
    final id = noteId.trim();
    if (id.isEmpty) return;

    var deleted = false;
    await _apiService.deleteRequest(
      url: ApiUrl.contactNotes,
      data: <String, dynamic>{'p_note_id': id},
      showSuccessToast: false,
      showErrorToast: false,
      onSuccess: (payload) {
        final raw = payload['response'];
        if (raw is Map<String, dynamic>) {
          if (raw['ok'] != true) {
            final msg = raw['message']?.toString().trim();
            ToastService.error(
              msg != null && msg.isNotEmpty ? msg : 'Could not delete note',
            );
            return;
          }
          final okMsg = raw['message']?.toString().trim();
          ToastService.success(
            okMsg != null && okMsg.isNotEmpty ? okMsg : 'Note deleted',
          );
          deleted = true;
          return;
        }
        ToastService.success('Note deleted');
        deleted = true;
      },
      onError: (message) {
        ToastService.error(
          message?.trim().isNotEmpty == true ? message!.trim() : 'Could not delete note',
        );
      },
    );

    if (deleted) {
      await fetchNotes(force: true);
    }
  }

  /// From contact detail: event → `event`, else organization → `organization`, else `private`.
  String _pVisibilityForNote() {
    final d = detail.value;
    if (d == null) return 'private';
    if (d.event != null) return 'event';
    if (d.organization != null) return 'organization';
    return 'private';
  }

  String? _readContactId() {
    final args = Get.arguments;
    if (args is String && args.trim().isNotEmpty) return args.trim();
    if (args is Map) {
      final id = args['contactId'] ?? args['id'] ?? args['p_contact_id'];
      final s = id?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return null;
  }

  Future<void> fetchDetail() async {
    final id = _contactId;
    if (id == null || id.isEmpty) return;

    isLoading.value = true;
    errorText.value = null;

    await _apiService.postRequest(
      url: ApiUrl.contactDetail,
      data: <String, dynamic>{'p_contact_id': id},
      showSuccessToast: false,
      showErrorToast: false,
      onSuccess: (payload) {
        final raw = payload['response'];
        if (raw is! Map<String, dynamic>) {
          errorText.value = 'Invalid response';
          detail.value = null;
          return;
        }
        if (raw['ok'] != true) {
          errorText.value =
              raw['message']?.toString().trim().isNotEmpty == true
                  ? raw['message'].toString()
                  : 'Could not load contact';
          detail.value = null;
          return;
        }
        final data = raw['data'];
        if (data is! Map<String, dynamic>) {
          errorText.value = 'Invalid contact data';
          detail.value = null;
          return;
        }
        detail.value = ContactDetail.fromJson(data);
        errorText.value = null;
      },
      onError: (message) {
        errorText.value =
            message.trim().isNotEmpty ? message : 'Could not load contact';
        detail.value = null;
      },
    );

    isLoading.value = false;
  }

  void setTab(ContactDetailsTab t) {
    tab.value = t;
    if (t == ContactDetailsTab.notes) {
      fetchNotes();
      return;
    }
    if (t == ContactDetailsTab.attachments) {
      fetchAttachments();
    }
  }

  Future<void> fetchAttachments({bool force = false}) async {
    final contactId = _contactId?.trim() ?? '';
    if (contactId.isEmpty) return;
    if (isAttachmentsLoading.value && !force) return;

    isAttachmentsLoading.value = true;
    attachmentsErrorText.value = null;

    await _apiService.getRequest(
      url: ApiUrl.contactAttachments,
      queryParameters: <String, dynamic>{'p_contact_id': contactId},
      showSuccessToast: false,
      showErrorToast: false,
      onSuccess: (payload) {
        final raw = payload['response'];
        if (raw is! Map<String, dynamic>) {
          attachmentsErrorText.value = 'Invalid attachments response';
          photos.clear();
          docs.clear();
          return;
        }
        if (raw['ok'] != true) {
          final msg = raw['message']?.toString().trim();
          attachmentsErrorText.value =
              msg != null && msg.isNotEmpty ? msg : 'Could not load attachments';
          photos.clear();
          docs.clear();
          return;
        }

        final dynamic rootData = raw['data'];
        Map<String, dynamic>? dataMap;
        if (rootData is Map<String, dynamic>) {
          dataMap = rootData;
        } else if (rootData is Map) {
          dataMap = Map<String, dynamic>.from(rootData);
        }

        final dynamic listRaw = dataMap?['data'];
        if (dataMap?['ok'] == false) {
          final msg = dataMap?['message']?.toString().trim();
          attachmentsErrorText.value =
              msg != null && msg.isNotEmpty ? msg : 'Could not load attachments';
          photos.clear();
          docs.clear();
          return;
        }
        if (listRaw is! List) {
          photos.clear();
          docs.clear();
          return;
        }

        final nextPhotos = <String>[];
        final nextDocs = <String>[];
        final nextApiAttachmentIdByPath = <String, String>{};

        for (final item in listRaw) {
          Map<String, dynamic>? row;
          if (item is Map<String, dynamic>) {
            row = item;
          } else if (item is Map) {
            row = Map<String, dynamic>.from(item);
          }
          if (row == null) continue;

          final fileUrl = row['file_url']?.toString().trim() ?? '';
          if (fileUrl.isEmpty) continue;
          final attachmentId = row['id']?.toString().trim() ?? '';
          final attachmentType = row['attachment_type']?.toString().trim().toLowerCase() ?? '';
          if (attachmentType == 'image') {
            nextPhotos.add(fileUrl);
          } else {
            nextDocs.add(fileUrl);
          }
          if (attachmentId.isNotEmpty) {
            nextApiAttachmentIdByPath[fileUrl] = attachmentId;
          }
        }

        photos.assignAll(nextPhotos);
        docs.assignAll(nextDocs);
        _apiAttachmentIdByPath
          ..clear()
          ..addAll(nextApiAttachmentIdByPath);
        attachmentsErrorText.value = null;
      },
      onError: (message) {
        attachmentsErrorText.value =
            message?.trim().isNotEmpty == true ? message!.trim() : 'Could not load attachments';
      },
    );

    isAttachmentsLoading.value = false;
  }

  Future<void> onCallTap() async {
    final phone = detail.value?.primaryPhone;
    if (phone == null || phone.isEmpty) {
      ToastService.info('No phone number on file');
      return;
    }
    final clean = phone.replaceAll(RegExp(r'\s'), '');
    final uri = Uri.parse('tel:$clean');
    if (!await launchUrl(uri)) {
      ToastService.error('Could not start call');
    }
  }

  Future<void> onEmailTap() async {
    final email = detail.value?.primaryEmail;
    if (email == null || email.isEmpty) {
      ToastService.info('No email on file');
      return;
    }
    final uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri)) {
      ToastService.error('Could not open email');
    }
  }

  /// Digits only, in the shape [wa.me](https://wa.me/) expects (no `+`).
  /// 10-digit Indian mobiles must include `91` or WhatsApp parses a leading
  /// `965…` as Kuwait (+965) instead of India (+91).
  static String? _digitsForWhatsAppLink(String rawPhone) {
    var digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    // Already `91` + 10-digit Indian mobile
    if (digits.length == 12 && digits.startsWith('91')) {
      final national = digits.substring(2);
      if (RegExp(r'^[6-9]\d{9}$').hasMatch(national)) {
        return digits;
      }
    }
    // Common case: 10-digit Indian mobile stored without country code
    if (digits.length == 10 && RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      return '91$digits';
    }
    // `0` + 10-digit Indian mobile
    if (digits.length == 11 && digits.startsWith('0')) {
      final national = digits.substring(1);
      if (RegExp(r'^[6-9]\d{9}$').hasMatch(national)) {
        return '91$national';
      }
    }
    return digits;
  }

  Future<void> onWhatsAppTap() async {
    final phone = detail.value?.primaryPhone;
    if (phone == null || phone.isEmpty) {
      ToastService.info('No phone number on file');
      return;
    }
    final digits = _digitsForWhatsAppLink(phone);
    if (digits == null || digits.isEmpty) {
      ToastService.info('Invalid phone for WhatsApp');
      return;
    }
    final uri = Uri.parse('https://wa.me/$digits');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ToastService.error('Could not open WhatsApp');
    }
  }

  Future<void> shareContactDetails() async {
    final d = detail.value;
    if (d == null) {
      ToastService.info('No contact to share');
      return;
    }
    final text = _formatContactShareDetails(d);
    if (text.trim().isEmpty) {
      ToastService.info('Nothing to share');
      return;
    }
    await Share.share(
      text,
      subject: d.displayName.trim().isEmpty ? 'Contact details' : d.displayName,
    );
  }

  Future<void> openGooglePlayListing() async {
    await _openExternalUrl(AppListingUrls.googlePlay);
  }

  Future<void> openAppStoreListing() async {
    await _openExternalUrl(AppListingUrls.appStore);
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      ToastService.error('Invalid link');
      return;
    }
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ToastService.error('Could not open link');
    }
  }

  /// Plain-text share card with friendly labels and app link.
  /// Omits any line whose value is null, empty, whitespace, or a placeholder.
  static String _formatContactShareDetails(ContactDetail d) {
    final body = <String>[];

    void addEmojiLine(String emojiLabel, String? raw) {
      final v = _shareValueOrNull(raw);
      if (v == null) return;
      body.add('$emojiLabel $v');
    }

    final name = _shareNameLine(d);
    addEmojiLine('👤 Name:', name);
    addEmojiLine('💼 Designation:', d.designation);
    addEmojiLine('🏢 Company:', d.companyName);
    addEmojiLine('📞 Mobile:', d.phone1);
    addEmojiLine('☎️ Phone:', d.phone2);
    addEmojiLine('✉️ Email 1:', d.email1);
    addEmojiLine('📧 Email 2:', d.email2);

    if (body.isEmpty) return '';
    return <String>[
      'Scanned via Just Cards App',
      '',
      ...body,
      '',
      '\n📲 Get the app: ${AppListingUrls.googlePlay}',
    ].join('\n');
  }

  static String? _shareValueOrNull(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return null;
    final lower = v.toLowerCase();
    if (v == '—' || v == '-' || v == '–' || lower == 'n/a' || lower == 'na') {
      return null;
    }
    return v;
  }

  /// Name for share text only (no `Contact` fallback when everything is blank).
  static String? _shareNameLine(ContactDetail d) {
    final fromFull = _shareValueOrNull(d.fullName);
    if (fromFull != null) return fromFull;
    final combined = '${d.firstName.trim()} ${d.lastName.trim()}'.trim();
    return _shareValueOrNull(combined.isEmpty ? null : combined);
  }

  bool get hasLocalAttachments {
    for (final p in photos) {
      if (_isLocalPath(p)) return true;
    }
    for (final d in docs) {
      if (_isLocalPath(d)) return true;
    }
    return false;
  }

  Future<void> saveChanges() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      final localPhotos = photos.where(_isLocalPath).toList(growable: false);
      final localDocs = docs.where(_isLocalPath).toList(growable: false);
      if (localPhotos.isEmpty && localDocs.isEmpty) {
        await ToastService.info('No local attachments to upload');
        return;
      }

      final contactId = _contactId?.trim() ?? '';
      if (contactId.isEmpty) {
        await ToastService.error('Contact not available. Go back and open the contact again.');
        return;
      }
      final token = Get.find<AuthSessionService>().accessToken.value.trim();
      if (token.isEmpty) {
        await ToastService.error('Session expired. Please login again.');
        return;
      }

      final imageUploaded = await _uploadInBatches(
        token: token,
        contactId: contactId,
        attachmentType: 'image',
        paths: localPhotos,
      );
      if (imageUploaded == null) return;

      final docsUploaded = await _uploadInBatches(
        token: token,
        contactId: contactId,
        attachmentType: 'document',
        paths: localDocs,
      );
      if (docsUploaded == null) return;

      _clearLocalAttachmentsFromLists();
      await fetchAttachments(force: true);
      await ToastService.success('${imageUploaded + docsUploaded} attachment(s) uploaded');
    } finally {
      isSaving.value = false;
    }
  }

  bool _isLocalPath(String path) {
    final p = path.trim();
    if (p.isEmpty) return false;
    return !(p.startsWith('http://') || p.startsWith('https://'));
  }

  Future<void> addPhotosFromGallery() async {
    final picked = await _imagePicker.pickMultiImage();
    if (picked.isEmpty) return;
    final accepted = <String>[];
    var skipped = 0;
    for (final x in picked) {
      final path = x.path.trim();
      if (path.isEmpty) continue;
      final f = File(path);
      if (!await f.exists()) {
        skipped++;
        continue;
      }
      final bytes = await f.length();
      if (bytes > _maxImageBytes) {
        skipped++;
        continue;
      }
      accepted.add(path);
    }
    if (accepted.isNotEmpty) {
      _addLocalUnique(photos, accepted);
    }
    if (skipped > 0) {
      await ToastService.info('Skipped $skipped image(s). Max allowed size is 2 MB per image.');
    }
  }

  Future<void> addPhotosFromCameraScanner() async {
    final scannedPaths = await DocumentScannerService.scan(allowMultiple: true);
    if (scannedPaths.isEmpty) return;
    final accepted = <String>[];
    var skipped = 0;
    for (final rawPath in scannedPaths) {
      final path = rawPath.trim();
      if (path.isEmpty) continue;
      final f = File(path);
      if (!await f.exists()) {
        skipped++;
        continue;
      }
      final bytes = await f.length();
      if (bytes > _maxImageBytes) {
        skipped++;
        continue;
      }
      accepted.add(path);
    }
    if (accepted.isNotEmpty) {
      _addLocalUnique(photos, accepted);
    }
    if (skipped > 0) {
      await ToastService.info('Skipped $skipped image(s). Max allowed size is 2 MB per image.');
    }
  }

  Future<void> addPdfFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;
    final accepted = <String>[];
    var skipped = 0;
    for (final f in result.files) {
      final path = f.path?.trim() ?? '';
      if (path.isEmpty) {
        skipped++;
        continue;
      }
      final bytes = f.size;
      if (bytes > _maxPdfBytes) {
        skipped++;
        continue;
      }
      accepted.add(path);
    }
    if (accepted.isNotEmpty) {
      _addLocalUnique(docs, accepted);
    }
    if (skipped > 0) {
      await ToastService.info('Skipped $skipped file(s). Max allowed size is 50 MB per PDF.');
    }
  }

  Future<void> removePhotoAt(int index) async {
    if (index < 0 || index >= photos.length) return;
    final path = photos[index];
    final attachmentId = _apiAttachmentIdByPath[path];
    if (attachmentId != null) {
      final deleted = await _deleteServerAttachment(attachmentId);
      if (!deleted) return;
      _apiAttachmentIdByPath.remove(path);
    }
    photos.removeAt(index);
  }

  Future<void> removeDocAt(int index) async {
    if (index < 0 || index >= docs.length) return;
    final path = docs[index];
    final attachmentId = _apiAttachmentIdByPath[path];
    if (attachmentId != null) {
      final deleted = await _deleteServerAttachment(attachmentId);
      if (!deleted) return;
      _apiAttachmentIdByPath.remove(path);
    }
    docs.removeAt(index);
  }

  void _addLocalUnique(RxList<String> target, List<String> paths) {
    for (final raw in paths) {
      final p = raw.trim();
      if (p.isEmpty) continue;
      if (!target.contains(p)) target.add(p);
    }
  }

  void _clearLocalAttachmentsFromLists() {
    photos.removeWhere(_isLocalPath);
    docs.removeWhere(_isLocalPath);
  }

  Future<int?> _uploadInBatches({
    required String token,
    required String contactId,
    required String attachmentType,
    required List<String> paths,
  }) async {
    if (paths.isEmpty) return 0;
    final unique = <String>[];
    final seen = <String>{};
    for (final raw in paths) {
      final p = raw.trim();
      if (p.isEmpty) continue;
      if (seen.add(p)) unique.add(p);
    }

    var uploaded = 0;
    for (var i = 0; i < unique.length; i += _uploadBatchSize) {
      final end = (i + _uploadBatchSize > unique.length) ? unique.length : i + _uploadBatchSize;
      final batch = unique.sublist(i, end);
      final results = await Future.wait(
        batch.map(
          (path) => _uploadAttachment(
            token: token,
            contactId: contactId,
            attachmentType: attachmentType,
            filePath: path,
          ),
        ),
      );
      if (results.any((ok) => !ok)) return null;
      uploaded += results.length;
    }
    return uploaded;
  }

  Future<bool> _uploadAttachment({
    required String token,
    required String contactId,
    required String attachmentType,
    required String filePath,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      await ToastService.error('File not found: $filePath');
      return false;
    }

    final uri = Uri.parse('${ApiUrl.baseUrl}${ApiUrl.contactAttachmentsUpload}');
    final response = await sendMultipartFormData(
      uri: uri,
      headers: <String, String>{'Authorization': 'Bearer $token'},
      textFields: <String, String>{
        'p_contact_id': contactId,
        'p_attachment_type': attachmentType,
      },
      fileFieldName: 'file',
      file: file,
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(response.bodyText);
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = _extractUploadErrorMessage(decoded) ?? 'Could not upload attachment';
      await ToastService.error(message);
      return false;
    }
    if (decoded is Map<String, dynamic>) {
      if (decoded['ok'] == false) {
        final message = _extractUploadErrorMessage(decoded) ?? 'Could not upload attachment';
        await ToastService.error(message);
        return false;
      }
    }
    return true;
  }

  String? _extractUploadErrorMessage(dynamic decoded) {
    if (decoded is Map) {
      final msg = decoded['message'] ?? decoded['error'];
      final s = msg?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
      final nested = decoded['data'];
      if (nested is Map) {
        final nestedMsg = nested['message']?.toString().trim();
        if (nestedMsg != null && nestedMsg.isNotEmpty) return nestedMsg;
      }
    }
    return null;
  }

  Future<bool> _deleteServerAttachment(String attachmentId) async {
    var deleted = false;
    await _apiService.deleteRequest(
      url: ApiUrl.contactAttachments,
      data: <String, dynamic>{'p_attachment_id': attachmentId},
      showSuccessToast: false,
      showErrorToast: false,
      onSuccess: (payload) {
        final raw = payload['response'];
        if (raw is Map<String, dynamic>) {
          if (raw['ok'] == false) {
            final msg = raw['message']?.toString().trim();
            ToastService.error(
              msg != null && msg.isNotEmpty ? msg : 'Could not delete attachment',
            );
            return;
          }
          final nested = raw['data'];
          if (nested is Map && nested['ok'] == false) {
            final msg = nested['message']?.toString().trim();
            ToastService.error(
              msg != null && msg.isNotEmpty ? msg : 'Could not delete attachment',
            );
            return;
          }
        }
        deleted = true;
      },
      onError: (message) {
        ToastService.error(
          message?.trim().isNotEmpty == true ? message!.trim() : 'Could not delete attachment',
        );
      },
    );
    return deleted;
  }
}
