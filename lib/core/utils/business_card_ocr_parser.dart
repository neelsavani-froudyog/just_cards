/// Parses ML Kit OCR output (often like a business card) into form fields.
///
/// Example:
/// ```
/// John Doe
/// Software Engineer
/// ABC Pvt Ltd
/// Mobile: +91 9876543210
/// Email: john@example.com
/// www.abc.com
/// Ahmedabad, India
/// ```
class ParsedBusinessCardFields {
  const ParsedBusinessCardFields({
    required this.fullName,
    required this.jobTitle,
    required this.company,
    required this.primaryPhone,
    required this.secondaryPhone,
    required this.email,
  });

  final String fullName;
  final String jobTitle;
  final String company;
  final String primaryPhone;
  final String secondaryPhone;
  final String email;

  static const empty = ParsedBusinessCardFields(
    fullName: '',
    jobTitle: '',
    company: '',
    primaryPhone: '',
    secondaryPhone: '',
    email: '',
  );
}

class BusinessCardOcrParser {
  BusinessCardOcrParser._();

  static final RegExp _emailRe = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );

  static final RegExp _labeledPhone = RegExp(
    r'^(?:mobile|mob|tel|phone|office|ph|cell|gsm)\s*[:.]?\s*(.+)$',
    caseSensitive: false,
  );

  static final RegExp _phoneDigits = RegExp(
    r'(?:\+\d{1,3}[\s\-]?)?(?:\(?\d{2,5}\)?[\s\-]?)?[\d\-\s]{6,22}\d',
  );

  static final RegExp _companyHints = RegExp(
    r'\b(pvt|ltd|llc|inc|corp|limited|solutions|technologies|group|holdings|enterprises)\b',
    caseSensitive: false,
  );

  static List<String> _lines(String raw) {
    return raw
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  static String? _firstEmail(String text) {
    final m = _emailRe.firstMatch(text);
    return m?.group(0);
  }

  static List<String> _phonesFromLine(String line) {
    final target = _labeledPhone.firstMatch(line)?.group(1)?.trim() ?? line;
    final out = <String>[];
    for (final m in _phoneDigits.allMatches(target)) {
      var p = m.group(0);
      if (p == null) continue;
      p = p.replaceAll(RegExp(r'\s+'), ' ').trim();
      final digits = p.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 8) {
        out.add(p);
      }
    }
    return out;
  }

  static bool _isUrlOnlyLine(String line) {
    final t = line.toLowerCase().trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return true;
    if (t.startsWith('www.')) return true;
    return RegExp(r'^[a-z0-9.-]+\.[a-z]{2,}(/|$)', caseSensitive: false).hasMatch(t);
  }

  static bool _looksLikeAddress(String line) {
    return line.contains(',') &&
        (line.length > 8) &&
        ! _emailRe.hasMatch(line) &&
        _phonesFromLine(line).isEmpty;
  }

  /// Heuristic parse; works best when OCR preserves line breaks like the example.
  static ParsedBusinessCardFields parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return ParsedBusinessCardFields.empty;

    final email = _firstEmail(text) ?? '';

    final lines = _lines(text);
    final phones = <String>[];
    final contentLines = <String>[];

    for (final line in lines) {
      if (_isUrlOnlyLine(line)) {
        continue;
      }
      final lineEmail = _firstEmail(line);
      if (lineEmail != null && line.replaceAll(RegExp(r'\s'), '') == lineEmail.replaceAll(RegExp(r'\s'), '')) {
        continue;
      }
      if (line.toLowerCase().startsWith('e-mail') ||
          line.toLowerCase().startsWith('email')) {
        final em = _firstEmail(line);
        if (em != null) {
          continue;
        }
      }

      final fromPhones = _phonesFromLine(line);
      if (fromPhones.isNotEmpty) {
        phones.addAll(fromPhones);
        continue;
      }

      var keep = line;
      if (lineEmail != null) {
        keep = line.replaceAll(_emailRe, '').replaceAll(RegExp(r'\s+'), ' ').trim();
        if (keep.isEmpty) continue;
      }
      contentLines.add(keep);
    }

    final dedupedPhones = <String>[];
    for (final p in phones) {
      if (!dedupedPhones.any((e) => e.replaceAll(RegExp(r'\D'), '') == p.replaceAll(RegExp(r'\D'), ''))) {
        dedupedPhones.add(p);
      }
    }

    String primary = '';
    String secondary = '';
    if (dedupedPhones.isNotEmpty) {
      primary = dedupedPhones.first;
      if (dedupedPhones.length > 1) {
        secondary = dedupedPhones[1];
      }
    }

    String name = '';
    String title = '';
    String company = '';

    if (contentLines.isEmpty) {
      return ParsedBusinessCardFields(
        fullName: name,
        jobTitle: title,
        company: company,
        primaryPhone: primary,
        secondaryPhone: secondary,
        email: email,
      );
    }

    var work = List<String>.from(contentLines);
    if (work.length >= 2 && _looksLikeAddress(work.last)) {
      work.removeLast();
    }

    if (work.length == 1) {
      name = work.first;
    } else if (work.length == 2) {
      name = work[0];
      if (_companyHints.hasMatch(work[1])) {
        company = work[1];
      } else {
        title = work[1];
      }
    } else if (work.length >= 3) {
      name = work.first;
      title = work[1];
      company = work[2];
      if (work.length > 3) {
        final rest = work.sublist(3).join(' · ');
        if (rest.isNotEmpty) {
          company = '$company · $rest';
        }
      }
    }

    return ParsedBusinessCardFields(
      fullName: name,
      jobTitle: title,
      company: company,
      primaryPhone: primary,
      secondaryPhone: secondary,
      email: email,
    );
  }
}
