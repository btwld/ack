import 'common_types.dart';
import 'constraints/pattern_constraint.dart';
import 'constraints/string_literal_constraint.dart';
import 'schemas/extensions/ack_schema_extensions.dart';
import 'schemas/extensions/string_schema_extensions.dart';
import 'schemas/schema.dart';

/// The main entry point for creating schemas with the Ack validation library.
final class Ack {
  /// Creates a string schema. Boundary and runtime are both `String`.
  static StringSchema string() => const StringSchema();

  /// Creates a literal string schema that only accepts the exact [value].
  static StringSchema literal(String value) =>
      string().withConstraint(StringLiteralConstraint(value));

  /// Creates an integer schema. Boundary and runtime are both `int`.
  static IntegerSchema integer() => const IntegerSchema();

  /// Creates a double schema. Boundary and runtime are both `double`.
  static DoubleSchema double() => const DoubleSchema();

  /// Creates a number schema. Boundary and runtime are both `num`.
  static NumberSchema number() => const NumberSchema();

  /// Creates a boolean schema. Boundary and runtime are both `bool`.
  static BooleanSchema boolean() => const BooleanSchema();

  /// Creates an object schema with the given properties.
  static ObjectSchema object(
    Map<String, AnyAckSchema> properties, {
    bool additionalProperties = false,
  }) => ObjectSchema(properties, additionalProperties: additionalProperties);

  /// Creates a discriminated object schema for polymorphic validation.
  static DiscriminatedObjectSchema<T> discriminated<T extends Object>({
    required String discriminatorKey,
    required Map<String, AckSchema<JsonMap, T>> schemas,
  }) => DiscriminatedObjectSchema<T>(
    discriminatorKey: discriminatorKey,
    schemas: schemas,
  );

  /// Creates a list schema with the given non-nullable item schema.
  ///
  /// `Ack.list(...)` models JSON arrays whose items are present values. Use
  /// `Ack.any()` for mixed JSON values. Nullable list items are intentionally
  /// rejected.
  static ListSchema<B, R> list<B extends Object, R extends Object>(
    AckSchema<B, R> itemSchema,
  ) => ListSchema<B, R>(itemSchema);

  /// Creates an enum schema for validating enum values.
  static EnumSchema<T> enumValues<T extends Enum>(List<T> values) =>
      EnumSchema(values: values);

  /// Creates a bidirectional codec for Dart enums, with boundary `String` and
  /// runtime [T].
  ///
  /// This is a thin wrapper around [enumValues] that returns a
  /// [CodecSchema] instead of an [EnumSchema], for uniform composition with
  /// other codecs (e.g. when assembling a registry of `CodecSchema` values
  /// for many value shapes). The decode and encode functions are identity
  /// because [EnumSchema] already maps between [T] and the enum's `.name`.
  ///
  /// Prefer [enumValues] when you need [EnumSchema]-specific affordances
  /// (e.g. adding constraints, copying with new flags). Prefer [enumCodec]
  /// when downstream code expects every value-shape to be a `CodecSchema`.
  static CodecSchema<String, T> enumCodec<T extends Enum>(List<T> values) =>
      enumValues(values).codec<T>(
        decode: (value) => value,
        encode: (value) => value,
      );

  /// Creates a string schema that only accepts one of the given [values].
  static StringSchema enumString(List<String> values) =>
      string().withConstraint(PatternConstraint.enumString(values));

  /// Creates a schema that can be one of many types.
  static AnyOfSchema anyOf(List<AnyAckSchema> schemas) => AnyOfSchema(schemas);

  /// Creates a schema that accepts any non-null JSON-safe value.
  ///
  /// Accepted values are finite numbers, strings, booleans, string-keyed maps,
  /// and lists recursively composed from those values. Mark the schema nullable
  /// to accept `null`.
  static AnySchema any() => const AnySchema();

  /// Creates a schema for a specific Dart instance type [T], with [T] as
  /// both boundary and runtime type.
  static InstanceSchema<T> instance<T extends Object>() => InstanceSchema<T>();

  /// Creates a universal codec from an [input] schema, with a [decode]
  /// function and an [encode] function. The optional [output] schema
  /// applies runtime-side invariants.
  static CodecSchema<Boundary, Runtime> codec<
    Boundary extends Object,
    InputRuntime extends Object,
    Runtime extends Object
  >({
    required AckSchema<Boundary, InputRuntime> input,
    required Runtime Function(InputRuntime value) decode,
    required InputRuntime Function(Runtime value) encode,
    AckSchema<dynamic, Runtime>? output,
  }) {
    return CodecSchema.create<Boundary, InputRuntime, Runtime>(
      inputSchema: input,
      outputSchema: output ?? InstanceSchema<Runtime>(),
      decoder: decode,
      encoder: encode,
      isOptional: input.isOptional,
      isNullable: input.isNullable,
    );
  }

  /// Bidirectional date codec: ISO 8601 `YYYY-MM-DD` strings ↔ local
  /// midnight `DateTime` runtime values.
  ///
  /// Runtime invariant: the encoded `DateTime` must be local midnight
  /// (year/month/day only). Values with non-zero time-of-day fail
  /// `safeEncode` and `validateRuntimeWithContext`.
  static CodecSchema<String, DateTime> date() {
    return CodecSchema.create<String, String, DateTime>(
      inputSchema: string().date(),
      outputSchema: InstanceSchema<DateTime>().refine(
        _isLocalMidnightDate,
        message: 'Expected a local DateTime at midnight (00:00:00.000).',
      ),
      decoder: DateTime.parse,
      encoder: _encodeIsoDate,
    );
  }

  /// Bidirectional datetime codec: ISO 8601 datetime strings ↔ UTC
  /// `DateTime` runtime values.
  ///
  /// Runtime invariant: the encoded `DateTime` must be UTC. Local-time
  /// values fail validation; convert with `.toUtc()` before encoding.
  static CodecSchema<String, DateTime> datetime() {
    return CodecSchema.create<String, String, DateTime>(
      inputSchema: string().datetime(),
      outputSchema: InstanceSchema<DateTime>().refine(
        (value) => value.isUtc,
        message: 'Expected a UTC DateTime.',
      ),
      decoder: DateTime.parse,
      encoder: _encodeIsoDateTime,
    );
  }

  /// Bidirectional URI codec.
  ///
  /// Runtime invariant: the `Uri` must have both a scheme and a host
  /// (matching the parse-side predicate).
  static CodecSchema<String, Uri> uri() {
    return CodecSchema.create<String, String, Uri>(
      inputSchema: string().uri(),
      outputSchema: InstanceSchema<Uri>().refine(
        (u) => u.hasScheme && u.host.isNotEmpty,
        message: 'Expected an absolute URI with scheme and host.',
      ),
      decoder: Uri.parse,
      encoder: (value) => value.toString(),
    );
  }

  /// Bidirectional duration codec: milliseconds ↔ `Duration`.
  ///
  /// Runtime invariant: the `Duration` must be a whole number of
  /// milliseconds (sub-millisecond precision is rejected to avoid silent
  /// truncation on encode).
  static CodecSchema<int, Duration> duration() {
    return CodecSchema.create<int, int, Duration>(
      inputSchema: integer(),
      outputSchema: InstanceSchema<Duration>().refine(
        (value) =>
            value.inMicroseconds % Duration.microsecondsPerMillisecond == 0,
        message: 'Expected a whole-millisecond Duration.',
      ),
      decoder: (ms) => Duration(milliseconds: ms),
      encoder: (value) => value.inMilliseconds,
    );
  }
}

bool _isLocalMidnightDate(DateTime value) {
  if (value.isUtc) return false;
  return value.hour == 0 &&
      value.minute == 0 &&
      value.second == 0 &&
      value.millisecond == 0 &&
      value.microsecond == 0;
}

String _encodeIsoDate(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _encodeIsoDateTime(DateTime value) {
  return value.toIso8601String();
}
