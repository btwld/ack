import 'common_types.dart';
import 'constraints/pattern_constraint.dart';
import 'constraints/string_literal_constraint.dart';
import 'schemas/extensions/ack_schema_extensions.dart';
import 'schemas/extensions/string_schema_extensions.dart';
import 'schemas/schema.dart';

/// The main entry point for creating schemas with the Ack validation library.
final class Ack {
  /// Compiles a decoded draft 2020-12 JSON Schema into an ACK validator.
  ///
  /// [document] must be a map or boolean, not a JSON string. Referenced
  /// [documents] are supplied by retrieval URI; no files or URLs are fetched.
  /// Unsupported semantics throw [JsonSchemaImportException].
  static AckSchema<Object, Object> fromJsonSchema(
    Object document, {
    Uri? baseUri,
    Map<Uri, Object> documents = const {},
  }) => ImportedJsonSchema.fromDocument(
    document,
    baseUri: baseUri,
    documents: documents,
  );

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

  /// Creates a schema for a JSON object with arbitrary string keys whose
  /// values all match [valueSchema].
  ///
  /// Use `Ack.map(Ack.any())` for a JSON object of non-null JSON-safe values
  /// and `Ack.map(Ack.any().nullable())` for a `JsonMap` whose values may be
  /// `null`. Use [object] when the object has declared properties.
  static MapSchema<B, R> map<B extends Object, R extends Object>(
    AckSchema<B, R> valueSchema,
  ) => MapSchema<B, R>(valueSchema);

  /// Creates an enum schema for validating enum values.
  static EnumSchema<T> enumValues<T extends Enum>(List<T> values) {
    _requireNonEmpty(values, 'values');
    _requireUniqueBy(values, 'values', (value) => value.name);
    return EnumSchema(values: List.unmodifiable(values));
  }

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
      enumValues(values).codec<T>(decode: _identity, encode: _identity);

  /// Creates a string schema that only accepts one of the given [values].
  static StringSchema enumString(List<String> values) {
    _requireNonEmpty(values, 'values');
    _requireUniqueBy(values, 'values', (value) => value);
    return string().withConstraint(
      PatternConstraint.enumString(List.unmodifiable(values)),
    );
  }

  /// Creates a schema that can be one of many types.
  static AnyOfSchema anyOf(List<AnyAckSchema> schemas) {
    _requireNonEmpty(schemas, 'schemas');
    return AnyOfSchema(List.unmodifiable(schemas));
  }

  /// Creates a schema that accepts any non-null JSON-safe value.
  ///
  /// Accepted values are finite numbers, strings, booleans, string-keyed maps,
  /// and lists recursively composed from those values. Mark the schema nullable
  /// to accept `null`. Parsing returns a detached, recursively unmodifiable
  /// snapshot of the input.
  static AnySchema any() => const AnySchema();

  /// Validates with [schema] while returning the original boundary value.
  ///
  /// Nested codecs still run for validation, but their decoded runtime values
  /// are discarded. This keeps wire data composable with a later typed parse.
  static BoundarySchema<Boundary> preserveBoundary<
    Boundary extends Object,
    Runtime extends Object
  >(AckSchema<Boundary, Runtime> schema) {
    return BoundarySchema<Boundary>(schema);
  }

  /// Creates a schema reference that is resolved lazily on first use.
  ///
  /// The [builder] is called once and memoized. [maxDepth] bounds how many
  /// times this lazy schema may recur in its active context chain before
  /// parsing, runtime validation, or encoding fails; it defaults to
  /// [LazySchema.defaultMaxDepth] and must be at least `1`. Two `Ack.lazy`
  /// instances are equal only when their `builder` closure is the same
  /// reference -- pulling the closure into a `final` variable lets two calls
  /// share equality.
  ///
  /// `toJsonSchema()` and `toSchemaModel()` export lazy references through
  /// recursive `definitions`/`$ref` JSON Schema definitions. Bare or wrapped
  /// `Ack.lazy` schemas cannot be used as discriminated union branches. The
  /// `maxDepth` check is a runtime-only constraint that cannot be expressed
  /// through a `$ref`, so exported schema models warn that it was omitted.
  static LazySchema<Boundary, Runtime>
  lazy<Boundary extends Object, Runtime extends Object>(
    String name,
    AckSchema<Boundary, Runtime> Function() builder, {
    int maxDepth = LazySchema.defaultMaxDepth,
  }) {
    return LazySchema<Boundary, Runtime>(name, builder, maxDepth: maxDepth);
  }

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
  /// Announced RFC 3339 leap seconds are valid for `Ack.string().datetime()`,
  /// but this codec rejects them because Dart normalizes `:60` to the following
  /// minute instead of preserving the instant's textual representation.
  ///
  /// Runtime invariant: the encoded `DateTime` must be UTC. Local-time
  /// values fail validation; convert with `.toUtc()` before encoding.
  static CodecSchema<String, DateTime> datetime() {
    return CodecSchema.create<String, String, DateTime>(
      inputSchema: string().datetime().refine(
        isDateTimeSecondRepresentableByDart,
        message: 'Dart DateTime cannot represent leap seconds.',
      ),
      outputSchema: InstanceSchema<DateTime>().refine(
        _isUtcDateTime,
        message: 'Expected a UTC DateTime.',
      ),
      decoder: _decodeIso8601DateTime,
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
        _isAbsoluteUri,
        message: 'Expected an absolute URI with scheme and host.',
      ),
      decoder: Uri.parse,
      encoder: _encodeUri,
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
        _isWholeMillisecondDuration,
        message: 'Expected a whole-millisecond Duration.',
      ),
      decoder: _decodeDuration,
      encoder: _encodeDuration,
      // `DurationConstraint` renders milliseconds, which is exactly this
      // codec's boundary, so `.min()`/`.max()` stay true on the wire.
      projectsConstraintsToBoundary: true,
    );
  }
}

T _identity<T extends Object>(T value) => value;

bool _isLocalMidnightDate(DateTime value) {
  if (value.isUtc) return false;
  return value.hour == 0 &&
      value.minute == 0 &&
      value.second == 0 &&
      value.millisecond == 0 &&
      value.microsecond == 0;
}

bool _isUtcDateTime(DateTime value) => value.isUtc;

bool _isAbsoluteUri(Uri value) => value.hasScheme && value.host.isNotEmpty;

String _encodeUri(Uri value) => value.toString();

bool _isWholeMillisecondDuration(Duration value) {
  return value.inMicroseconds % Duration.microsecondsPerMillisecond == 0;
}

Duration _decodeDuration(int milliseconds) {
  return Duration(milliseconds: milliseconds);
}

int _encodeDuration(Duration value) => value.inMilliseconds;

String _encodeIsoDate(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _encodeIsoDateTime(DateTime value) {
  return value.toIso8601String();
}

DateTime _decodeIso8601DateTime(String value) {
  // The input schema accepts RFC 3339's lowercase `t`/`z` separators, but
  // `DateTime.parse` only accepts the uppercase forms. Normalize so the codec
  // decodes every string its own format validation admitted. The value is
  // already known to match the ISO 8601 pattern, whose only letters are these
  // separators, so upper-casing cannot corrupt any other field.
  return DateTime.parse(value.toUpperCase());
}

List<T> _requireNonEmpty<T>(List<T> values, String name) {
  if (values.isEmpty) {
    throw ArgumentError.value(values, name, 'Must not be empty.');
  }
  return values;
}

List<T> _requireUniqueBy<T, K>(
  List<T> values,
  String name,
  K Function(T) keyOf,
) {
  if (values.map(keyOf).toSet().length != values.length) {
    throw ArgumentError.value(values, name, 'Must be unique.');
  }
  return values;
}
