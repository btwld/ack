import 'package:ack/ack.dart';
import 'package:flutter/painting.dart' show Radius;

import '../json_readers.dart';

/// Codec for [Radius]. A single non-negative number is a circular radius;
/// `{"x": ..., "y": ...}` is elliptical. Circular radii encode back to a number.
final radiusCodec = Ack.codec<Object, Object, Radius>(
  input: Ack.anyOf([
    Ack.number().min(0),
    Ack.object({'x': Ack.number().min(0), 'y': Ack.number().min(0)}),
  ]),
  decode: _decodeRadius,
  encode: _encodeRadius,
);

Radius _decodeRadius(Object value) {
  if (value is num) {
    return Radius.circular(value.toDouble());
  }

  final map = value as JsonMap;
  return Radius.elliptical(readDouble(map, 'x'), readDouble(map, 'y'));
}

Object _encodeRadius(Radius value) {
  if (value.x == value.y) return value.x;
  return {'x': value.x, 'y': value.y};
}
