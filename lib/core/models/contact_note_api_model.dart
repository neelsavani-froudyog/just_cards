class ContactNoteAuthor {
  const ContactNoteAuthor({
    required this.id,
    required this.email,
    required this.fullName,
  });

  final String id;
  final String email;
  final String fullName;

  factory ContactNoteAuthor.fromJson(Map<String, dynamic> json) {
    return ContactNoteAuthor(
      id: (json['id'] ?? '').toString().trim(),
      email: (json['email'] ?? '').toString().trim(),
      fullName: (json['full_name'] ?? '').toString().trim(),
    );
  }

  static ContactNoteAuthor? maybeFrom(dynamic raw) {
    if (raw == null) return null;
    if (raw is! Map) return null;
    return ContactNoteAuthor.fromJson(Map<String, dynamic>.from(raw));
  }
}

/// One note from `GET /contacts/notes`.
class ContactNoteApiItem {
  const ContactNoteApiItem({
    required this.id,
    required this.author,
    required this.noteText,
    required this.createdAt,
    required this.updatedAt,
    required this.visibility,
  });

  final String id;
  final ContactNoteAuthor author;
  final String noteText;
  final String createdAt;
  final String updatedAt;
  final String visibility;

  factory ContactNoteApiItem.fromJson(Map<String, dynamic> json) {
    final authorRaw = json['author'];
    final author = ContactNoteAuthor.maybeFrom(authorRaw) ??
        const ContactNoteAuthor(id: '', email: '', fullName: '');
    return ContactNoteApiItem(
      id: (json['id'] ?? '').toString().trim(),
      author: author,
      noteText: (json['note_text'] ?? '').toString().trim(),
      createdAt: (json['created_at'] ?? '').toString().trim(),
      updatedAt: (json['updated_at'] ?? '').toString().trim(),
      visibility: (json['visibility'] ?? '').toString().trim(),
    );
  }

  String get visibilityLabel {
    final v = visibility.toLowerCase();
    if (v.isEmpty) return 'Note';
    return v[0].toUpperCase() + (v.length > 1 ? v.substring(1) : '');
  }
}
