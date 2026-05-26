import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show Border, BorderDirectional, BorderSide, BorderStyle, BoxBorder, Color;

import 'enums.dart' show borderStyleCodec;
import 'json_readers.dart';
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
  input: Ack.anyOf([Ack.enumCodec(_StrokeAlign.values), Ack.number()]),
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
/// The string `"none"` is a shorthand for [BorderSide.none]. Otherwise an
/// object `{color, width, style, strokeAlign}` is used, with each field
/// optional and falling back to the [BorderSide] constructor defaults — so
/// `{}` decodes to `const BorderSide()` (1px solid black, NOT
/// [BorderSide.none]; use `"none"` for that).
///
/// Encoding canonicalizes [BorderSide.none] to `"none"` and emits a full
/// canonical `{color, width, style, strokeAlign}` object for any other value.
final borderSideCodec = Ack.codec<Object, Object, BorderSide>(
  input: Ack.anyOf([
    Ack.literal('none'),
    Ack.object({
      'color': colorCodec.withDefault(const Color(0xFF000000)),
      'width': Ack.number().min(0).withDefault(1.0),
      'style': borderStyleCodec.withDefault(BorderStyle.solid),
      'strokeAlign': strokeAlignCodec.withDefault(BorderSide.strokeAlignInside),
    }),
  ]),
  decode: _decodeBorderSide,
  encode: _encodeBorderSide,
);

BorderSide _decodeBorderSide(Object value) {
  if (value == 'none') return BorderSide.none;

  final map = value as JsonMap;
  return BorderSide(
    color: readValue<Color>(map, 'color'),
    width: readDouble(map, 'width'),
    style: readValue<BorderStyle>(map, 'style'),
    strokeAlign: readValue<double>(map, 'strokeAlign'),
  );
}

// Returns runtime property values (Color, BorderStyle, double), not JSON. The
// object schema re-encodes each property through its own schema (colorCodec,
// borderStyleCodec, strokeAlignCodec) to produce the JSON-safe boundary.
Object _encodeBorderSide(BorderSide value) {
  if (value == BorderSide.none) return 'none';

  return {
    'color': value.color,
    'width': value.width,
    'style': value.style,
    'strokeAlign': value.strokeAlign,
  };
}

/// Codec for [Border]. A bare [BorderSide] shorthand (via [borderSideCodec])
/// fans the same side across all four edges via [Border.fromBorderSide]; an
/// object `{top, right, bottom, left}` (each side optional, defaulting to
/// [BorderSide.none]) sets them individually. Encoding canonicalizes uniform
/// borders back to the side shorthand, so `Border()` round-trips through
/// `"none"` and `Border.all(...)` through a single side object.
///
/// Note: `{}` decodes through the side branch to `Border.fromBorderSide(const
/// BorderSide())` — four 1px solid black sides — *not* `Border()`. Use
/// `"none"` for an empty border.
final borderCodec = Ack.codec<Object, Object, Border>(
  input: Ack.anyOf([
    borderSideCodec,
    Ack.object({
      'top': borderSideCodec.withDefault(BorderSide.none),
      'right': borderSideCodec.withDefault(BorderSide.none),
      'bottom': borderSideCodec.withDefault(BorderSide.none),
      'left': borderSideCodec.withDefault(BorderSide.none),
    }),
  ]),
  decode: _decodeBorder,
  encode: _encodeBorder,
);

Border _decodeBorder(Object value) {
  if (value is BorderSide) return Border.fromBorderSide(value);

  final map = value as JsonMap;
  return Border(
    top: readValue<BorderSide>(map, 'top'),
    right: readValue<BorderSide>(map, 'right'),
    bottom: readValue<BorderSide>(map, 'bottom'),
    left: readValue<BorderSide>(map, 'left'),
  );
}

Object _encodeBorder(Border value) {
  if (value.top == value.right &&
      value.right == value.bottom &&
      value.bottom == value.left) {
    return value.top;
  }

  return {
    'top': value.top,
    'right': value.right,
    'bottom': value.bottom,
    'left': value.left,
  };
}

/// Codec for [BorderDirectional], an object `{top, start, end, bottom}` (each
/// side optional, defaulting to [BorderSide.none]). Always encodes to the
/// object form — never a side shorthand — so the directional type round-trips
/// even when uniform or empty (a bare side is reserved for [Border]).
final borderDirectionalCodec =
    Ack.object({
      'top': borderSideCodec.withDefault(BorderSide.none),
      'start': borderSideCodec.withDefault(BorderSide.none),
      'end': borderSideCodec.withDefault(BorderSide.none),
      'bottom': borderSideCodec.withDefault(BorderSide.none),
    }).codec<BorderDirectional>(
      decode: (data) => BorderDirectional(
        top: readValue<BorderSide>(data, 'top'),
        start: readValue<BorderSide>(data, 'start'),
        end: readValue<BorderSide>(data, 'end'),
        bottom: readValue<BorderSide>(data, 'bottom'),
      ),
      encode: (value) => {
        'top': value.top,
        'start': value.start,
        'end': value.end,
        'bottom': value.bottom,
      },
    );

/// Codec for [BoxBorder], unioning [borderCodec] and [borderDirectionalCodec].
///
/// A bare side shorthand, an `{top, right, bottom, left}` object, and the
/// `"none"` alias decode to [Border]; objects carrying `start`/`end` decode to
/// [BorderDirectional] ([borderCodec] is tried first). Encoding dispatches by
/// runtime type. Mixed borders (the result of adding a [Border] to a
/// [BorderDirectional]) are not supported.
final boxBorderCodec = Ack.anyOf([borderCodec, borderDirectionalCodec])
    .codec<BoxBorder>(
      decode: (value) => value as BoxBorder,
      encode: (value) => value,
    );
