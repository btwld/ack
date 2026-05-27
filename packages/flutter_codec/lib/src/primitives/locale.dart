import 'dart:ui' show Locale;

import 'package:ack/ack.dart';

// BCP-47 subset: required language (2-3 lowercase), optional script
// (4-character title case), optional region (2 uppercase letters or 3 digits).
// Capture groups extract each subtag for the inline decoder on [localeCodec];
// they don't affect validation behavior.
const _localePattern =
    r'^([a-z]{2,3})(?:-([A-Z][a-z]{3}))?(?:-([A-Z]{2}|\d{3}))?$';
final _localeRegex = RegExp(_localePattern);

/// Codec for [Locale] using BCP-47 language tags.
///
/// Supports language-only tags (`"en"`), language-region tags (`"en-US"`),
/// and language-script-region tags (`"zh-Hans-CN"`). Encoding delegates to
/// [Locale.toLanguageTag].
final localeCodec = Ack.codec<String, String, Locale>(
  input: Ack.string().matches(_localePattern),
  decode: (value) {
    final match = _localeRegex.firstMatch(value)!;
    return Locale.fromSubtags(
      languageCode: match.group(1)!,
      scriptCode: match.group(2),
      countryCode: match.group(3),
    );
  },
  encode: (value) => value.toLanguageTag(),
);
