import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/contact_detail_model.dart';
import '../../../core/models/contact_note_api_model.dart';
import '../../../core/services/api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/create_contact_service.dart';
import '../../../core/services/toast_service.dart';

enum ContactDetailsTab { details, notes, attachments }

class ContactDetailsController extends GetxController {
  static const int maxNoteLength = 600;

  late final ApiService _apiService;

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

  String? _contactId;
  String? _cachedProfileUserId;

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
    if (existing.isNotEmpty) return;
    final id = await Get.find<CreateContactService>().fetchProfileUserId();
    _cachedProfileUserId = id?.trim();
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
    }
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

  Future<void> onWhatsAppTap() async {
    final phone = detail.value?.primaryPhone;
    if (phone == null || phone.isEmpty) {
      ToastService.info('No phone number on file');
      return;
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      ToastService.info('Invalid phone for WhatsApp');
      return;
    }
    final uri = Uri.parse('https://wa.me/$digits');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ToastService.error('Could not open WhatsApp');
    }
  }

  void onShareTap() {
    ToastService.info('Share coming soon');
  }

  Future<void> saveChanges() async {
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      ToastService.success('Changes saved');
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> addAttachment() async {
    photos.add('photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
  }
}
