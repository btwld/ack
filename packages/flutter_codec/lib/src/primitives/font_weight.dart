import 'dart:ui' show FontWeight;

import 'package:ack/ack.dart';

/// Named [FontWeight] values encoded as canonical `wNNN` string aliases.
enum _FontWeight { w100, w200, w300, w400, w500, w600, w700, w800, w900 }

/// Codec for [FontWeight].
///
/// Accepts `"w100"` through `"w900"` plus the conventional aliases
/// `"normal"` and `"bold"`. Encoding canonicalizes aliases back to the
/// numeric `wNNN` form.
final fontWeightCodec = Ack.codec<Object, Object, FontWeight>(
  input: Ack.anyOf([
    Ack.literal('normal'),
    Ack.literal('bold'),
    Ack.enumCodec(_FontWeight.values),
  ]),
  decode: _decodeFontWeight,
  encode: _encodeFontWeight,
);

FontWeight _decodeFontWeight(Object value) {
  if (value == 'normal') return FontWeight.normal;
  if (value == 'bold') return FontWeight.bold;

  return switch (value as _FontWeight) {
    _FontWeight.w100 => FontWeight.w100,
    _FontWeight.w200 => FontWeight.w200,
    _FontWeight.w300 => FontWeight.w300,
    _FontWeight.w400 => FontWeight.w400,
    _FontWeight.w500 => FontWeight.w500,
    _FontWeight.w600 => FontWeight.w600,
    _FontWeight.w700 => FontWeight.w700,
    _FontWeight.w800 => FontWeight.w800,
    _FontWeight.w900 => FontWeight.w900,
  };
}

Object _encodeFontWeight(FontWeight value) {
  return switch (value.value) {
    100 => _FontWeight.w100,
    200 => _FontWeight.w200,
    300 => _FontWeight.w300,
    400 => _FontWeight.w400,
    500 => _FontWeight.w500,
    600 => _FontWeight.w600,
    700 => _FontWeight.w700,
    800 => _FontWeight.w800,
    900 => _FontWeight.w900,
    _ => throw ArgumentError.value(
      value,
      'value',
      'Expected a FontWeight value from w100 through w900.',
    ),
  };
}
