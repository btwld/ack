import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show
        BeveledRectangleBorder,
        BorderRadius,
        BorderRadiusGeometry,
        BorderSide,
        CircleBorder,
        ContinuousRectangleBorder,
        LinearBorder,
        LinearBorderEdge,
        OutlinedBorder,
        RoundedRectangleBorder,
        RoundedSuperellipseBorder,
        ShapeBorder,
        StadiumBorder,
        StarBorder;

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

/// Codec for [StarBorder].
///
/// Composes [borderSideCodec] for [StarBorder.side] (default
/// [BorderSide.none]) with the six shape-control doubles: `points`
/// (default `5`, `>= 2`), `innerRadiusRatio` (default `0.4`, `[0, 1]`),
/// `pointRounding` and `valleyRounding` (each default `0`, each in
/// `[0, 1]`), `rotation` in degrees (default `0`), and `squash`
/// (default `0`, `[0, 1]`).
///
/// `points` is intentionally typed as a number rather than an integer to
/// match Flutter's constructor: non-integer values produce an additional
/// shorter point or corner to finish the shape, enabling smooth
/// animation between point counts.
///
/// The constructor also asserts `pointRounding + valleyRounding <= 1`;
/// that cross-field constraint is left to the constructor rather than
/// re-enforced here. The `"type"` discriminator is added by
/// [shapeBorderCodec] when this codec is used as one of its branches.
///
/// `StarBorder.polygon` round-trips through the regular `StarBorder`
/// constructor: encoding reads the computed `innerRadiusRatio` and
/// `valleyRounding` (always `0` for polygons), so the painted output is
/// identical even though the runtime "this came from `.polygon`"
/// information is lost.
///
/// `rotation` is stored internally as radians and compared exactly by
/// `StarBorder` equality, while this codec round-trips it as degrees. The
/// degrees↔radians conversion is not bit-stable, so some rotations are
/// painted-equivalent but not `==`-equal after a round-trip.
final starBorderCodec =
    Ack.object({
      'side': borderSideCodec.withDefault(BorderSide.none),
      'points': Ack.number().min(2).withDefault(5),
      'innerRadiusRatio': Ack.number().min(0).max(1).withDefault(0.4),
      'pointRounding': Ack.number().min(0).max(1).withDefault(0.0),
      'valleyRounding': Ack.number().min(0).max(1).withDefault(0.0),
      'rotation': Ack.number().withDefault(0.0),
      'squash': Ack.number().min(0).max(1).withDefault(0.0),
    }).codec<StarBorder>(
      decode: (data) => StarBorder(
        side: readValue<BorderSide>(data, 'side'),
        points: readDouble(data, 'points'),
        innerRadiusRatio: readDouble(data, 'innerRadiusRatio'),
        pointRounding: readDouble(data, 'pointRounding'),
        valleyRounding: readDouble(data, 'valleyRounding'),
        rotation: readDouble(data, 'rotation'),
        squash: readDouble(data, 'squash'),
      ),
      encode: (value) => {
        'side': value.side,
        'points': value.points,
        'innerRadiusRatio': value.innerRadiusRatio,
        'pointRounding': value.pointRounding,
        'valleyRounding': value.valleyRounding,
        'rotation': value.rotation,
        'squash': value.squash,
      },
    );

/// Codec for [LinearBorderEdge].
///
/// Composes `size` (default `1.0`, `[0, 1]` matching the constructor
/// assert) and `alignment` (default `0.0`, `[-1, 1]` per dartdoc — the
/// constructor does not assert this bound but the codec enforces it).
/// Used as a sub-codec by [linearBorderCodec] for its four edge slots.
final linearBorderEdgeCodec =
    Ack.object({
      'size': Ack.number().min(0).max(1).withDefault(1.0),
      'alignment': Ack.number().min(-1).max(1).withDefault(0.0),
    }).codec<LinearBorderEdge>(
      decode: (data) => LinearBorderEdge(
        size: readDouble(data, 'size'),
        alignment: readDouble(data, 'alignment'),
      ),
      encode: (value) => {'size': value.size, 'alignment': value.alignment},
    );

/// Codec for [LinearBorder].
///
/// Composes [borderSideCodec] for [LinearBorder.side] (default
/// [BorderSide.none]) and four optional [LinearBorderEdge] slots —
/// `start`, `end`, `top`, `bottom` — via [linearBorderEdgeCodec]. The
/// convenience factories (`LinearBorder.start`, `.end`, `.top`,
/// `.bottom`, and `LinearBorder.none`) round-trip through the regular
/// constructor since their fields are publicly observable.
///
/// The `"type"` discriminator is added by [shapeBorderCodec] when this
/// codec is used as one of its branches.
final linearBorderCodec =
    Ack.object({
      'side': borderSideCodec.withDefault(BorderSide.none),
      'start': linearBorderEdgeCodec.nullable().optional(),
      'end': linearBorderEdgeCodec.nullable().optional(),
      'top': linearBorderEdgeCodec.nullable().optional(),
      'bottom': linearBorderEdgeCodec.nullable().optional(),
    }).codec<LinearBorder>(
      decode: (data) => LinearBorder(
        side: readValue<BorderSide>(data, 'side'),
        start: readNullableValue<LinearBorderEdge>(data, 'start'),
        end: readNullableValue<LinearBorderEdge>(data, 'end'),
        top: readNullableValue<LinearBorderEdge>(data, 'top'),
        bottom: readNullableValue<LinearBorderEdge>(data, 'bottom'),
      ),
      encode: (value) => {
        'side': value.side,
        'start': value.start,
        'end': value.end,
        'top': value.top,
        'bottom': value.bottom,
      },
    );

/// Codec for JSON-safe [ShapeBorder] values, discriminated by `"type"`.
///
/// Covers the eight concrete [OutlinedBorder] subtypes Flutter exposes from
/// `package:flutter/painting.dart`:
///
/// * `"circle"` → [CircleBorder]
/// * `"stadium"` → [StadiumBorder]
/// * `"roundedRectangle"` → [RoundedRectangleBorder]
/// * `"beveledRectangle"` → [BeveledRectangleBorder]
/// * `"continuousRectangle"` → [ContinuousRectangleBorder]
/// * `"roundedSuperellipse"` → [RoundedSuperellipseBorder] (Flutter 3.27+)
/// * `"star"` → [StarBorder]
/// * `"linear"` → [LinearBorder]
///
/// `InputBorder` subtypes (Material — `OutlineInputBorder`,
/// `UnderlineInputBorder`) are intentionally not covered here — they live
/// in `package:flutter/material.dart` rather than the painting layer and
/// belong to a separate plan.
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
    'star': starBorderCodec,
    'linear': linearBorderCodec,
  },
);
