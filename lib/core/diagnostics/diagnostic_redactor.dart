/// The one place that decides what must never reach a log line.
///
/// Diagnostics are exported and shared, so a secret that gets into an event is a secret
/// that gets into a bug report. Redaction happens at the point of recording rather than
/// at render time: an event that was persisted with a token in it is already leaked, and
/// no amount of careful UI can un-leak it.
///
/// This is a safety net, not a licence. Callers still must not pass credentials into
/// diagnostics; the rules below only catch what slips through.
class DiagnosticRedactor {
  const DiagnosticRedactor._();

  static const String placeholder = '[REDACTED]';

  /// Metadata keys whose value is dropped outright. Matched as a substring of the
  /// lower-cased key, so `authHeader`, `x-auth`, and `AUTHORIZATION` all match `auth`.
  static const List<String> _sensitiveKeyParts = <String>[
    'password',
    'passwd',
    'secret',
    'token',
    'auth',
    'cookie',
    'credential',
    'bearer',
    'apikey',
    'api_key',
    'privatekey',
    'private_key',
    'session',
    'signature',
    'card',
    'cvv',
    'iban',
    'ssn',
  ];

  /// `Bearer <blob>` and `Authorization: <blob>` in free text.
  static final RegExp _bearer = RegExp(
    r'\b(bearer|authorization\s*[:=])\s*[A-Za-z0-9._\-+/=]{8,}',
    caseSensitive: false,
  );

  /// `key=value` shapes inside otherwise useful messages, e.g. an engine error that
  /// echoes back a URL query.
  static final RegExp _inlineAssignment = RegExp(
    r'(?<key>${keys})(?<sep>["\x27]?\s*[:=]\s*["\x27]?)(?<value>[^\s,;&"\x27}\]]{4,})'
        .replaceFirst(r'${keys}', _sensitiveKeyParts.join('|')),
    caseSensitive: false,
  );

  /// A JWT. Matched on shape because the interesting ones never announce themselves.
  static final RegExp _jwt = RegExp(r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{4,}');

  /// 13-19 digits, optionally grouped: a payment card number.
  static final RegExp _cardNumber = RegExp(r'\b(?:\d[ -]?){13,19}\b');

  static final RegExp _pemBlock = RegExp(
    r'-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----',
  );

  /// Longest first, so `/storage/emulated/0` is labelled before `/storage`.
  static const List<(String, String)> _pathRoots = <(String, String)>[
    ('/storage/emulated/0', '<shared>'),
    ('/sdcard', '<shared>'),
    ('/data/user/0', '<app-data>'),
    ('/data/data', '<app-data>'),
    ('/data/media/0', '<shared>'),
    ('/storage', '<volume>'),
  ];

  static bool isSensitiveKey(String key) {
    final String needle = key.toLowerCase();
    return _sensitiveKeyParts.any(needle.contains);
  }

  /// Cheap test for "is it even worth running the patterns".
  ///
  /// Redaction runs on every recorded message, and the patterns below are not free.
  /// The overwhelming majority of Duplika's log lines are prose plus a package name,
  /// which cannot contain any of these shapes, so a single lower-case scan lets them
  /// skip the regex work entirely.
  static bool _mightContainSecret(String value) {
    final String lower = value.toLowerCase();
    if (lower.contains('-----begin') || lower.contains('eyj')) {
      return true;
    }
    for (final String part in _sensitiveKeyParts) {
      if (lower.contains(part)) {
        return true;
      }
    }
    // A card number needs at least 13 digits; anything shorter cannot match.
    int digits = 0;
    for (int index = 0; index < value.length; index++) {
      final int unit = value.codeUnitAt(index);
      if (unit >= 0x30 && unit <= 0x39) {
        if (++digits >= 13) {
          return true;
        }
      } else if (unit != 0x20 && unit != 0x2D) {
        digits = 0;
      }
    }
    return false;
  }

  /// Free text: messages, details, exception messages.
  static String redactText(String value) {
    if (value.isEmpty || !_mightContainSecret(value)) {
      return value;
    }
    return value
        .replaceAll(_pemBlock, placeholder)
        .replaceAll(_jwt, placeholder)
        .replaceAll(_bearer, placeholder)
        .replaceAllMapped(
          _inlineAssignment,
          (Match match) => match is RegExpMatch
              ? '${match.namedGroup('key')}${match.namedGroup('sep')}$placeholder'
              : placeholder,
        )
        .replaceAllMapped(_cardNumber, (Match match) {
          // Digit runs are also version codes, byte counts and timestamps. Only treat
          // one as a card number when it passes the Luhn check, otherwise a log line
          // reading "installed 1234567890123 bytes" would come back redacted.
          final String digits = match[0]!.replaceAll(RegExp(r'[ -]'), '');
          return _passesLuhn(digits) ? placeholder : match[0]!;
        });
  }

  static Map<String, String> redactMetadata(Map<String, String> metadata) {
    if (metadata.isEmpty) {
      return const <String, String>{};
    }
    return metadata.map(
      (String key, String value) => MapEntry<String, String>(
        key,
        isSensitiveKey(key) ? placeholder : redactText(value),
      ),
    );
  }

  /// Shortens a filesystem path to something safe to show and still useful.
  ///
  /// The filename is kept, because "which APK failed" is exactly the question an import
  /// diagnostic has to answer. Everything above it collapses to a root label, so a
  /// shared report does not carry the user's folder structure.
  static String sanitizePath(String path) {
    if (path.isEmpty) {
      return path;
    }

    for (final (String prefix, String label) in _pathRoots) {
      if (path.startsWith(prefix)) {
        final String remainder = path.substring(prefix.length);
        final int lastSlash = remainder.lastIndexOf('/');
        if (lastSlash <= 0) {
          return '$label$remainder';
        }
        return '$label/…/${remainder.substring(lastSlash + 1)}';
      }
    }

    // An unrecognised root is more likely to be an OEM volume than anything private,
    // but the parent directories still get collapsed.
    final int lastSlash = path.lastIndexOf('/');
    return lastSlash <= 0 ? path : '…/${path.substring(lastSlash + 1)}';
  }

  static List<String> sanitizePaths(Iterable<String> paths) =>
      paths.map(sanitizePath).toList(growable: false);

  static bool _passesLuhn(String digits) {
    if (digits.length < 13 || digits.length > 19) {
      return false;
    }
    int sum = 0;
    bool doubleIt = false;
    for (int index = digits.length - 1; index >= 0; index--) {
      int digit = digits.codeUnitAt(index) - 0x30;
      if (digit < 0 || digit > 9) {
        return false;
      }
      if (doubleIt) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      sum += digit;
      doubleIt = !doubleIt;
    }
    return sum % 10 == 0;
  }
}
