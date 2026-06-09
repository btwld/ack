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
        Decoration,
        DecorationImage,
        Gradient,
        ShapeBorder,
        ShapeDecoration;

import 'borders.dart' show boxBorderCodec;
import 'decoration_image.dart' show decorationImageCodec;
import 'enums.dart' show blendModeCodec, boxShapeCodec;
import 'gradients.dart' show gradientCodec;
import 'json_readers.dart';
import 'primitives/border_radius.dart' show borderRadiusGeometryCodec;
import 'primitives/color.dart' show colorCodec;
import 'shadows.dart' show boxShadowCodec;
import 'shape_borders.dart' show shapeBorderCodec;

/// Codec for [BoxDecoration].
///
/// Composes every JSON-safe constructor field: `color` ([colorCodec]),
/// `image` ([decorationImageCodec]), `border` ([boxBorderCodec]),
/// `borderRadius` ([borderRadiusGeometryCodec]), `boxShadow`
/// ([boxShadowCodec]), `gradient` ([gradientCodec]), `backgroundBlendMode`
/// ([blendModeCodec]), and `shape` ([boxShapeCodec], default
/// [BoxShape.rectangle]). The `"type"` discriminator is added by
/// [decorationCodec] when this codec is used as one of its branches.
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
        })
        // Enforced here (not just by the constructor's debug assert) so the
        // check holds in release builds.
        .refine(
          (data) =>
              data['backgroundBlendMode'] == null ||
              data['color'] != null ||
              data['gradient'] != null,
          message:
              'BoxDecoration.backgroundBlendMode requires a color or gradient.',
        )
        .codec<BoxDecoration>(
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

/// Codec for [ShapeDecoration].
///
/// Composes every JSON-safe constructor field: `color` ([colorCodec]),
/// `image` ([decorationImageCodec]), `gradient` ([gradientCodec]), `shadows`
/// ([boxShadowCodec]), and the required `shape` ([shapeBorderCodec]). Unset
/// optional fields are emitted as explicit nulls for round-trip stability,
/// matching the canonical-map convention used by [boxDecorationCodec]. The
/// `"type"` discriminator is added by [decorationCodec] when this codec is
/// used as one of its branches.
///
/// [ShapeDecoration] asserts that `color` and `gradient` cannot both be
/// non-null; this codec enforces the same rule with a refinement so it holds
/// in release builds (where the constructor assert is stripped).
final shapeDecorationCodec =
    Ack.object({
          'color': colorCodec.nullable().optional(),
          'image': decorationImageCodec.nullable().optional(),
          'gradient': gradientCodec.nullable().optional(),
          'shadows': Ack.list(boxShadowCodec).nullable().optional(),
          'shape': shapeBorderCodec,
        })
        .refine(
          (data) => data['color'] == null || data['gradient'] == null,
          message: 'ShapeDecoration cannot set both color and gradient.',
        )
        .codec<ShapeDecoration>(
          decode: _decodeShapeDecoration,
          encode: _encodeShapeDecoration,
        );

ShapeDecoration _decodeShapeDecoration(JsonMap data) {
  return ShapeDecoration(
    color: readNullableValue<Color>(data, 'color'),
    image: readNullableValue<DecorationImage>(data, 'image'),
    gradient: readNullableValue<Gradient>(data, 'gradient'),
    shadows: readNullableList<BoxShadow>(data, 'shadows'),
    shape: readValue<ShapeBorder>(data, 'shape'),
  );
}

JsonMap _encodeShapeDecoration(ShapeDecoration value) {
  return {
    'color': value.color,
    'image': value.image,
    'gradient': value.gradient,
    'shadows': value.shadows,
    'shape': value.shape,
  };
}

/// Codec for the abstract [Decoration] type, discriminated by `"type"`.
///
/// * `"box"` → [BoxDecoration] via [boxDecorationCodec]
/// * `"shape"` → [ShapeDecoration] via [shapeDecorationCodec]
///
/// The `"type"` discriminator is synthesized by the union: encoding adds the
/// key automatically, and parsing uses it to select the branch. Each
/// underlying codec ([boxDecorationCodec], [shapeDecorationCodec]) remains
/// usable on its own without a `"type"` field — unlike the gradient family,
/// the decoration branches do not embed a `"type"` literal in their standalone
/// schemas, so the discriminator only exists at the union layer.
///
/// Other [Decoration] subtypes ([FlutterLogoDecoration], custom decorations)
/// are intentionally not covered — they either lack a portable JSON shape or
/// belong outside the painting layer.
final decorationCodec = Ack.discriminated<Decoration>(
  discriminatorKey: 'type',
  schemas: {'box': boxDecorationCodec, 'shape': shapeDecorationCodec},
);
