import 'dart:math' as math;

import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show
        Alignment,
        AlignmentGeometry,
        Color,
        Gradient,
        LinearGradient,
        RadialGradient,
        SweepGradient,
        TileMode;

import 'enums.dart' show tileModeCodec;
import 'json_readers.dart';
import 'primitives/alignment.dart' show alignmentGeometryCodec;
import 'primitives/color.dart' show colorCodec;

/// Codec for [LinearGradient]. Tagged with `"type": "linear"`.
///
/// `colors` is required and must contain at least two entries. `stops`, when
/// non-null, should have the same length as `colors` (enforced by Flutter at
/// paint time, not by the schema). `transform` is not supported — apply
/// gradient transforms outside the codec layer.
final linearGradientCodec =
    Ack.object({
      'type': Ack.literal('linear'),
      'begin': alignmentGeometryCodec.withDefault(Alignment.centerLeft),
      'end': alignmentGeometryCodec.withDefault(Alignment.centerRight),
      'colors': Ack.list(colorCodec).minItems(2),
      'stops': Ack.list(Ack.number()).nullable().optional(),
      'tileMode': tileModeCodec.withDefault(TileMode.clamp),
    }).codec<LinearGradient>(
      decode: (data) => LinearGradient(
        begin: readValue<AlignmentGeometry>(data, 'begin'),
        end: readValue<AlignmentGeometry>(data, 'end'),
        colors: readList<Color>(data, 'colors'),
        stops: readNullableDoubleList(data, 'stops'),
        tileMode: readValue<TileMode>(data, 'tileMode'),
      ),
      encode: (value) => {
        'type': 'linear',
        'begin': value.begin,
        'end': value.end,
        'colors': value.colors,
        'stops': value.stops,
        'tileMode': value.tileMode,
      },
    );

/// Codec for [RadialGradient]. Tagged with `"type": "radial"`.
///
/// `radius` and `focalRadius` are non-negative. `focal` is optional. See
/// [linearGradientCodec] for shared notes on `colors`, `stops`, and
/// `transform`.
final radialGradientCodec =
    Ack.object({
      'type': Ack.literal('radial'),
      'center': alignmentGeometryCodec.withDefault(Alignment.center),
      'radius': Ack.number().min(0).withDefault(0.5),
      'colors': Ack.list(colorCodec).minItems(2),
      'stops': Ack.list(Ack.number()).nullable().optional(),
      'tileMode': tileModeCodec.withDefault(TileMode.clamp),
      'focal': alignmentGeometryCodec.nullable().optional(),
      'focalRadius': Ack.number().min(0).withDefault(0.0),
    }).codec<RadialGradient>(
      decode: (data) => RadialGradient(
        center: readValue<AlignmentGeometry>(data, 'center'),
        radius: readDouble(data, 'radius'),
        colors: readList<Color>(data, 'colors'),
        stops: readNullableDoubleList(data, 'stops'),
        tileMode: readValue<TileMode>(data, 'tileMode'),
        focal: readNullableValue<AlignmentGeometry>(data, 'focal'),
        focalRadius: readDouble(data, 'focalRadius'),
      ),
      encode: (value) => {
        'type': 'radial',
        'center': value.center,
        'radius': value.radius,
        'colors': value.colors,
        'stops': value.stops,
        'tileMode': value.tileMode,
        'focal': value.focal,
        'focalRadius': value.focalRadius,
      },
    );

/// Codec for [SweepGradient]. Tagged with `"type": "sweep"`.
///
/// `startAngle` and `endAngle` are radians (default `0.0` and `2π`). See
/// [linearGradientCodec] for shared notes on `colors`, `stops`, and
/// `transform`.
final sweepGradientCodec =
    Ack.object({
      'type': Ack.literal('sweep'),
      'center': alignmentGeometryCodec.withDefault(Alignment.center),
      'startAngle': Ack.number().withDefault(0.0),
      'endAngle': Ack.number().withDefault(math.pi * 2),
      'colors': Ack.list(colorCodec).minItems(2),
      'stops': Ack.list(Ack.number()).nullable().optional(),
      'tileMode': tileModeCodec.withDefault(TileMode.clamp),
    }).codec<SweepGradient>(
      decode: (data) => SweepGradient(
        center: readValue<AlignmentGeometry>(data, 'center'),
        startAngle: readDouble(data, 'startAngle'),
        endAngle: readDouble(data, 'endAngle'),
        colors: readList<Color>(data, 'colors'),
        stops: readNullableDoubleList(data, 'stops'),
        tileMode: readValue<TileMode>(data, 'tileMode'),
      ),
      encode: (value) => {
        'type': 'sweep',
        'center': value.center,
        'startAngle': value.startAngle,
        'endAngle': value.endAngle,
        'colors': value.colors,
        'stops': value.stops,
        'tileMode': value.tileMode,
      },
    );

/// Codec for [Gradient], discriminated by a `"type"` key (`"linear"`,
/// `"radial"`, or `"sweep"`). Each branch is the corresponding concrete
/// codec, upcast to the union runtime type. The standalone codecs
/// ([linearGradientCodec], [radialGradientCodec], [sweepGradientCodec]) carry
/// the same `"type"` literal, so a value encoded through this union round-trips
/// through them and vice versa.
final gradientCodec = Ack.discriminated<Gradient>(
  discriminatorKey: 'type',
  schemas: {
    'linear': linearGradientCodec.codec<Gradient>(
      decode: (value) => value,
      encode: (value) => value as LinearGradient,
    ),
    'radial': radialGradientCodec.codec<Gradient>(
      decode: (value) => value,
      encode: (value) => value as RadialGradient,
    ),
    'sweep': sweepGradientCodec.codec<Gradient>(
      decode: (value) => value,
      encode: (value) => value as SweepGradient,
    ),
  },
);
