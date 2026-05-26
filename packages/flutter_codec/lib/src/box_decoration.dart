import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show
        BlendMode,
        BorderRadiusGeometry,
        BoxBorder,
        BoxDecoration,
        BoxShadow,
        BoxShape,
        Color,
        Gradient;

import 'borders.dart' show boxBorderCodec;
import 'enums.dart' show blendModeCodec, boxShapeCodec;
import 'gradients.dart' show gradientCodec;
import 'json_readers.dart';
import 'primitives/border_radius.dart' show borderRadiusGeometryCodec;
import 'primitives/color.dart' show colorCodec;
import 'shadows.dart' show boxShadowCodec;

const _unsupportedDecorationImageMessage =
    'DecorationImage is not yet supported by boxDecorationCodec.';

/// Codec for [BoxDecoration].
///
/// Supports the JSON-safe constructor fields: `color`, `border`,
/// `borderRadius`, `boxShadow`, `gradient`, `backgroundBlendMode`, and
/// `shape`.
///
/// `image` is intentionally deferred until the dedicated
/// `DecorationImage`/`ImageProvider` plan. Decode accepts only missing or
/// explicit `null` image values; encode always emits `"image": null` to keep
/// the canonical object shape stable.
final boxDecorationCodec =
    Ack.object({
      'color': colorCodec.nullable().optional(),
      'image': Ack.any().nullable().optional().refine(
        (_) => false,
        message: _unsupportedDecorationImageMessage,
      ),
      'border': boxBorderCodec.nullable().optional(),
      'borderRadius': borderRadiusGeometryCodec.nullable().optional(),
      'boxShadow': Ack.list(boxShadowCodec).nullable().optional(),
      'gradient': gradientCodec.nullable().optional(),
      'backgroundBlendMode': blendModeCodec.nullable().optional(),
      'shape': boxShapeCodec.withDefault(BoxShape.rectangle),
    }).codec<BoxDecoration>(
      decode: _decodeBoxDecoration,
      encode: _encodeBoxDecoration,
    );

BoxDecoration _decodeBoxDecoration(JsonMap data) {
  return BoxDecoration(
    color: readNullableValue<Color>(data, 'color'),
    border: readNullableValue<BoxBorder>(data, 'border'),
    borderRadius: readNullableValue<BorderRadiusGeometry>(data, 'borderRadius'),
    boxShadow: readNullableList<BoxShadow>(data, 'boxShadow'),
    gradient: readNullableValue<Gradient>(data, 'gradient'),
    backgroundBlendMode: readNullableValue<BlendMode>(
      data,
      'backgroundBlendMode',
    ),
    shape: readValue<BoxShape>(data, 'shape'),
  );
}

JsonMap _encodeBoxDecoration(BoxDecoration value) {
  return {
    'color': value.color,
    'image': null,
    'border': value.border,
    'borderRadius': value.borderRadius,
    'boxShadow': value.boxShadow,
    'gradient': value.gradient,
    'backgroundBlendMode': value.backgroundBlendMode,
    'shape': value.shape,
  };
}
