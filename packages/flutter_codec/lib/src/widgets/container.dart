import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show AlignmentGeometry, Color, Decoration, EdgeInsetsGeometry;
import 'package:flutter/rendering.dart' show BoxConstraints;
import 'package:flutter/widgets.dart' show Clip, Container, Matrix4, Widget;

import '../constraints.dart' show boxConstraintsCodec;
import '../decorations.dart' show decorationCodec;
import '../enums.dart' show clipCodec;
import '../json_readers.dart';
import '../primitives/alignment.dart' show alignmentGeometryCodec;
import '../primitives/color.dart' show colorCodec;
import '../primitives/edge_insets.dart' show edgeInsetsGeometryCodec;
import '../primitives/matrix4.dart' show matrix4Codec;
import 'key.dart' show keyCodec;
import 'widget.dart' show widgetCodec;

/// Codec for [Container].
///
/// `width` and `height` are accepted on decode because they are constructor
/// parameters, but Flutter stores them by tightening [Container.constraints].
/// Encoding therefore canonicalizes both shorthands to `constraints`.
final CodecSchema<JsonMap, Container> containerWidgetCodec =
    Ack.object({
          'key': keyCodec.nullable().optional(),
          'alignment': alignmentGeometryCodec.nullable().optional(),
          'padding': edgeInsetsGeometryCodec.nullable().optional(),
          'color': colorCodec.nullable().optional(),
          'isAntiAlias': Ack.boolean().withDefault(true),
          'decoration': decorationCodec.nullable().optional(),
          'foregroundDecoration': decorationCodec.nullable().optional(),
          'width': Ack.number().min(0).nullable().optional(),
          'height': Ack.number().min(0).nullable().optional(),
          'constraints': boxConstraintsCodec.nullable().optional(),
          'margin': edgeInsetsGeometryCodec.nullable().optional(),
          'transform': matrix4Codec.nullable().optional(),
          'transformAlignment': alignmentGeometryCodec.nullable().optional(),
          'clipBehavior': clipCodec.withDefault(Clip.none),
          'child': Ack.lazy<JsonMap, Widget>(
            'widgetCodec',
            () => widgetCodec,
          ).nullable().optional(),
        })
        // Enforce the constructor's cross-field invariants here so validation holds
        // in release builds too (Flutter's asserts are stripped outside debug).
        .refine(
          (data) => data['color'] == null || data['decoration'] == null,
          message: 'Container cannot set both color and decoration.',
        )
        .refine(
          (data) =>
              data['decoration'] != null || data['clipBehavior'] == Clip.none,
          message: 'Container clipBehavior requires a decoration.',
        )
        // Reject negative insets: Flutter's Padding/margin handling asserts
        // non-negative edges in debug, and the assert is stripped in release.
        .refine((data) {
          final padding = data['padding'];
          return padding is! EdgeInsetsGeometry || padding.isNonNegative;
        }, message: 'Container padding must not be negative.')
        .refine((data) {
          final margin = data['margin'];
          return margin is! EdgeInsetsGeometry || margin.isNonNegative;
        }, message: 'Container margin must not be negative.')
        .codec<Container>(decode: _decodeContainer, encode: _encodeContainer);

Container _decodeContainer(JsonMap data) {
  return Container(
    key: readNullableValue(data, 'key'),
    alignment: readNullableValue<AlignmentGeometry>(data, 'alignment'),
    padding: readNullableValue<EdgeInsetsGeometry>(data, 'padding'),
    color: readNullableValue<Color>(data, 'color'),
    isAntiAlias: readValue<bool>(data, 'isAntiAlias'),
    decoration: readNullableValue<Decoration>(data, 'decoration'),
    foregroundDecoration: readNullableValue<Decoration>(
      data,
      'foregroundDecoration',
    ),
    width: readNullableDouble(data, 'width'),
    height: readNullableDouble(data, 'height'),
    constraints: readNullableValue<BoxConstraints>(data, 'constraints'),
    margin: readNullableValue<EdgeInsetsGeometry>(data, 'margin'),
    transform: readNullableValue<Matrix4>(data, 'transform'),
    transformAlignment: readNullableValue<AlignmentGeometry>(
      data,
      'transformAlignment',
    ),
    clipBehavior: readValue<Clip>(data, 'clipBehavior'),
    child: readNullableValue<Widget>(data, 'child'),
  );
}

JsonMap _encodeContainer(Container value) {
  return {
    'key': value.key,
    'alignment': value.alignment,
    'padding': value.padding,
    'color': value.color,
    'isAntiAlias': value.isAntiAlias,
    'decoration': value.decoration,
    'foregroundDecoration': value.foregroundDecoration,
    'width': null,
    'height': null,
    'constraints': value.constraints,
    'margin': value.margin,
    'transform': value.transform,
    'transformAlignment': value.transformAlignment,
    'clipBehavior': value.clipBehavior,
    'child': value.child,
  };
}
