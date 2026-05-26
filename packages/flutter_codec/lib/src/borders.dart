import 'package:ack/ack.dart';
import 'package:flutter/painting.dart' show BorderSide, BorderStyle, Color;

import 'enums.dart' show borderStyleCodec;
import 'numbers.dart';
import 'primitives/color.dart' show colorCodec;

/// Named [BorderSide.strokeAlign] offsets, encoded as string aliases.
enum _StrokeAlign { inside, center, outside }

/// Codec for [BorderSide.strokeAlign] values.
///
/// Accepts the named aliases `"inside"`, `"center"`, and `"outside"` (mapping
/// to [BorderSide.strokeAlignInside], [BorderSide.strokeAlignCenter], and
/// [BorderSide.strokeAlignOutside]) as well as any finite number. Encoding
/// canonicalizes the three named offsets back to their aliases and emits any
/// other finite value as a number.
final strokeAlignCodec = Ack.codec<Object, Object, double>(
  input: Ack.anyOf([Ack.enumCodec(_StrokeAlign.values), finiteNumber()]),
  decode: _decodeStrokeAlign,
  encode: _encodeStrokeAlign,
);

double _decodeStrokeAlign(Object value) {
  if (value is num) return value.toDouble();

  return switch (value as _StrokeAlign) {
    _StrokeAlign.inside => BorderSide.strokeAlignInside,
    _StrokeAlign.center => BorderSide.strokeAlignCenter,
    _StrokeAlign.outside => BorderSide.strokeAlignOutside,
  };
}

Object _encodeStrokeAlign(double value) {
  return switch (value) {
    BorderSide.strokeAlignInside => _StrokeAlign.inside,
    BorderSide.strokeAlignCenter => _StrokeAlign.center,
    BorderSide.strokeAlignOutside => _StrokeAlign.outside,
    _ => value,
  };
}

/// Codec for [BorderSide], composing [colorCodec], [borderStyleCodec], and
/// [strokeAlignCodec].
///
/// Missing fields fall back to Flutter's [BorderSide] constructor defaults, so
/// `{}` decodes to `const BorderSide()`. Encoding always emits a full canonical
/// object with all four fields.
final borderSideCodec = Ack.object({
  'color': colorCodec.withDefault(const Color(0xFF000000)),
  'width': nonNegativeFiniteNumber().withDefault(1.0),
  'style': borderStyleCodec.withDefault(BorderStyle.solid),
  'strokeAlign': strokeAlignCodec.withDefault(BorderSide.strokeAlignInside),
}).model<BorderSide>(decode: _decodeBorderSide, encode: _encodeBorderSide);

BorderSide _decodeBorderSide(JsonMap data) {
  return BorderSide(
    color: data['color']! as Color,
    width: readDouble(data, 'width'),
    style: data['style']! as BorderStyle,
    strokeAlign: data['strokeAlign']! as double,
  );
}

// Returns runtime property values (Color, BorderStyle, double), not JSON. The
// object schema re-encodes each property through its own schema (colorCodec,
// borderStyleCodec, strokeAlignCodec) to produce the JSON-safe boundary.
JsonMap _encodeBorderSide(BorderSide value) {
  return {
    'color': value.color,
    'width': value.width,
    'style': value.style,
    'strokeAlign': value.strokeAlign,
  };
}
