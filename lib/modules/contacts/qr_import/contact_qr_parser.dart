import 'dart:convert';

class ContactQrData {
  ContactQrData({
    required this.fullName,
    required this.firstName,
    required this.lastName,
    required this.organization,
    required this.jobTitle,
    required this.phones,
    required this.emails,
    required this.website,
    required this.address,
    required this.note,
    required this.birthday,
    required this.rawText,
    required this.format,
  });

  final String fullName;
  final String firstName;
  final String lastName;
  final String organization;
  final String jobTitle;
  final List<String> phones;
  final List<String> emails;
  final String website;
  final String address;
  final String note;
  final String birthday;
  final String rawText;
  final String format;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'fullName': fullName,
        'firstName': firstName,
        'lastName': lastName,
        'organization': organization,
        'jobTitle': jobTitle,
        'phones': phones,
        'emails': emails,
        'website': website,
        'address': address,
        'note': note,
        'birthday': birthday,
        'rawText': rawText,
        'format': format,
      };
}

class ContactQrParser {
  static String _decodeEscaped(String input) {
    return input
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\N', '\n')
        .replaceAll(r'\,', ',')
        .replaceAll(r'\;', ';');
  }

  static ContactQrData parse(String qrText) {
    final raw = qrText.trim();

    var fullName = '';
    var firstName = '';
    var lastName = '';
    var organization = '';
    var jobTitle = '';
    final phones = <String>[];
    final emails = <String>[];
    var website = '';
    var address = '';
    var note = '';
    var birthday = '';
    final format = 'unknown';

    if (raw.isEmpty) {
      return ContactQrData(
        fullName: fullName,
        firstName: firstName,
        lastName: lastName,
        organization: organization,
        jobTitle: jobTitle,
        phones: phones,
        emails: emails,
        website: website,
        address: address,
        note: note,
        birthday: birthday,
        rawText: raw,
        format: format,
      );
    }

    if (raw.toUpperCase().contains('BEGIN:VCARD')) {
      final lines =
          raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

      var pendingLine = '';
      final unfolded = <String>[];

      for (final line in lines) {
        if (line.startsWith(' ') || line.startsWith('\t')) {
          pendingLine += line.trimLeft();
        } else {
          if (pendingLine.isNotEmpty) unfolded.add(pendingLine);
          pendingLine = line;
        }
      }
      if (pendingLine.isNotEmpty) unfolded.add(pendingLine);

      for (final line in unfolded) {
        final upper = line.toUpperCase();
        final colonIndex = line.indexOf(':');
        if (colonIndex == -1) continue;

        final value = _decodeEscaped(line.substring(colonIndex + 1).trim());

        if (upper.startsWith('FN:')) {
          fullName = value;
        } else if (upper.startsWith('N:')) {
          final parts = value.split(';');
          lastName = parts.isNotEmpty ? parts[0].trim() : '';
          firstName = parts.length > 1 ? parts[1].trim() : '';
          if (fullName.isEmpty) {
            fullName = '$firstName $lastName'.trim();
          }
        } else if (upper.startsWith('ORG')) {
          organization = value;
        } else if (upper.startsWith('TITLE')) {
          jobTitle = value;
        } else if (upper.startsWith('TEL')) {
          if (value.isNotEmpty) phones.add(value);
        } else if (upper.startsWith('EMAIL')) {
          if (value.isNotEmpty) emails.add(value);
        } else if (upper.startsWith('URL')) {
          website = value;
        } else if (upper.startsWith('ADR')) {
          address =
              value.split(';').where((e) => e.trim().isNotEmpty).join(', ');
        } else if (upper.startsWith('NOTE')) {
          note = value;
        } else if (upper.startsWith('BDAY')) {
          birthday = value;
        }
      }

      return ContactQrData(
        fullName: fullName,
        firstName: firstName,
        lastName: lastName,
        organization: organization,
        jobTitle: jobTitle,
        phones: phones,
        emails: emails,
        website: website,
        address: address,
        note: note,
        birthday: birthday,
        rawText: raw,
        format: 'vcard',
      );
    }

    if (raw.toUpperCase().startsWith('MECARD:')) {
      final body = raw.substring(7);
      final items = body.split(';');

      for (final item in items) {
        if (!item.contains(':')) continue;
        final idx = item.indexOf(':');
        final key = item.substring(0, idx).toUpperCase().trim();
        final value = item.substring(idx + 1).trim();

        switch (key) {
          case 'N':
            fullName = value.replaceAll(',', ' ').trim();
            final parts = fullName
                .split(RegExp(r'\s+'))
                .where((p) => p.trim().isNotEmpty)
                .toList();
            firstName = parts.isNotEmpty ? parts.first.trim() : '';
            lastName =
                parts.length > 1 ? parts.sublist(1).join(' ').trim() : '';
            break;
          case 'TEL':
            if (value.isNotEmpty) phones.add(value);
            break;
          case 'EMAIL':
            if (value.isNotEmpty) emails.add(value);
            break;
          case 'ORG':
            organization = value;
            break;
          case 'TITLE':
            jobTitle = value;
            break;
          case 'URL':
            website = value;
            break;
          case 'ADR':
            address = value;
            break;
          case 'NOTE':
            note = value;
            break;
        }
      }

      return ContactQrData(
        fullName: fullName,
        firstName: firstName,
        lastName: lastName,
        organization: organization,
        jobTitle: jobTitle,
        phones: phones,
        emails: emails,
        website: website,
        address: address,
        note: note,
        birthday: birthday,
        rawText: raw,
        format: 'mecard',
      );
    }

    final lines = raw
        .split(RegExp(r'[\n|]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isNotEmpty) {
      fullName = lines.first;
    }

    for (final line in lines) {
      if (RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(line)) {
        emails.add(line);
      } else if (RegExp(r'^\+?[0-9()\-\s]{7,}$').hasMatch(line)) {
        phones.add(line);
      } else if (line.startsWith('http://') ||
          line.startsWith('https://') ||
          line.startsWith('www.')) {
        website = line;
      }
    }

    if (firstName.isEmpty && lastName.isEmpty && fullName.isNotEmpty) {
      final parts = fullName
          .split(RegExp(r'\s+'))
          .where((p) => p.trim().isNotEmpty)
          .toList();
      firstName = parts.isNotEmpty ? parts.first.trim() : '';
      lastName = parts.length > 1 ? parts.sublist(1).join(' ').trim() : '';
    }

    return ContactQrData(
      fullName: fullName,
      firstName: firstName,
      lastName: lastName,
      organization: organization,
      jobTitle: jobTitle,
      phones: phones,
      emails: emails,
      website: website,
      address: address,
      note: note,
      birthday: birthday,
      rawText: raw,
      format: 'plain_text',
    );
  }

  static String parseToJson(String qrText) => jsonEncode(parse(qrText).toMap());
}
