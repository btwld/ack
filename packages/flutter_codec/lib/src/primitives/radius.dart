import 'package:ack/ack.dart';
import 'package:flutter/painting.dart' show Radius;

final radiusCodec = Ack.codec<Object, Object, Radius>(
  input: Ack.anyOf([
    _nonNegativeNumber(),
    Ack.object({'x': _nonNegativeNumber(), 'y': _nonNegativeNumber()}),
  ]),
  decode: _decodeRadius,
  encode: _encodeRadius,
);

NumberSchema _nonNegativeNumber() {
  return Ack.number().refine(
    (value) => value >= 0,
    message: 'Expected a non-negative number.',
  );
}

Radius _decodeRadius(Object value) {
  if (value is num) {
    return Radius.circular(value.toDouble());
  }

  final map = value as JsonMap;
  final x = map['x']! as num;
  final y = map['y']! as num;
  return Radius.elliptical(x.toDouble(), y.toDouble());
}

Object _encodeRadius(Radius value) {
  if (value.x == value.y) return value.x;
  return {'x': value.x, 'y': value.y};
}
