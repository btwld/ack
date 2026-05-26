import 'package:ack/ack.dart';
import 'package:flutter/painting.dart'
    show BorderRadius, BorderRadiusDirectional, BorderRadiusGeometry, Radius;

import 'radius.dart' show radiusCodec;

/// Codec for [BorderRadius]. A single radius (a number or `{x,y}`) sets all four
/// corners; an object `{topLeft, topRight, bottomLeft, bottomRight}` (each corner
/// optional, defaulting to `Radius.zero`) sets them individually. Encoding emits
/// a single radius when all corners are equal, otherwise the full object.
final borderRadiusCodec = Ack.codec<Object, Object, BorderRadius>(
  input: Ack.anyOf([
    radiusCodec,
    Ack.object({
      'topLeft': radiusCodec.withDefault(Radius.zero),
      'topRight': radiusCodec.withDefault(Radius.zero),
      'bottomLeft': radiusCodec.withDefault(Radius.zero),
      'bottomRight': radiusCodec.withDefault(Radius.zero),
    }),
  ]),
  decode: _decodeBorderRadius,
  encode: _encodeBorderRadius,
);

BorderRadius _decodeBorderRadius(Object value) {
  if (value is Radius) return BorderRadius.all(value);

  final map = value as JsonMap;
  return BorderRadius.only(
    topLeft: map['topLeft']! as Radius,
    topRight: map['topRight']! as Radius,
    bottomLeft: map['bottomLeft']! as Radius,
    bottomRight: map['bottomRight']! as Radius,
  );
}

Object _encodeBorderRadius(BorderRadius value) {
  if (value.topLeft == value.topRight &&
      value.topRight == value.bottomLeft &&
      value.bottomLeft == value.bottomRight) {
    return value.topLeft;
  }

  return {
    'topLeft': value.topLeft,
    'topRight': value.topRight,
    'bottomLeft': value.bottomLeft,
    'bottomRight': value.bottomRight,
  };
}

/// Codec for [BorderRadiusDirectional], an object
/// `{topStart, topEnd, bottomStart, bottomEnd}` (each corner optional, defaulting
/// to `Radius.zero`). Always encodes to the object form — never a shorthand — so
/// the directional type round-trips even when uniform or zero (a single radius is
/// reserved for [BorderRadius]).
final borderRadiusDirectionalCodec =
    Ack.object({
      'topStart': radiusCodec.withDefault(Radius.zero),
      'topEnd': radiusCodec.withDefault(Radius.zero),
      'bottomStart': radiusCodec.withDefault(Radius.zero),
      'bottomEnd': radiusCodec.withDefault(Radius.zero),
    }).codec<BorderRadiusDirectional>(
      decode: (data) => BorderRadiusDirectional.only(
        topStart: data['topStart']! as Radius,
        topEnd: data['topEnd']! as Radius,
        bottomStart: data['bottomStart']! as Radius,
        bottomEnd: data['bottomEnd']! as Radius,
      ),
      encode: (value) => {
        'topStart': value.topStart,
        'topEnd': value.topEnd,
        'bottomStart': value.bottomStart,
        'bottomEnd': value.bottomEnd,
      },
    );

/// Codec for [BorderRadiusGeometry], unioning [borderRadiusCodec] and
/// [borderRadiusDirectionalCodec].
///
/// A radius shorthand, an `{topLeft, …}` object, and `{}` decode to
/// [BorderRadius]; objects carrying `topStart`/`topEnd`/`bottomStart`/`bottomEnd`
/// decode to [BorderRadiusDirectional] ([borderRadiusCodec] is tried first).
/// Encoding dispatches by runtime type. Mixed radii (from adding a [BorderRadius]
/// to a [BorderRadiusDirectional]) are not supported.
final borderRadiusGeometryCodec =
    Ack.anyOf([
      borderRadiusCodec,
      borderRadiusDirectionalCodec,
    ]).codec<BorderRadiusGeometry>(
      decode: (value) => value as BorderRadiusGeometry,
      encode: (value) => value,
    );
