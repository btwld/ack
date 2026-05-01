import 'dart:convert';

import '../ack.dart';
import '../schemas/extensions/string_schema_extensions.dart';
import '../schemas/schema.dart';

/// Curated catalogue of bidirectional codec recipes.
///
/// Mirrors Zod 4.1's "Useful codecs" page. These are not built-in primitives —
/// they are pre-built [CodecSchema] instances composed from the same public
/// `Ack.codec(...)` factory that user code uses. Each recipe round-trips
/// cleanly via `safeEncode` / `safeDecode`.
///
/// Access via [Ack.codecs]. Example:
///
/// ```dart
/// final user = Ack.object({
///   'name': Ack.string(),
///   'createdAt': Ack.codecs.isoStringToDateTime(),
/// });
/// ```
final class Codecs {
  const Codecs();

  /// `String <-> DateTime` via ISO 8601 (`DateTime.parse` / `toIso8601String`).
  ///
  /// Decoding accepts any string parseable by [DateTime.parse]. Encoding
  /// produces an ISO 8601 string that preserves UTC vs local information
  /// according to the source [DateTime].
  CodecSchema<String, DateTime> isoStringToDateTime() =>
      Ack.codec<String, DateTime>(
        Ack.string().datetime(),
        Ack.custom<DateTime>(),
        decode: DateTime.parse,
        encode: (d) => d.toIso8601String(),
      );

  /// `int <-> DateTime` via milliseconds since the Unix epoch.
  ///
  /// Decoding produces a UTC [DateTime] (`isUtc: true`); encoding goes via
  /// [DateTime.millisecondsSinceEpoch], which converts non-UTC inputs to
  /// their UTC equivalent under the hood. The boundary form is therefore
  /// always UTC, but a *local* [DateTime] passed to encode round-trips back
  /// as UTC — the local-vs-UTC marker is lost. Pass UTC values if you need
  /// strict instant identity across encode/decode.
  CodecSchema<int, DateTime> epochMillisToDateTime() =>
      Ack.codec<int, DateTime>(
        Ack.integer(),
        Ack.custom<DateTime>(),
        decode: (ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
        encode: (d) => d.millisecondsSinceEpoch,
      );

  /// `String <-> Uri` via [Uri.parse] / [Uri.toString].
  CodecSchema<String, Uri> stringToUri() => Ack.codec<String, Uri>(
    Ack.string().uri(),
    Ack.custom<Uri>(),
    decode: Uri.parse,
    encode: (u) => u.toString(),
  );

  /// `int <-> Duration` via milliseconds.
  CodecSchema<int, Duration> intMillisToDuration() => Ack.codec<int, Duration>(
    Ack.integer(),
    Ack.custom<Duration>(),
    decode: (ms) => Duration(milliseconds: ms),
    encode: (d) => d.inMilliseconds,
  );

  /// `String <-> int` via [int.parse] / `toString`.
  CodecSchema<String, int> stringToInt({int radix = 10}) =>
      Ack.codec<String, int>(
        Ack.string(),
        Ack.integer(),
        decode: (s) => int.parse(s, radix: radix),
        encode: (i) => i.toRadixString(radix),
      );

  /// `String <-> double` via [double.parse] / `toString`.
  ///
  /// Encoding rejects non-finite values ([double.nan], [double.infinity],
  /// [double.negativeInfinity]) because [double.parse] does not round-trip
  /// `'NaN'` (it returns a value that compares unequal to itself, which
  /// quietly breaks any equality-based check downstream). Pre-filter or
  /// substitute before encoding if you need to serialize them anyway.
  CodecSchema<String, double> stringToDouble() => Ack.codec<String, double>(
    Ack.string(),
    Ack.double(),
    decode: double.parse,
    encode: (d) {
      if (!d.isFinite) {
        throw FormatException('Cannot encode non-finite double: $d');
      }
      return d.toString();
    },
  );

  /// `String <-> BigInt` via [BigInt.parse] / `toString`.
  CodecSchema<String, BigInt> stringToBigInt({int radix = 10}) =>
      Ack.codec<String, BigInt>(
        Ack.string(),
        Ack.custom<BigInt>(),
        decode: (s) => BigInt.parse(s, radix: radix),
        encode: (b) => b.toRadixString(radix),
      );

  /// `String <-> T` via [jsonEncode] / [jsonDecode], with [schema] validating
  /// the decoded structure.
  ///
  /// **Single-pass validation:** the decoder casts the raw [jsonDecode] output
  /// to [T] for type-system satisfaction only. The real validation — including
  /// field presence, constraint checks, and path tracking — is performed by the
  /// codec's `outputSchema` (which is [schema]) in its normal
  /// `parseAndValidate` pass. Failures surface as the original [SchemaError]
  /// subclass with full `#/<field>` path information intact (e.g.
  /// `SchemaNestedError` wrapping per-field constraint errors).
  ///
  /// This means a missing required field produces a structured error at
  /// `#/<fieldName>` rather than a flat [SchemaTransformError] wrapping a
  /// [FormatException].
  CodecSchema<String, T> json<T extends Object>(AckSchema<T> schema) =>
      Ack.codec<String, T>(
        Ack.string(),
        schema,
        decode: (s) {
          final raw = jsonDecode(s);
          if (raw is T) return raw;
          if (raw is Map) return raw.cast<String, Object?>() as T;
          if (raw is List) return raw.cast<Object?>() as T;
          return raw as T;
        },
        encode: (v) => jsonEncode(v),
      );
}
