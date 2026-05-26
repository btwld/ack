import 'package:ack/ack.dart';
import 'package:flutter/painting.dart' show Offset;

import '../numbers.dart';

/// Codec for [Offset], represented as `{"x": ..., "y": ...}`.
final offsetCodec = Ack.object({'x': Ack.number(), 'y': Ack.number()})
    .codec<Offset>(
      decode: (data) => Offset(readDouble(data, 'x'), readDouble(data, 'y')),
      encode: (value) => {'x': value.dx, 'y': value.dy},
    );
