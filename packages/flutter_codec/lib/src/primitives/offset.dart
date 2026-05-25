import 'package:ack/ack.dart';
import 'package:flutter/painting.dart' show Offset;

final offsetCodec = Ack.object({'x': Ack.number(), 'y': Ack.number()})
    .model<Offset>(
      decode: (data) {
        final x = data['x']! as num;
        final y = data['y']! as num;
        return Offset(x.toDouble(), y.toDouble());
      },
      encode: (value) => {'x': value.dx, 'y': value.dy},
    );
