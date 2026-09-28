part of '../schemas/schema.dart';

const _jsonSchemaFormats = {
  'date',
  'time',
  'date-time',
  'duration',
  'email',
  'idn-email',
  'hostname',
  'idn-hostname',
  'ipv4',
  'ipv6',
  'uri',
  'uri-reference',
  'iri',
  'iri-reference',
  'uri-template',
  'json-pointer',
  'relative-json-pointer',
  'regex',
  'uuid',
};

bool _isSupportedJsonSchemaFormat(String format) =>
    _jsonSchemaFormats.contains(format);

bool _isValidJsonSchemaFormat(String format, String value) => switch (format) {
  'date' => _isFullDate(value),
  'time' => _isFullTime(value),
  'date-time' => _isDateTime(value),
  'duration' => _isDuration(value),
  'email' => _isEmail(value, international: false),
  'idn-email' => _isEmail(value, international: true),
  'hostname' => _isHostname(value, international: false),
  'idn-hostname' => _isHostname(value, international: true),
  'ipv4' => _isIpv4(value),
  'ipv6' => _isIpv6(value),
  'uri' => _isUri(value, absolute: true, international: false),
  'uri-reference' => _isUri(value, absolute: false, international: false),
  'iri' => _isUri(value, absolute: true, international: true),
  'iri-reference' => _isUri(value, absolute: false, international: true),
  'uri-template' => _isUriTemplate(value),
  'json-pointer' => _isJsonPointer(value),
  'relative-json-pointer' => _isRelativeJsonPointer(value),
  'regex' => _isRegex(value),
  'uuid' => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value),
  _ => false,
};

bool _isFullDate(String value) {
  final match = RegExp(r'^([0-9]{4})-([0-9]{2})-([0-9]{2})$').firstMatch(value);
  if (match == null) return false;
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  if (year == 0 || month < 1 || month > 12 || day < 1) return false;
  final leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  final days = [31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  return day <= days[month - 1];
}

final _fullTimePattern = RegExp(
  r'^([0-9]{2}):([0-9]{2}):([0-9]{2})(?:\.([0-9]+))?([Zz]|([+-])([0-9]{2}):([0-9]{2}))$',
);

bool _isFullTime(String value) {
  final match = _fullTimePattern.firstMatch(value);
  if (match == null) return false;
  final hour = int.parse(match[1]!);
  final minute = int.parse(match[2]!);
  final second = int.parse(match[3]!);
  final offsetHour = match[7] == null ? 0 : int.parse(match[7]!);
  final offsetMinute = match[8] == null ? 0 : int.parse(match[8]!);
  if (hour > 23 ||
      minute > 59 ||
      second > 60 ||
      offsetHour > 23 ||
      offsetMinute > 59) {
    return false;
  }
  if (second == 60) {
    final signedOffset =
        (offsetHour * 60 + offsetMinute) * (match[6] == '-' ? -1 : 1);
    final utcMinute = (hour * 60 + minute - signedOffset) % (24 * 60);
    if (utcMinute != 23 * 60 + 59) return false;
  }
  return true;
}

bool _isDateTime(String value) {
  if (value.length < 12 || (value[10] != 'T' && value[10] != 't')) {
    return false;
  }
  return _isFullDate(value.substring(0, 10)) &&
      _isFullTime(value.substring(11));
}

bool _isDuration(String value) {
  if (RegExp(r'^P[0-9]+W$').hasMatch(value)) return true;
  final match = RegExp(
    r'^P(?:([0-9]+)Y)?(?:([0-9]+)M)?(?:([0-9]+)D)?(?:T(?:([0-9]+)H)?(?:([0-9]+)M)?(?:([0-9]+)S)?)?$',
  ).firstMatch(value);
  if (match == null) return false;
  final present = [for (var i = 1; i <= 6; i++) match[i] != null];
  if (!present.contains(true)) return false;
  if (value.contains('T') && !present.sublist(3).contains(true)) return false;
  if (present[0] && present[2] && !present[1]) return false;
  if (present[3] && present[5] && !present[4]) return false;
  return true;
}

bool _isIpv4(String value) {
  final parts = value.split('.');
  if (parts.length != 4) return false;
  for (final part in parts) {
    if (!RegExp(r'^(0|[1-9][0-9]{0,2})$').hasMatch(part)) return false;
    if (int.parse(part) > 255) return false;
  }
  return true;
}

bool _isIpv6(String value) {
  // Uri.parseIPv6Address differs across supported Dart SDKs (notably for
  // whitespace and IPv4 tails), so validate the RFC 3986 grammar ourselves.
  if (value.isEmpty || RegExp(r'[^0-9A-Fa-f:.]').hasMatch(value)) {
    return false;
  }
  var address = value;
  var embeddedGroups = 0;
  if (value.contains('.')) {
    final separator = value.lastIndexOf(':');
    if (separator < 0) return false;
    final tail = value.substring(separator + 1);
    if (!_isIpv4(tail)) return false;
    address = value.substring(0, separator);
    if (address.endsWith(':')) address += ':';
    if (address.contains('.')) return false;
    embeddedGroups = 2;
  }
  final compressed = address.contains('::');
  if (compressed) {
    if (address.contains(':::') ||
        address.indexOf('::', address.indexOf('::') + 2) >= 0 ||
        (address.startsWith(':') && !address.startsWith('::')) ||
        (address.endsWith(':') && !address.endsWith('::'))) {
      return false;
    }
  } else if (address.startsWith(':') || address.endsWith(':')) {
    return false;
  }
  final groups = address.split(':').where((group) => group.isNotEmpty).toList();
  if (groups.any((group) => group.length > 4)) return false;
  final expectedGroups = 8 - embeddedGroups;
  return compressed
      ? groups.length < expectedGroups
      : groups.length == expectedGroups;
}

bool _isJsonPointer(String value) {
  if (value.isEmpty) return true;
  if (!value.startsWith('/')) return false;
  return !RegExp(r'~(?![01])').hasMatch(value);
}

bool _isRelativeJsonPointer(String value) {
  final match = RegExp(r'^(0|[1-9][0-9]*)(#|(?:/.*)?)$').firstMatch(value);
  if (match == null) return false;
  final suffix = match[2]!;
  return suffix == '#' || _isJsonPointer(suffix);
}

bool _isRegex(String value) {
  try {
    RegExp(value, unicode: true);
    return true;
  } on FormatException {
    return false;
  }
}

bool _isHostname(String value, {required bool international}) {
  if (!international && value.runes.any((rune) => rune > 127)) return false;
  final mapped = international
      ? unorm
            .nfkc(
              value.replaceAll(RegExp('[。．｡]'), '.').replaceAll('\u200b', ''),
            )
            .toLowerCase()
      : value.toLowerCase();
  if (mapped.isEmpty) return false;
  final asciiLabels = <String>[];
  final unicodeLabels = <String>[];
  for (final rawLabel in mapped.split('.')) {
    if (rawLabel.isEmpty ||
        rawLabel.startsWith('-') ||
        rawLabel.endsWith('-')) {
      return false;
    }
    if (!international && rawLabel.runes.any((rune) => rune > 127)) {
      return false;
    }
    var label = rawLabel;
    if (rawLabel.startsWith('xn--')) {
      try {
        label = punycoder.punycode.decode(rawLabel.substring(4));
      } on FormatException {
        return false;
      }
      if (label.isEmpty || label.runes.every((rune) => rune < 128)) {
        return false;
      }
      label = unorm.nfkc(label).toLowerCase();
      if (punycoder.punycode.encode(label).toLowerCase() !=
          rawLabel.substring(4)) {
        return false;
      }
    } else if (rawLabel.length >= 4 &&
        rawLabel[2] == '-' &&
        rawLabel[3] == '-') {
      return false;
    }
    if (!_isIdnaLabel(label)) return false;
    final ascii = label.runes.every((rune) => rune < 128)
        ? label
        : 'xn--${punycoder.punycode.encode(label).toLowerCase()}';
    if (ascii.length > 63) return false;
    asciiLabels.add(ascii);
    unicodeLabels.add(label);
  }
  if (asciiLabels.join('.').length > 253) return false;
  if (unicodeLabels.any((label) => label.runes.any(_isRtlRune))) {
    for (final label in unicodeLabels) {
      if (label.runes.any(_isRtlRune)) continue;
      if (!RegExp(r'^[a-z]').hasMatch(label)) return false;
    }
  }
  return true;
}

bool _isIdnaLabel(String label) {
  final runes = label.runes.toList();
  if (runes.isEmpty ||
      RegExp(r'^\p{M}', unicode: true).hasMatch(label) ||
      (label.length >= 4 && label[2] == '-' && label[3] == '-') ||
      label.startsWith('-') ||
      label.endsWith('-')) {
    return false;
  }
  var hasArabicIndic = false;
  var hasExtendedArabicIndic = false;
  var hasJapanese = false;
  var hasRtl = false;
  var hasLatin = false;
  var hasEuropeanDigit = false;
  for (var i = 0; i < runes.length; i++) {
    final rune = runes[i];
    if (rune < 128 &&
        !((rune >= 0x61 && rune <= 0x7a) ||
            (rune >= 0x30 && rune <= 0x39) ||
            rune == 0x2d)) {
      return false;
    }
    if (rune >= 128 &&
        !RegExp(
          r'^[\p{L}\p{M}\p{N}]$',
          unicode: true,
        ).hasMatch(String.fromCharCode(rune)) &&
        !const {
          0x00b7,
          0x0375,
          0x05f3,
          0x05f4,
          0x06fd,
          0x06fe,
          0x0f0b,
          0x200c,
          0x200d,
          0x30fb,
        }.contains(rune)) {
      return false;
    }
    if (rune <= 0x20 ||
        (rune >= 0x7f && rune <= 0x9f) ||
        rune == 0x302e ||
        rune == 0x302f ||
        (rune >= 0x3031 && rune <= 0x3035) ||
        rune == 0x303b ||
        rune == 0x0640 ||
        rune == 0x07fa) {
      return false;
    }
    if (rune >= 0x61 && rune <= 0x7a) hasLatin = true;
    if (rune >= 0x30 && rune <= 0x39) hasEuropeanDigit = true;
    if (rune >= 0x0660 && rune <= 0x0669) hasArabicIndic = true;
    if (rune >= 0x06f0 && rune <= 0x06f9) hasExtendedArabicIndic = true;
    if (_isRtlRune(rune)) hasRtl = true;
    if (rune != 0x30fb && _isJapaneseRune(rune)) hasJapanese = true;
    if (rune == 0x00b7 &&
        (i == 0 ||
            i == runes.length - 1 ||
            runes[i - 1] != 0x6c ||
            runes[i + 1] != 0x6c)) {
      return false;
    }
    if (rune == 0x0375 &&
        (i == runes.length - 1 || !_isGreekRune(runes[i + 1]))) {
      return false;
    }
    if ((rune == 0x05f3 || rune == 0x05f4) &&
        (i == 0 || !_isHebrewRune(runes[i - 1]))) {
      return false;
    }
    if ((rune == 0x200c || rune == 0x200d) &&
        (i == 0 || !_isVirama(runes[i - 1]))) {
      if (rune == 0x200d ||
          i == 0 ||
          i == runes.length - 1 ||
          !_isArabicRune(runes[i - 1]) ||
          !_isArabicRune(runes[i + 1])) {
        return false;
      }
    }
  }
  if (hasArabicIndic && hasExtendedArabicIndic) return false;
  if (hasArabicIndic && !hasRtl && !hasLatin) return false;
  if (runes.contains(0x30fb) && !hasJapanese) return false;
  if (hasRtl) {
    if (!_isRtlRune(runes.first) ||
        hasLatin ||
        (hasEuropeanDigit && (hasArabicIndic || hasExtendedArabicIndic))) {
      return false;
    }
  }
  return true;
}

bool _isHebrewRune(int rune) => rune >= 0x0590 && rune <= 0x05ff;
bool _isArabicRune(int rune) =>
    rune >= 0x0600 &&
    rune <= 0x08ff &&
    !(rune >= 0x0660 && rune <= 0x0669) &&
    !(rune >= 0x06f0 && rune <= 0x06f9);
bool _isRtlRune(int rune) => _isHebrewRune(rune) || _isArabicRune(rune);
bool _isGreekRune(int rune) =>
    (rune >= 0x0370 && rune <= 0x03ff) || (rune >= 0x1f00 && rune <= 0x1fff);
bool _isJapaneseRune(int rune) =>
    (rune >= 0x3040 && rune <= 0x30ff) || (rune >= 0x3400 && rune <= 0x9fff);
bool _isVirama(int rune) => const {
  0x094d,
  0x09cd,
  0x0a4d,
  0x0acd,
  0x0b4d,
  0x0bcd,
  0x0c4d,
  0x0ccd,
  0x0d4d,
  0x0dca,
  0x0e3a,
  0x0f84,
  0x1039,
  0x1714,
}.contains(rune);

bool _isEmail(String value, {required bool international}) {
  final match = RegExp(
    r'^("(?:[^"\\]|\\[\s\S])*"|[^@]+)@(.+)$',
  ).firstMatch(value);
  if (match == null) return false;
  final local = match[1]!;
  final domain = match[2]!;
  if (!international && !local.runes.every((rune) => rune < 128)) {
    return false;
  }
  if (local.startsWith('"')) {
    if (!local.endsWith('"')) return false;
    if (RegExp(r'[\u0000-\u001f\u007f]').hasMatch(local)) return false;
  } else {
    final atom = international
        ? RegExp(r'^[^\s@\x00-\x20\x7f(),:;<>\[\]"\\]+$')
        : RegExp(r"^[A-Za-z0-9!#\$%&'*+/=?^_`{|}~.-]+$");
    if (!atom.hasMatch(local) ||
        local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..')) {
      return false;
    }
  }
  if (domain.startsWith('[') && domain.endsWith(']')) {
    final literal = domain.substring(1, domain.length - 1);
    if (literal.toLowerCase().startsWith('ipv6:')) {
      return _isIpv6(literal.substring(5));
    }
    return _isIpv4(literal);
  }
  return _isHostname(domain, international: international);
}

bool _hasValidPercents(String value) {
  for (var i = 0; i < value.length; i++) {
    if (value[i] != '%') continue;
    if (i + 2 >= value.length ||
        !RegExp(r'^[0-9a-fA-F]{2}$').hasMatch(value.substring(i + 1, i + 3))) {
      return false;
    }
    i += 2;
  }
  return true;
}

bool _isUri(
  String value, {
  required bool absolute,
  required bool international,
}) {
  if (!_hasValidPercents(value)) return false;
  if (RegExp(r'[\u0000-\u0020\u007f<>"{}|\\^`]').hasMatch(value)) {
    return false;
  }
  if (!international && value.runes.any((rune) => rune > 127)) return false;
  if (absolute && !RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*:').hasMatch(value)) {
    return false;
  }
  if (!absolute &&
      RegExp(r'^[^/?.#][^/]*:').hasMatch(value) &&
      !RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*:').hasMatch(value)) {
    return false;
  }
  try {
    final firstBracket = value.indexOf('[');
    final lastBracket = value.lastIndexOf(']');
    if (firstBracket >= 0 || lastBracket >= 0) {
      final authorityMarker = value.indexOf('//');
      if (authorityMarker < 0) return false;
      final authorityStart = authorityMarker + 2;
      var authorityEnd = value.length;
      for (final delimiter in ['/', '?', '#']) {
        final next = value.indexOf(delimiter, authorityStart);
        if (next >= 0 && next < authorityEnd) authorityEnd = next;
      }
      if (firstBracket < authorityStart ||
          firstBracket >= authorityEnd ||
          lastBracket < firstBracket ||
          lastBracket >= authorityEnd) {
        return false;
      }
      final literal = value.substring(firstBracket + 1, lastBracket);
      if (!_isIpv6(literal) &&
          !RegExp(
            r"^[vV][0-9A-Fa-f]+\.[A-Za-z0-9._~!$&'()*+,;=:-]+$",
          ).hasMatch(literal)) {
        return false;
      }
    }
    final uri = Uri.parse(value);
    if (absolute && !uri.hasScheme) return false;
    if (uri.path.contains('[') || uri.path.contains(']')) return false;
    if (uri.hasAuthority &&
        uri.host.contains(':') &&
        !value.contains('[${uri.host}]')) {
      return false;
    }
    return true;
  } on FormatException {
    return false;
  }
}

bool _isUriTemplate(String value) {
  var index = 0;
  while (index < value.length) {
    final char = value[index];
    if (char == '}') return false;
    if (char != '{') {
      index++;
      continue;
    }
    final end = value.indexOf('}', index + 1);
    if (end < 0) return false;
    var expression = value.substring(index + 1, end);
    if (expression.isEmpty || expression.contains('{')) return false;
    if ('+#./;?&'.contains(expression[0])) expression = expression.substring(1);
    if (expression.isEmpty) return false;
    for (final variable in expression.split(',')) {
      if (variable.isEmpty) return false;
      final match = RegExp(
        r'^([A-Za-z0-9_]|%[0-9A-Fa-f]{2})+(?:\.(?:[A-Za-z0-9_]|%[0-9A-Fa-f]{2})+)*(?:\*|:[1-9][0-9]{0,3})?$',
      ).firstMatch(variable);
      if (match == null) return false;
    }
    index = end + 1;
  }
  return _hasValidPercents(value.replaceAll(RegExp(r'\{[^{}]*\}'), '')) &&
      !RegExp(r'[\u0000-\u0020\u007f]').hasMatch(value);
}
