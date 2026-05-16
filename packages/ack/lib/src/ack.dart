import 'common_types.dart';
import 'constraints/pattern_constraint.dart';
import 'constraints/string_literal_constraint.dart';
import 'schemas/extensions/string_schema_extensions.dart';
import 'schemas/schema.dart';

/// The main entry point for creating schemas with the Ack validation library.
///
/// Provides a fluent API for creating various schema types.
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
    Map<String, AckSchema> properties, {
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

  /// Creates a list schema with the given item schema.
  static ListSchema<B, R> list<B extends Object, R extends Object>(
    AckSchema<B, R> itemSchema,
  ) => ListSchema<B, R>(itemSchema);

  /// Creates an enum schema for validating enum values.
  static EnumSchema<T> enumValues<T extends Enum>(List<T> values) =>
      EnumSchema(values: values);

  /// Creates a string schema that only accepts one of the given [values].
  static StringSchema enumString(List<String> values) =>
      string().withConstraint(PatternConstraint.enumString(values));

  /// Creates a schema that can be one of many types.
  static AnyOfSchema anyOf(List<AckSchema> schemas) => AnyOfSchema(schemas);

  /// Creates a schema that accepts any non-null value.
  static AnySchema any() => const AnySchema();

  /// Creates a schema for a specific Dart instance type [T], with [T] as both
  /// boundary and runtime type.
  static InstanceSchema<T> instance<T extends Object>() =>
      InstanceSchema<T>();

  /// Creates a universal codec from an [input] schema, with a [decode]
  /// function and an [encode] function.
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
    return CodecSchemaImpl<Boundary, InputRuntime, Runtime>(
      inputSchema: input,
      outputSchema: output ?? InstanceSchema<Runtime>(),
      decoder: decode,
      encoder: encode,
    );
  }

  /// Creates a bidirectional date schema that parses ISO 8601 date strings
  /// (YYYY-MM-DD) into [DateTime] objects (local midnight) and encodes
  /// [DateTime] back to the YYYY-MM-DD form.
  static CodecSchema<String, DateTime> date() {
    return CodecSchemaImpl<String, String, DateTime>(
      inputSchema: string().date(),
      outputSchema: InstanceSchema<DateTime>(),
      decoder: DateTime.parse,
      encoder: _encodeIsoDate,
    );
  }

  /// Creates a bidirectional datetime schema that parses ISO 8601 datetime
  /// strings into [DateTime] objects (UTC) and encodes [DateTime] back to
  /// ISO 8601 form.
  static CodecSchema<String, DateTime> datetime() {
    return CodecSchemaImpl<String, String, DateTime>(
      inputSchema: string().datetime(),
      outputSchema: InstanceSchema<DateTime>(),
      decoder: DateTime.parse,
      encoder: _encodeIsoDateTime,
    );
  }

  /// Creates a bidirectional URI schema.
  static CodecSchema<String, Uri> uri() {
    return CodecSchemaImpl<String, String, Uri>(
      inputSchema: string().uri(),
      outputSchema: InstanceSchema<Uri>(),
      decoder: Uri.parse,
      encoder: (value) => value.toString(),
    );
  }

  /// Creates a bidirectional duration schema that parses milliseconds into
  /// [Duration] objects.
  static CodecSchema<int, Duration> duration() {
    return CodecSchemaImpl<int, int, Duration>(
      inputSchema: integer(),
      outputSchema: InstanceSchema<Duration>(),
      decoder: (ms) => Duration(milliseconds: ms),
      encoder: (value) => value.inMilliseconds,
    );
  }
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
