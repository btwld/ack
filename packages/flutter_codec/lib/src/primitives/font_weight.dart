import 'dart:ui' show FontWeight;

import 'package:ack/ack.dart';

// String aliases accepted for FontWeight.
//
// The first nine entries (w100..w900) are deliberately parallel to
// FontWeight.values so encoding can map between the two by index. The
// trailing `normal` and `bold` are accept-only aliases for w400/w700 and are
// never emitted on encode.
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
/// Accepts `"w100"` through `"w900"` plus the conventional aliases `"normal"`
/// and `"bold"`. Encoding canonicalizes every value to the numeric `wNNN`
/// form, since [FontWeight.normal] is the same instance as [FontWeight.w400]
/// (and likewise for [FontWeight.bold] / [FontWeight.w700]).
final fontWeightCodec = Ack.enumCodec(_FontWeight.values).codec<FontWeight>(
  decode: (value) => switch (value) {
    _FontWeight.normal => FontWeight.normal,
    _FontWeight.bold => FontWeight.bold,
    _ => FontWeight.values[value.index],
  },
  encode: (value) {
    final index = FontWeight.values.indexOf(value);
    if (index < 0) {
      throw ArgumentError.value(
        value,
        'value',
        'Expected a FontWeight from w100 through w900.',
      );
    }
    return _FontWeight.values[index];
  },
);
