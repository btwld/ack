import 'dart:ui' show Locale;

import 'package:ack/ack.dart';

const _localePattern = r'^[a-z]{2,3}(?:-[A-Z][a-z]{3})?(?:-[A-Z]{2}|\d{3})?$';

/// Codec for [Locale] using BCP-47 language tags.
///
/// Supports language-only tags (`"en"`), language-region tags (`"en-US"`),
/// and language-script-region tags (`"zh-Hans-CN"`). Encoding delegates to
/// [Locale.toLanguageTag].
final localeCodec = Ack.codec<String, String, Locale>(
  input: Ack.string().matches(_localePattern),
  decode: _decodeLocale,
  encode: (value) => value.toLanguageTag(),
);

Locale _decodeLocale(String value) {
  final parts = value.split('-');
  final languageCode = parts.first;
  String? scriptCode;
  String? countryCode;

  for (final part in parts.skip(1)) {
    if (part.length == 4) {
      scriptCode = part;
    } else {
      countryCode = part;
    }
  }

  return Locale.fromSubtags(
    languageCode: languageCode,
    scriptCode: scriptCode,
    countryCode: countryCode,
  );
}
