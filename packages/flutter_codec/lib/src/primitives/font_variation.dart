import 'package:ack/ack.dart';
import 'package:flutter/painting.dart' show FontVariation;

import '../json_readers.dart';

// 4-character printable-ASCII axis tag pattern. Flutter only asserts
// `.length == 4` at construction; see `font_feature.dart` for the rationale
// behind the tighter printable-ASCII check applied at the wire layer.
const _axisPattern = r'^[\x20-\x7E]{4}$';

/// Codec for [FontVariation].
///
/// Serializes the public [FontVariation.axis] (a 4-character OpenType
/// variation axis tag, e.g. `"wght"` or `"wdth"`) and [FontVariation.value]
/// (a [double] constrained to the `[-32768, 32768)` 16.16 fixed-point range
/// that the [FontVariation] constructor requires).
///
/// Convenience constructors like [FontVariation.weight] are not preserved on
/// round-trip because they all materialize as the same `(axis, value)` pair
/// on the resulting [FontVariation] instance.
final fontVariationCodec =
    Ack.object({
      'axis': Ack.string().matches(_axisPattern),
      'value': Ack.number().min(-32768).lessThan(32768),
    }).codec<FontVariation>(
      decode: (data) => FontVariation(
        readValue<String>(data, 'axis'),
        readDouble(data, 'value'),
      ),
      encode: (value) => {'axis': value.axis, 'value': value.value},
    );
