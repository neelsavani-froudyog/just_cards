import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../services/toast_service.dart';
import '../../modules/events/manage/event_contacts_model.dart';
import '../../modules/events/manage/event_members_model.dart';
import '../../modules/organization/detail/organization_contacts_model.dart';

/// Safe stem for CSV file names (no path separators or illegal characters).
String sanitizeCsvExportStem(String raw, {String fallback = 'export'}) {
  var s = raw.trim();
  if (s.isEmpty) return fallback;
  s = s.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
  s = s.replaceAll(RegExp(r'[\x00-\x1f]'), '_');
  s = s.replaceAll(RegExp(r'\s+'), '_');
  while (s.contains('__')) {
    s = s.replaceAll('__', '_');
  }
  s = s.replaceAll(RegExp(r'^_+|_+$'), '');
  if (s.isEmpty) return fallback;
  if (s.length > 96) {
    s = s.substring(0, 96);
  }
  return s;
}

String _escapeCsvField(String? raw) {
  final s = raw ?? '';
  if (s.contains(',') ||
      s.contains('"') ||
      s.contains('\n') ||
      s.contains('\r')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

String buildEventContactsCsv(Iterable<EventContactItem> items) {
  final buf = StringBuffer();
  buf.writeln(
    [
      'Full name',
      'Email 1',
      'Email 2',
      'Phone 1',
      'Phone 2',
      'Company',
      'Title',
      'Website',
      'Address',
      'Status',
    ].join(','),
  );
  for (final c in items) {
    buf.writeln(
      [
        _escapeCsvField(c.fullName),
        _escapeCsvField(c.email1),
        _escapeCsvField(c.email2),
        _escapeCsvField(c.phone1),
        _escapeCsvField(c.phone2),
        _escapeCsvField(c.companyName),
        _escapeCsvField(c.designation),
        _escapeCsvField(c.website),
        _escapeCsvField(c.address),
        _escapeCsvField(c.status),
      ].join(','),
    );
  }
  return buf.toString();
}

Uint8List buildEventContactsXlsxBytes(Iterable<EventContactItem> items) {
  final excel = Excel.createExcel();
  final sheet = excel['Contacts'];
  sheet.appendRow(<CellValue>[
    TextCellValue('Full name'),
    TextCellValue('Email 1'),
    TextCellValue('Email 2'),
    TextCellValue('Phone 1'),
    TextCellValue('Phone 2'),
    TextCellValue('Company'),
    TextCellValue('Title'),
    TextCellValue('Website'),
    TextCellValue('Address'),
    TextCellValue('Status'),
  ]);

  for (final c in items) {
    sheet.appendRow(<CellValue>[
      TextCellValue(c.fullName),
      TextCellValue(c.email1),
      TextCellValue(c.email2),
      TextCellValue(c.phone1),
      TextCellValue(c.phone2),
      TextCellValue(c.companyName),
      TextCellValue(c.designation),
      TextCellValue(c.website),
      TextCellValue(c.address),
      TextCellValue(c.status),
    ]);
  }

  final bytes = excel.encode();
  return Uint8List.fromList(bytes ?? const <int>[]);
}

String buildOrganizationContactsCsv(Iterable<OrganizationContactItem> items) {
  final buf = StringBuffer();
  buf.writeln(
    [
      'Full name',
      'Email',
      'Phone',
      'Company',
      'Title',
      'Status',
    ].join(','),
  );
  for (final c in items) {
    buf.writeln(
      [
        _escapeCsvField(c.fullName),
        _escapeCsvField(c.email1),
        _escapeCsvField(c.phone1),
        _escapeCsvField(c.companyName),
        _escapeCsvField(c.designation),
        _escapeCsvField(c.status),
      ].join(','),
    );
  }
  return buf.toString();
}

Uint8List buildOrganizationContactsXlsxBytes(
  Iterable<OrganizationContactItem> items,
) {
  final excel = Excel.createExcel();
  final sheet = excel['Contacts'];
  sheet.appendRow(<CellValue>[
    TextCellValue('Full name'),
    TextCellValue('Email'),
    TextCellValue('Phone'),
    TextCellValue('Company'),
    TextCellValue('Title'),
    TextCellValue('Status'),
  ]);

  for (final c in items) {
    sheet.appendRow(<CellValue>[
      TextCellValue(c.fullName),
      TextCellValue(c.email1),
      TextCellValue(c.phone1),
      TextCellValue(c.companyName),
      TextCellValue(c.designation),
      TextCellValue(c.status),
    ]);
  }

  final bytes = excel.encode();
  return Uint8List.fromList(bytes ?? const <int>[]);
}

/// CSV for `GET /events/members` style payloads (event members / invites).
String buildEventMembersCsv(Iterable<EventMemberItem> items) {
  final buf = StringBuffer();
  buf.writeln(
    [
      'role',
      'email',
      'source',
      'status',
      'user_id',
      'full_name',
      'invite_id',
      'joined_at',
      'avatar_url',
      'invited_at',
      'invite_batch_id',
    ].join(','),
  );
  for (final m in items) {
    buf.writeln(
      [
        _escapeCsvField(m.role),
        _escapeCsvField(m.email),
        _escapeCsvField(m.source),
        _escapeCsvField(m.status),
        _escapeCsvField(m.userId.trim().isNotEmpty ? m.userId : null),
        _escapeCsvField(m.fullName),
        _escapeCsvField(m.inviteId),
        _escapeCsvField(m.joinedAt),
        _escapeCsvField(m.avatarUrl),
        _escapeCsvField(m.invitedAt),
        _escapeCsvField(m.inviteBatchId),
      ].join(','),
    );
  }
  return buf.toString();
}

/// Result of parsing `POST /contacts/by-event/export` (or similar) HTTP response.
class ParsedContactsExport {
  const ParsedContactsExport({
    this.csv,
    this.suggestedFileName,
    this.errorMessage,
  });

  final String? csv;
  final String? suggestedFileName;
  final String? errorMessage;

  bool get isSuccess => csv != null && csv!.trim().isNotEmpty;
}

String? _headerCi(Map<String, String> headers, String name) {
  final lower = name.toLowerCase();
  for (final e in headers.entries) {
    if (e.key.toLowerCase() == lower) return e.value;
  }
  return null;
}

String? _filenameFromContentDisposition(String? value) {
  if (value == null || value.isEmpty) return null;
  final star = RegExp(r"filename\*\s*=\s*[^']*''([^;]+)", caseSensitive: false);
  final mStar = star.firstMatch(value);
  if (mStar != null) {
    try {
      return Uri.decodeComponent(mStar.group(1)!.trim());
    } catch (_) {
      return mStar.group(1)!.trim();
    }
  }
  final plain = RegExp(r'filename\s*=\s*"([^"]+)"', caseSensitive: false);
  final m1 = plain.firstMatch(value);
  if (m1 != null) return m1.group(1)!.trim();
  final plain2 = RegExp(r'filename\s*=\s*([^;\s]+)', caseSensitive: false);
  final m2 = plain2.firstMatch(value);
  if (m2 != null) return m2.group(1)!.trim().replaceAll('"', '');
  return null;
}

String? _contactsListToEventContactsCsv(List<dynamic> list) {
  if (list.isEmpty) return buildEventContactsCsv(const []);
  final items = <EventContactItem>[];
  for (final e in list) {
    if (e is Map<String, dynamic>) {
      items.add(EventContactItem.fromJson(e));
    } else if (e is Map) {
      items.add(EventContactItem.fromJson(Map<String, dynamic>.from(e)));
    } else {
      return null;
    }
  }
  return buildEventContactsCsv(items);
}

String? _contactsListToOrganizationContactsCsv(List<dynamic> list) {
  if (list.isEmpty) return buildOrganizationContactsCsv(const []);
  final items = <OrganizationContactItem>[];
  for (final e in list) {
    if (e is Map<String, dynamic>) {
      items.add(OrganizationContactItem.fromJson(e));
    } else if (e is Map) {
      items.add(OrganizationContactItem.fromJson(Map<String, dynamic>.from(e)));
    } else {
      return null;
    }
  }
  return buildOrganizationContactsCsv(items);
}

String? _extractCsvFromJson(dynamic decoded) {
  if (decoded is String) {
    final t = decoded.trim();
    if (t.isEmpty) return null;
    if (t.startsWith('{') || t.startsWith('[')) {
      try {
        return _extractCsvFromJson(json.decode(t));
      } catch (_) {
        return decoded;
      }
    }
    return decoded;
  }
  if (decoded is List) {
    return _contactsListToEventContactsCsv(decoded) ??
        _contactsListToOrganizationContactsCsv(decoded);
  }
  if (decoded is! Map) return null;
  final map = Map<String, dynamic>.from(decoded);

  for (final key in <String>[
    'csv',
    'content',
    'file_content',
    'body',
    'file',
    'export',
    'text',
    'download',
  ]) {
    final v = map[key];
    if (v is String && v.trim().isNotEmpty) {
      final nested = _extractCsvFromJson(v);
      if (nested != null) return nested;
    }
  }

  final data = map['data'];
  if (data is String && data.trim().isNotEmpty) {
    final nested = _extractCsvFromJson(data);
    if (nested != null) return nested;
  }
  if (data is List) {
    final csv =
        _contactsListToEventContactsCsv(data) ??
        _contactsListToOrganizationContactsCsv(data);
    if (csv != null) return csv;
  }
  if (data is Map) {
    final nested = _extractCsvFromJson(data);
    if (nested != null) return nested;
  }

  for (final key in <String>['response', 'payload', 'result']) {
    final inner = map[key];
    if (inner != null) {
      final nested = _extractCsvFromJson(inner);
      if (nested != null) return nested;
    }
  }

  return null;
}

String _errorMessageFromJsonBody(String bodyText) {
  final trimmed = bodyText.trim();
  if (trimmed.isEmpty) return 'Could not export contacts';
  try {
    final decoded = json.decode(trimmed);
    if (decoded is Map) {
      final m = Map<String, dynamic>.from(decoded);
      for (final key in <String>['message', 'error', 'detail']) {
        final v = m[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      final data = m['data'];
      if (data is Map) {
        final dm = Map<String, dynamic>.from(data);
        final v = dm['message'] ?? dm['error'];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    }
  } catch (_) {}
  return trimmed.length > 200 ? 'Could not export contacts' : trimmed;
}

/// Parses CSV export HTTP response: raw `text/csv` body or JSON wrapping CSV text.
ParsedContactsExport parseContactsExportHttpResponse({
  required int statusCode,
  required String bodyText,
  required Map<String, String> headers,
}) {
  if (statusCode == 401) {
    return const ParsedContactsExport(errorMessage: 'Session expired');
  }
  if (statusCode != 200 && statusCode != 201) {
    return ParsedContactsExport(
      errorMessage: _errorMessageFromJsonBody(bodyText),
    );
  }

  final contentType = _headerCi(headers, 'Content-Type') ?? '';
  final ct = contentType.toLowerCase();
  final filename = _filenameFromContentDisposition(
    _headerCi(headers, 'Content-Disposition'),
  );
  final isCsvMime =
      ct.contains('csv') ||
      ct.contains('text/plain') ||
      (ct.contains('octet-stream') &&
          (filename?.toLowerCase().endsWith('.csv') ?? false));

  final trimmed = bodyText.trim();
  if (trimmed.isEmpty) {
    return const ParsedContactsExport(errorMessage: 'No contacts to export');
  }

  if (isCsvMime && !trimmed.startsWith('{')) {
    return ParsedContactsExport(csv: bodyText, suggestedFileName: filename);
  }

  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
    try {
      final decoded = json.decode(trimmed);
      if (decoded is Map) {
        final m = Map<String, dynamic>.from(decoded);
        final sc = m['statusCode'];
        if (sc != null && sc.toString() != '200' && sc.toString() != '201') {
          return ParsedContactsExport(
            errorMessage: _errorMessageFromJsonBody(bodyText),
          );
        }
        if (m['success'] == false) {
          return ParsedContactsExport(
            errorMessage: _errorMessageFromJsonBody(bodyText),
          );
        }
        if (m['ok'] == false) {
          return ParsedContactsExport(
            errorMessage: _errorMessageFromJsonBody(bodyText),
          );
        }
      }
      final csv = _extractCsvFromJson(decoded);
      if (csv != null && csv.trim().isNotEmpty) {
        return ParsedContactsExport(csv: csv, suggestedFileName: filename);
      }
      if (decoded is Map) {
        final m = Map<String, dynamic>.from(decoded);
        if (m['ok'] == true) {
          return const ParsedContactsExport(
            errorMessage: 'No contacts to export',
          );
        }
      }
      return const ParsedContactsExport(
        errorMessage: 'Could not read export file from server',
      );
    } catch (_) {
      // Treat as raw CSV below
    }
  }

  if (trimmed.startsWith('BEGIN:VCARD')) {
    return ParsedContactsExport(
      errorMessage: 'Unexpected vCard response; expected CSV',
    );
  }

  return ParsedContactsExport(csv: bodyText, suggestedFileName: filename);
}

/// Subfolder under **public** Download (Android) or app storage (fallback / iOS).
const String appCsvExportFolderName = 'JustCards';

const MethodChannel _androidPublicDownloadsChannel = MethodChannel(
  'com.forudyog.justcards/downloads',
);

Future<Directory> _ensureJustcardsExportFolder(Directory parent) async {
  final folder = Directory(p.join(parent.path, appCsvExportFolderName));
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }
  return folder;
}

/// iOS / desktop / Android fallback: scoped Downloads or app Documents.
Future<(Directory dir, String locationLabel)>
_exportTargetDirectoryFallback() async {
  try {
    final downloads = await getDownloadsDirectory();
    if (downloads != null) {
      try {
        if (!await downloads.exists()) {
          await downloads.create(recursive: true);
        }
      } catch (_) {}
      final folder = await _ensureJustcardsExportFolder(downloads);
      return (folder, 'Downloads/$appCsvExportFolderName');
    }
  } catch (_) {}
  final doc = await getApplicationDocumentsDirectory();
  final folder = await _ensureJustcardsExportFolder(doc);
  return (folder, 'Documents/$appCsvExportFolderName');
}

/// Android: **My Files → Download → JustCards** via MediaStore (API 29+) or public Download dir.
Future<String?> _saveBytesAndroidPublicDownload({
  required Uint8List bytes,
  required String initialFileName,
  required String mimeType,
}) async {
  if (!Platform.isAndroid) return null;

  final ext = p.extension(initialFileName);
  final stem =
      ext.isEmpty
          ? initialFileName
          : initialFileName.substring(0, initialFileName.length - ext.length);
  var name = initialFileName;
  var i = 1;
  for (var attempt = 0; attempt < 80; attempt++) {
    try {
      final displayPath = await _androidPublicDownloadsChannel
          .invokeMethod<String>('saveFileToDownloadFolder', <String, dynamic>{
            'folderName': appCsvExportFolderName,
            'fileName': name,
            'bytes': bytes,
            'mimeType': mimeType,
          });
      if (displayPath != null && displayPath.isNotEmpty) {
        return displayPath;
      }
    } on PlatformException catch (_) {
      // try next filename (e.g. duplicate)
    } catch (_) {
      return null;
    }
    name = '${stem}_$i$ext';
    i++;
  }
  return null;
}

/// Writes CSV into **Download/JustCards** on Android (visible in My Files), or Documents/JustCards elsewhere.
Future<void> saveContactsCsvToDevice({
  required String csv,
  required String fileName,
}) async {
  try {
    final base = fileName.trim().replaceAll(RegExp(r'[/\\]'), '_');
    var name = base.toLowerCase().endsWith('.csv') ? base : '$base.csv';

    if (Platform.isAndroid) {
      final publicPath = await _saveBytesAndroidPublicDownload(
        bytes: Uint8List.fromList(csv.codeUnits),
        initialFileName: name,
        mimeType: 'text/csv',
      );
      if (publicPath != null) {
        await ToastService.success('Saved to My Files → $publicPath');
        return;
      }
    }

    final (dir, locationLabel) = await _exportTargetDirectoryFallback();
    var path = p.join(dir.path, name);
    var file = File(path);
    var i = 1;
    while (await file.exists()) {
      final stem = name.replaceAll(RegExp(r'\.csv$', caseSensitive: false), '');
      path = p.join(dir.path, '${stem}_$i.csv');
      file = File(path);
      i++;
    }

    await file.writeAsString(csv, flush: true);

    await ToastService.success('Saved to $locationLabel/${p.basename(path)}');
  } catch (_) {
    await ToastService.error('Could not save file');
  }
}

Future<void> saveContactsXlsxToDevice({
  required Uint8List bytes,
  required String fileName,
}) async {
  try {
    if (bytes.isEmpty) {
      await ToastService.error('Could not generate XLSX file');
      return;
    }

    final base = fileName.trim().replaceAll(RegExp(r'[/\\]'), '_');
    var name = base.toLowerCase().endsWith('.xlsx') ? base : '$base.xlsx';

    if (Platform.isAndroid) {
      final publicPath = await _saveBytesAndroidPublicDownload(
        bytes: bytes,
        initialFileName: name,
        mimeType:
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (publicPath != null) {
        await ToastService.success('Saved to My Files → $publicPath');
        return;
      }
    }

    final (dir, locationLabel) = await _exportTargetDirectoryFallback();
    var path = p.join(dir.path, name);
    var file = File(path);
    var i = 1;
    while (await file.exists()) {
      final stem = name.replaceAll(
        RegExp(r'\.xlsx$', caseSensitive: false),
        '',
      );
      path = p.join(dir.path, '${stem}_$i.xlsx');
      file = File(path);
      i++;
    }

    await file.writeAsBytes(bytes, flush: true);

    await ToastService.success('Saved to $locationLabel/${p.basename(path)}');
  } catch (_) {
    await ToastService.error('Could not save file');
  }
}

/// @deprecated Use [saveContactsCsvToDevice] — kept for any stale references.
Future<void> shareContactsCsvFile({
  required String csv,
  required String fileName,
}) => saveContactsCsvToDevice(csv: csv, fileName: fileName);
