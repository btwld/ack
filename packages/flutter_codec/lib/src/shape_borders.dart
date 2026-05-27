import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show
        BeveledRectangleBorder,
        BorderRadius,
        BorderRadiusGeometry,
        BorderSide,
        CircleBorder,
        ContinuousRectangleBorder,
        OutlinedBorder,
        RoundedRectangleBorder,
        RoundedSuperellipseBorder,
        ShapeBorder,
        StadiumBorder;

import 'borders.dart' show borderSideCodec;
import 'json_readers.dart';
import 'primitives/border_radius.dart' show borderRadiusGeometryCodec;

// Shared `{side, borderRadius}` schema for the four corner-rounded
// rectangular border codecs ([roundedRectangleBorderCodec],
// [beveledRectangleBorderCodec], [continuousRectangleBorderCodec],
// [roundedSuperellipseBorderCodec]). They accept the same JSON payload and
// differ only in the runtime [ShapeBorder] subtype they decode to.
final _rectangleBorderSchema = Ack.object({
  'side': borderSideCodec.withDefault(BorderSide.none),
  'borderRadius': borderRadiusGeometryCodec.withDefault(BorderRadius.zero),
});

/// Codec for [CircleBorder].
///
/// Composes [borderSideCodec] for [CircleBorder.side] and a non-negative
/// `eccentricity` in `[0, 1]` (default `0.0`, a perfect circle; `1.0` is a
/// fully flattened ellipse — matching the bounds Flutter's constructor
/// asserts). The `"type"` discriminator is added by [shapeBorderCodec] when
/// this codec is used as one of its branches.
final circleBorderCodec =
    Ack.object({
      'side': borderSideCodec.withDefault(BorderSide.none),
      'eccentricity': Ack.number().min(0).max(1).withDefault(0.0),
    }).codec<CircleBorder>(
      decode: (data) => CircleBorder(
        side: readValue<BorderSide>(data, 'side'),
        eccentricity: readDouble(data, 'eccentricity'),
      ),
      encode: (value) => {
        'side': value.side,
        'eccentricity': value.eccentricity,
      },
    );

/// Codec for [StadiumBorder].
///
/// Composes [borderSideCodec] for [StadiumBorder.side]. The `"type"`
/// discriminator is added by [shapeBorderCodec] when this codec is used as
/// one of its branches.
final stadiumBorderCodec =
    Ack.object({
      'side': borderSideCodec.withDefault(BorderSide.none),
    }).codec<StadiumBorder>(
      decode: (data) =>
          StadiumBorder(side: readValue<BorderSide>(data, 'side')),
      encode: (value) => {'side': value.side},
    );

/// Codec for [RoundedRectangleBorder].
///
/// Composes [borderSideCodec] for [RoundedRectangleBorder.side] and
/// [borderRadiusGeometryCodec] for [RoundedRectangleBorder.borderRadius]
/// (default [BorderRadius.zero], matching the constructor). The `"type"`
/// discriminator is added by [shapeBorderCodec] when this codec is used as
/// one of its branches.
final roundedRectangleBorderCodec = _rectangleBorderSchema
    .codec<RoundedRectangleBorder>(
      decode: (data) => RoundedRectangleBorder(
        side: readValue<BorderSide>(data, 'side'),
        borderRadius: readValue<BorderRadiusGeometry>(data, 'borderRadius'),
      ),
      encode: (value) => {
        'side': value.side,
        'borderRadius': value.borderRadius,
      },
    );

/// Codec for [BeveledRectangleBorder].
///
/// Shares the `{side, borderRadius}` shape with [roundedRectangleBorderCodec]
/// and [continuousRectangleBorderCodec]; the runtime [ShapeBorder] subtype is
/// the only difference. The `"type"` discriminator is added by
/// [shapeBorderCodec] when this codec is used as one of its branches.
final beveledRectangleBorderCodec = _rectangleBorderSchema
    .codec<BeveledRectangleBorder>(
      decode: (data) => BeveledRectangleBorder(
        side: readValue<BorderSide>(data, 'side'),
        borderRadius: readValue<BorderRadiusGeometry>(data, 'borderRadius'),
      ),
      encode: (value) => {
        'side': value.side,
        'borderRadius': value.borderRadius,
      },
    );

/// Codec for [ContinuousRectangleBorder].
///
/// Shares the `{side, borderRadius}` shape with [roundedRectangleBorderCodec]
/// and [beveledRectangleBorderCodec]; the runtime [ShapeBorder] subtype is
/// the only difference. The `"type"` discriminator is added by
/// [shapeBorderCodec] when this codec is used as one of its branches.
final continuousRectangleBorderCodec = _rectangleBorderSchema
    .codec<ContinuousRectangleBorder>(
      decode: (data) => ContinuousRectangleBorder(
        side: readValue<BorderSide>(data, 'side'),
        borderRadius: readValue<BorderRadiusGeometry>(data, 'borderRadius'),
      ),
      encode: (value) => {
        'side': value.side,
        'borderRadius': value.borderRadius,
      },
    );

/// Codec for [RoundedSuperellipseBorder].
///
/// Shares the `{side, borderRadius}` shape with the other corner-rounded
/// rectangle border codecs ([roundedRectangleBorderCodec],
/// [beveledRectangleBorderCodec], [continuousRectangleBorderCodec]); only the
/// runtime [ShapeBorder] subtype differs. Requires Flutter 3.27 or later.
/// The `"type"` discriminator is added by [shapeBorderCodec] when this codec
/// is used as one of its branches.
final roundedSuperellipseBorderCodec = _rectangleBorderSchema
    .codec<RoundedSuperellipseBorder>(
      decode: (data) => RoundedSuperellipseBorder(
        side: readValue<BorderSide>(data, 'side'),
        borderRadius: readValue<BorderRadiusGeometry>(data, 'borderRadius'),
      ),
      encode: (value) => {
        'side': value.side,
        'borderRadius': value.borderRadius,
      },
    );

/// Codec for JSON-safe [ShapeBorder] values, discriminated by `"type"`.
///
/// Covers the six concrete [OutlinedBorder] subtypes Flutter exposes from
/// `package:flutter/painting.dart`:
///
/// * `"circle"` → [CircleBorder]
/// * `"stadium"` → [StadiumBorder]
/// * `"roundedRectangle"` → [RoundedRectangleBorder]
/// * `"beveledRectangle"` → [BeveledRectangleBorder]
/// * `"continuousRectangle"` → [ContinuousRectangleBorder]
/// * `"roundedSuperellipse"` → [RoundedSuperellipseBorder] (Flutter 3.27+)
///
/// [InputBorder] subtypes (Material) and the newer [StarBorder] / [LinearBorder]
/// shapes are intentionally not covered here — they belong to separate plans
/// because their constructor surfaces are materially different.
///
/// `OvalBorder` extends [CircleBorder], so it round-trips as a
/// [CircleBorder] (the runtime subtype is lost). Its painted output is
/// equivalent to `CircleBorder(eccentricity: 1.0)`, but callers that depend
/// on the precise runtime type should handle that conversion themselves.
///
/// Custom user-defined [ShapeBorder] subtypes are rejected on encode rather
/// than guessing a non-portable JSON shape.
final shapeBorderCodec = Ack.discriminated<ShapeBorder>(
  discriminatorKey: 'type',
  schemas: {
    'circle': circleBorderCodec,
    'stadium': stadiumBorderCodec,
    'roundedRectangle': roundedRectangleBorderCodec,
    'beveledRectangle': beveledRectangleBorderCodec,
    'continuousRectangle': continuousRectangleBorderCodec,
    'roundedSuperellipse': roundedSuperellipseBorderCodec,
  },
);
