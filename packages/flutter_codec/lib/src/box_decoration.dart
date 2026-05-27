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
        DecorationImage,
        Gradient;

import 'borders.dart' show boxBorderCodec;
import 'decoration_image.dart' show decorationImageCodec;
import 'enums.dart' show blendModeCodec, boxShapeCodec;
import 'gradients.dart' show gradientCodec;
import 'json_readers.dart';
import 'primitives/border_radius.dart' show borderRadiusGeometryCodec;
import 'primitives/color.dart' show colorCodec;
import 'shadows.dart' show boxShadowCodec;

/// Codec for [BoxDecoration].
///
/// Composes every JSON-safe constructor field: `color` ([colorCodec]),
/// `image` ([decorationImageCodec]), `border` ([boxBorderCodec]),
/// `borderRadius` ([borderRadiusGeometryCodec]), `boxShadow`
/// ([boxShadowCodec]), `gradient` ([gradientCodec]), `backgroundBlendMode`
/// ([blendModeCodec]), and `shape` ([boxShapeCodec], default
/// [BoxShape.rectangle]).
final boxDecorationCodec =
    Ack.object({
      'color': colorCodec.nullable().optional(),
      'image': decorationImageCodec.nullable().optional(),
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
    image: readNullableValue<DecorationImage>(data, 'image'),
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
    'image': value.image,
    'border': value.border,
    'borderRadius': value.borderRadius,
    'boxShadow': value.boxShadow,
    'gradient': value.gradient,
    'backgroundBlendMode': value.backgroundBlendMode,
    'shape': value.shape,
  };
}
