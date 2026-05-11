import 'constraints/pattern_constraint.dart';
import 'constraints/string_literal_constraint.dart';
import 'schemas/extensions/string_schema_extensions.dart';
import 'schemas/schema.dart';

/// The main entry point for creating schemas with the Ack validation library.
///
/// Provides a fluent API for creating various schema types.
final class Ack {
  /// Creates a string schema.
  static StringSchema string() => const StringSchema();

  /// Creates a string schema that only accepts the exact [value].
  static StringSchema literal(String value) =>
      string().withConstraint(StringLiteralConstraint(value));

  /// Creates an integer schema.
  static IntegerSchema integer() => const IntegerSchema();

  /// Creates a double schema.
  static DoubleSchema double() => const DoubleSchema();

  /// Creates a boolean schema.
  static BooleanSchema boolean() => const BooleanSchema();

  /// Creates an object schema with the given properties.
  /// All properties are required by default unless wrapped with .optional().
  static ObjectSchema object(
    Map<String, AckSchema> properties, {
    bool additionalProperties = false,
  }) => ObjectSchema(properties, additionalProperties: additionalProperties);

  /// Creates a discriminated object schema for polymorphic validation.
  static DiscriminatedObjectSchema<T> discriminated<T extends Object>({
    required String discriminatorKey,
    required Map<String, AckSchema<T>> schemas,
  }) => DiscriminatedObjectSchema<T>(
    discriminatorKey: discriminatorKey,
    schemas: schemas,
  );

  /// Creates a list schema with the given item schema.
  static ListSchema<T> list<T extends Object>(AckSchema<T> itemSchema) =>
      ListSchema(itemSchema);

  /// Creates an enum schema for validating enum values.
  static EnumSchema<T> enumValues<T extends Enum>(List<T> values) =>
      EnumSchema(values: values);

  /// Creates a string schema that only accepts one of the given [values].
  static StringSchema enumString(List<String> values) =>
      string().withConstraint(PatternConstraint.enumString(values));

  /// Creates a schema that can be one of many types.
  static AnyOfSchema anyOf(List<AckSchema> schemas) => AnyOfSchema(schemas);

  /// Creates a schema that accepts any value without type conversion or validation.
  /// Useful for dynamic content or when you need maximum flexibility.
  static AnySchema any() => const AnySchema();

  /// Creates a schema describing a runtime value of type [T].
  ///
  /// Most useful as the `output` of [Ack.codec], where the runtime form is
  /// a non-JSON Dart class (e.g. `DateTime`, `Uri`, `Duration`, or a user
  /// class). Standalone, it accepts any [T] on parse/encode and has no
  /// meaningful JSON Schema form.
  static InstanceSchema<T> instance<T extends Object>() => InstanceSchema<T>();

  /// Creates a bidirectional codec between [input] (boundary form, type [I])
  /// and [output] (runtime form, type [O]).
  ///
  /// [decoder] (`I → O`) runs on parse; [encoder] (`O → I`) runs on encode.
  /// Both are required; this factory is the bidirectional construction. For
  /// parse-only conversion, call `schema.transform(...)` on a schema instead.
  ///
  /// Naming follows `dart:convert`: methods are verbs (`encode` / `decode`),
  /// the function-typed fields holding them are nouns ([encoder] /
  /// [decoder]).
  ///
  /// ```dart
  /// final intFromString = Ack.codec<String, int>(
  ///   input: Ack.string().matches(r'^-?\d+$'),
  ///   output: Ack.instance<int>(),
  ///   decoder: int.parse,
  ///   encoder: (value) => value.toString(),
  /// );
  /// intFromString.parse('42');  // → 42
  /// intFromString.encode(42);   // → '42'
  /// ```
  static CodecSchema<I, O> codec<I extends Object, O extends Object>({
    required AckSchema<I> input,
    required AckSchema<O> output,
    required O Function(I) decoder,
    required I Function(O) encoder,
  }) {
    return CodecSchema<I, O>(
      inputSchema: input,
      outputSchema: output,
      decoder: decoder,
      encoder: encoder,
    );
  }

  /// Creates a calendar-date codec.
  ///
  /// **Boundary form:** ISO 8601 date string `YYYY-MM-DD`.
  /// **Runtime form:** local-midnight [DateTime].
  ///
  /// On encode the value must be a **local** [DateTime] at midnight — dates
  /// are calendar dates, not instants. A UTC [DateTime] or a value with any
  /// non-zero time component is rejected with [SchemaEncodeError]. The error
  /// does not suggest `.toUtc()`; for instants/timestamps use [datetime]
  /// instead.
  ///
  /// You can add range constraints using `.min()` and `.max()`.
  ///
  /// ```dart
  /// final schema = Ack.date();
  /// schema.parse('2025-06-15');                 // → DateTime(2025, 6, 15)
  /// schema.encode(DateTime(2025, 6, 15));       // → '2025-06-15'
  /// schema.encode(DateTime.utc(2025, 6, 15));   // → SchemaEncodeError
  /// ```
  static CodecSchema<String, DateTime> date() {
    return Ack.codec<String, DateTime>(
      input: string().date(), // Validates ISO 8601 date format (YYYY-MM-DD).
      output: Ack.instance<DateTime>(),
      decoder: DateTime.parse,
      encoder: _encodeDateOnly,
    );
  }

  /// Creates an instant/timestamp codec.
  ///
  /// **Boundary form:** ISO 8601 datetime string with timezone.
  /// **Runtime form:** UTC [DateTime].
  ///
  /// On encode the value must be UTC. A non-UTC [DateTime] is rejected with
  /// [SchemaEncodeError]; the error advises calling `value.toUtc()` to
  /// canonicalize. Range constraints can be applied with `.min()` and
  /// `.max()`.
  ///
  /// ```dart
  /// final schema = Ack.datetime();
  /// schema.parse('2025-06-15T10:30:00Z');     // → DateTime.utc(...)
  /// schema.encode(DateTime.utc(2025, 6, 15)); // → '2025-06-15T00:00:00.000Z'
  /// schema.encode(DateTime(2025, 6, 15));     // → SchemaEncodeError
  /// ```
  static CodecSchema<String, DateTime> datetime() {
    return Ack.codec<String, DateTime>(
      input: string().datetime(), // ISO 8601 datetime with timezone.
      output: Ack.instance<DateTime>(),
      decoder: DateTime.parse,
      encoder: _encodeUtcDateTime,
    );
  }

  /// Creates a codec for absolute URIs.
  ///
  /// **Boundary form:** absolute URI string with scheme and authority
  /// (e.g. `https://example.com/path`). URIs without an authority
  /// component (e.g. `mailto:` or `urn:`) are rejected on both parse
  /// and encode.
  /// **Runtime form:** [Uri].
  ///
  /// ```dart
  /// final schema = Ack.uri();
  /// schema.parse('https://example.com/path?x=1'); // → Uri
  /// schema.encode(Uri.parse('https://example.com')); // → 'https://example.com'
  /// schema.encode(Uri.parse('/relative')); // → SchemaEncodeError
  /// ```
  static CodecSchema<String, Uri> uri() {
    return Ack.codec<String, Uri>(
      input: string().uri(), // Validates URI format on parse.
      output: Ack.instance<Uri>(),
      decoder: Uri.parse,
      encoder: _encodeAbsoluteUri,
    );
  }

  /// Creates a codec for [Duration] values represented as integer
  /// milliseconds at the boundary.
  ///
  /// **Boundary form:** `int` (milliseconds).
  /// **Runtime form:** [Duration].
  ///
  /// On encode the duration must be representable as a whole number of
  /// milliseconds — sub-millisecond components (microseconds) are
  /// rejected rather than silently truncated, so encoded round-trips are
  /// honest. You can add range constraints using `.min()` and `.max()`.
  ///
  /// ```dart
  /// Ack.duration().encode(const Duration(milliseconds: 1500)); // → 1500
  /// Ack.duration().encode(const Duration(microseconds: 1501)); // → SchemaEncodeError
  /// ```
  static CodecSchema<int, Duration> duration() {
    return Ack.codec<int, Duration>(
      input: integer(),
      output: Ack.instance<Duration>(),
      decoder: (ms) => Duration(milliseconds: ms),
      encoder: _encodeWholeMilliseconds,
    );
  }
}

// ---------------------------------------------------------------------------
// Built-in codec encoders.
//
// Encoders throw [ArgumentError] on policy violations.
// [CodecSchema.encodeBoundary] catches the throw and wraps it in
// [SchemaEncodeError.encoderThrew], preserving the "safeEncode never throws"
// guarantee.
// ---------------------------------------------------------------------------

/// Encodes a local-midnight [DateTime] into a `YYYY-MM-DD` string.
/// Rejects UTC values (use [Ack.datetime] for instants) and any value
/// with non-zero time components.
String _encodeDateOnly(DateTime value) {
  if (value.isUtc) {
    throw ArgumentError.value(
      value,
      'value',
      'Ack.date() can only encode local DateTime values. '
          'Use Ack.datetime() for UTC instants/timestamps.',
    );
  }
  if (value.hour != 0 ||
      value.minute != 0 ||
      value.second != 0 ||
      value.millisecond != 0 ||
      value.microsecond != 0) {
    throw ArgumentError.value(
      value,
      'value',
      'Ack.date() can only encode DateTime values at midnight.',
    );
  }
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Encodes a UTC [DateTime] to its canonical ISO 8601 string. Rejects
/// non-UTC values; the error message advises calling `.toUtc()`.
String _encodeUtcDateTime(DateTime value) {
  if (!value.isUtc) {
    throw ArgumentError.value(
      value,
      'value',
      'Ack.datetime() can only encode UTC DateTime values. '
          'Call value.toUtc() to canonicalize.',
    );
  }
  return value.toIso8601String();
}

/// Encodes an absolute [Uri] to its string form. Rejects URIs that are
/// missing scheme or authority (e.g. relative URIs, `mailto:`, `urn:`).
String _encodeAbsoluteUri(Uri value) {
  if (!value.hasScheme || !value.hasAuthority) {
    throw ArgumentError.value(
      value,
      'value',
      'Ack.uri() can only encode absolute URIs with scheme and authority.',
    );
  }
  return value.toString();
}

/// Encodes a [Duration] as whole milliseconds. Rejects durations with
/// sub-millisecond precision rather than silently truncating microseconds.
int _encodeWholeMilliseconds(Duration value) {
  if (value.inMicroseconds % Duration.microsecondsPerMillisecond != 0) {
    throw ArgumentError.value(
      value,
      'value',
      'Ack.duration() can only encode whole-millisecond durations.',
    );
  }
  return value.inMilliseconds;
}
