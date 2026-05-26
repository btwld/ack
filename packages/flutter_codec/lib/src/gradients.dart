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
import 'numbers.dart';
import 'primitives/alignment.dart' show alignmentGeometryCodec;
import 'primitives/color.dart' show colorCodec;

/// Reads the `colors` field, validated by the schema as a `List<Color>`.
List<Color> _readColors(JsonMap data) =>
    (data['colors']! as List).cast<Color>();

/// Reads the optional `stops` field as `List<double>?`.
List<double>? _readStops(JsonMap data) {
  final raw = data['stops'];
  if (raw == null) return null;

  return (raw as List).map((s) => (s as num).toDouble()).toList();
}

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
        begin: data['begin']! as AlignmentGeometry,
        end: data['end']! as AlignmentGeometry,
        colors: _readColors(data),
        stops: _readStops(data),
        tileMode: data['tileMode']! as TileMode,
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
        center: data['center']! as AlignmentGeometry,
        radius: readDouble(data, 'radius'),
        colors: _readColors(data),
        stops: _readStops(data),
        tileMode: data['tileMode']! as TileMode,
        focal: data['focal'] as AlignmentGeometry?,
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
        center: data['center']! as AlignmentGeometry,
        startAngle: readDouble(data, 'startAngle'),
        endAngle: readDouble(data, 'endAngle'),
        colors: _readColors(data),
        stops: _readStops(data),
        tileMode: data['tileMode']! as TileMode,
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

/// Codec for [Gradient], unioning the three concrete gradient codecs via the
/// `"type"` discriminator. Encoding dispatches by runtime type.
final gradientCodec =
    Ack.anyOf([
      linearGradientCodec,
      radialGradientCodec,
      sweepGradientCodec,
    ]).codec<Gradient>(
      decode: (value) => value as Gradient,
      encode: (value) => value,
    );
