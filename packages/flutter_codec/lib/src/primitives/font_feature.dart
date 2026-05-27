import 'package:ack/ack.dart';
import 'package:flutter/painting.dart' show FontFeature;

import '../json_readers.dart';

// 4-character printable-ASCII tag pattern shared by OpenType feature names
// and variation axis identifiers. Flutter only asserts `.length == 4` at
// construction; the printable-ASCII range is tightened here because OpenType
// tags are by spec ASCII and the wire format should reject control-character
// payloads that the Dart constructor would silently accept.
const _tagPattern = r'^[\x20-\x7E]{4}$';

/// Codec for [FontFeature].
///
/// Serializes the public [FontFeature.feature] (a 4-character OpenType
/// feature tag, e.g. `"smcp"` or `"liga"`) and [FontFeature.value] (a
/// non-negative integer; defaults to `1`, the conventional "enable" value).
///
/// Convenience constructors like [FontFeature.enable] or
/// [FontFeature.alternative] are not preserved on round-trip because they all
/// materialize as the same `(feature, value)` pair on the resulting
/// [FontFeature] instance.
final fontFeatureCodec =
    Ack.object({
      'feature': Ack.string().matches(_tagPattern),
      'value': Ack.integer().min(0).withDefault(1),
    }).codec<FontFeature>(
      decode: (data) => FontFeature(
        readValue<String>(data, 'feature'),
        readValue<int>(data, 'value'),
      ),
      encode: (value) => {'feature': value.feature, 'value': value.value},
    );
