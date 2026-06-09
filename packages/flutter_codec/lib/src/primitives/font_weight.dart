import 'dart:ui' show FontWeight;

import 'package:ack/ack.dart';

// Named aliases accepted for [FontWeight].
//
// w100..w900 occupy indices 0..8, so the canonical weight `100 * (index + 1)`
// maps to and from the enum arithmetically. The trailing `normal` and `bold`
// are accept-only aliases for w400/w700 and are never emitted on encode.
enum _FontWeight {
  w100,
  w200,
  w300,
  w400,
  w500,
  w600,
  w700,
  w800,
  w900,
  normal,
  bold,
}

/// Codec for [FontWeight].
///
/// Accepts the named aliases `"w100"` through `"w900"` plus `"normal"` and
/// `"bold"`, and any integer weight in `[1, 1000]` — Flutter's public
/// `const FontWeight(int)` supports arbitrary variable-font weights such as
/// `FontWeight(550)`. Encoding canonicalizes the nine standard weights to
/// their `"wNNN"` alias and emits any other weight as its integer
/// [FontWeight.value].
final fontWeightCodec = Ack.codec<Object, Object, FontWeight>(
  input: Ack.anyOf([
    Ack.enumCodec(_FontWeight.values),
    Ack.integer().min(1).max(1000),
  ]),
  decode: _decodeFontWeight,
  encode: _encodeFontWeight,
);

FontWeight _decodeFontWeight(Object value) {
  if (value is int) return FontWeight(value);

  return switch (value as _FontWeight) {
    _FontWeight.normal => FontWeight.normal,
    _FontWeight.bold => FontWeight.bold,
    final weight => FontWeight(100 * (weight.index + 1)),
  };
}

Object _encodeFontWeight(FontWeight value) {
  final weight = value.value;
  final isCanonical = weight >= 100 && weight <= 900 && weight % 100 == 0;

  return isCanonical ? _FontWeight.values[weight ~/ 100 - 1] : weight;
}
