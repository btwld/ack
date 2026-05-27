import 'package:ack/ack.dart';
import 'package:flutter/painting.dart' show Rect;

import '../json_readers.dart';

/// Codec for [Rect], represented as `{"left": ..., "top": ..., "right": ...,
/// "bottom": ...}`. All four sides are required; encoding uses LTRB form
/// to match the canonical Flutter constructor [Rect.fromLTRB].
final rectCodec =
    Ack.object({
      'left': Ack.number(),
      'top': Ack.number(),
      'right': Ack.number(),
      'bottom': Ack.number(),
    }).codec<Rect>(
      decode: (data) => Rect.fromLTRB(
        readDouble(data, 'left'),
        readDouble(data, 'top'),
        readDouble(data, 'right'),
        readDouble(data, 'bottom'),
      ),
      encode: (value) => {
        'left': value.left,
        'top': value.top,
        'right': value.right,
        'bottom': value.bottom,
      },
    );
