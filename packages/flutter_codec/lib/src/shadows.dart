import 'dart:ui' as ui show Shadow;

import 'package:ack/ack.dart';
import 'package:flutter/painting.dart' show BlurStyle, BoxShadow, Color, Offset;

import 'enums.dart' show blurStyleCodec;
import 'numbers.dart';
import 'primitives/color.dart' show colorCodec;
import 'primitives/offset.dart' show offsetCodec;

/// Codec for [ui.Shadow], an object `{color, offset, blurRadius}` with each
/// field optional and falling back to the [ui.Shadow] constructor defaults.
/// `{}` decodes to `const ui.Shadow()`.
final shadowCodec =
    Ack.object({
      'color': colorCodec.withDefault(const Color(0xFF000000)),
      'offset': offsetCodec.withDefault(Offset.zero),
      'blurRadius': Ack.number().min(0).withDefault(0.0),
    }).codec<ui.Shadow>(
      decode: (data) => ui.Shadow(
        color: data['color']! as Color,
        offset: data['offset']! as Offset,
        blurRadius: readDouble(data, 'blurRadius'),
      ),
      encode: (value) => {
        'color': value.color,
        'offset': value.offset,
        'blurRadius': value.blurRadius,
      },
    );

/// Codec for [BoxShadow], extending the [shadowCodec] field set with
/// `spreadRadius` and `blurStyle`. `{}` decodes to `const BoxShadow()`.
///
/// `blurRadius` is non-negative (Flutter requirement). `spreadRadius` is
/// unconstrained — negative values shrink the shadow.
final boxShadowCodec =
    Ack.object({
      'color': colorCodec.withDefault(const Color(0xFF000000)),
      'offset': offsetCodec.withDefault(Offset.zero),
      'blurRadius': Ack.number().min(0).withDefault(0.0),
      'spreadRadius': Ack.number().withDefault(0.0),
      'blurStyle': blurStyleCodec.withDefault(BlurStyle.normal),
    }).codec<BoxShadow>(
      decode: (data) => BoxShadow(
        color: data['color']! as Color,
        offset: data['offset']! as Offset,
        blurRadius: readDouble(data, 'blurRadius'),
        spreadRadius: readDouble(data, 'spreadRadius'),
        blurStyle: data['blurStyle']! as BlurStyle,
      ),
      encode: (value) => {
        'color': value.color,
        'offset': value.offset,
        'blurRadius': value.blurRadius,
        'spreadRadius': value.spreadRadius,
        'blurStyle': value.blurStyle,
      },
    );
