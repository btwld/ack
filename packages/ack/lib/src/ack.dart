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

  /// Creates a literal string schema that only accepts the exact [value].
  /// Similar to Zod's `z.literal("value")`.
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

  /// Creates a schema that validates a runtime value is an instance of [T].
  ///
  /// Useful as the runtime/output side of a codec for domain objects ACK does
  /// not structurally validate.
  static InstanceSchema<T> instance<T extends Object>() => InstanceSchema<T>();

  /// Creates a bidirectional codec between a boundary type [I] and a runtime
  /// type [O].
  ///
  /// `parse` validates the input via [inputSchema], runs [decode], then
  /// validates the result via [outputSchema]. `encode` is the inverse:
  /// validate via [outputSchema], run [encode], validate via [inputSchema].
  ///
  /// Use `.transform(fn)` instead when only the parse direction is needed —
  /// it produces a one-way codec whose `encode` fails clearly.
  ///
  /// Example:
  /// ```dart
  /// final dateCodec = Ack.codec<String, DateTime>(
  ///   Ack.string().datetime(),
  ///   Ack.instance<DateTime>(),
  ///   decode: DateTime.parse,
  ///   encode: (d) => d.toIso8601String(),
  /// );
  /// ```
  static CodecSchema<I, O> codec<I extends Object, O extends Object>(
    AckSchema<I> inputSchema,
    AckSchema<O> outputSchema, {
    required O Function(I value) decode,
    required I Function(O value) encode,
  }) => CodecSchema<I, O>(
    inputSchema: inputSchema,
    outputSchema: outputSchema,
    decoder: decode,
    encoder: encode,
  );

  /// Creates a date schema that parses ISO 8601 date strings (YYYY-MM-DD) into DateTime objects.
  ///
  /// The schema validates the string format before transformation, ensuring only valid
  /// date strings are parsed. You can add range constraints using [.min()] and [.max()].
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.date();
  /// final result = schema.parse("2025-06-15"); // Returns DateTime(2025, 6, 15)
  ///
  /// // With range validation
  /// final futureDate = Ack.date().min(DateTime.now());
  /// final year2025 = Ack.date()
  ///   .min(DateTime(2025, 1, 1))
  ///   .max(DateTime(2025, 12, 31));
  /// ```
  static CodecSchema<String, DateTime> date() {
    return Ack.codec<String, DateTime>(
      string().date(), // Validates ISO 8601 date format (YYYY-MM-DD) first
      Ack.instance<DateTime>(),
      decode: DateTime.parse,
      encode: (d) =>
          '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}',
    );
  }

  /// Creates a datetime schema that parses ISO 8601 datetime strings into DateTime objects.
  ///
  /// The schema validates the string format (including timezone) before transformation.
  /// You can add range constraints using [.min()] and [.max()].
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.datetime();
  /// final result = schema.parse("2025-06-15T10:30:00Z"); // Returns DateTime
  ///
  /// // With range validation
  /// final appointmentSchema = Ack.datetime().min(DateTime.now());
  /// ```
  static CodecSchema<String, DateTime> datetime() {
    return Ack.codec<String, DateTime>(
      string().datetime(), // Validates ISO 8601 datetime with timezone first
      Ack.instance<DateTime>(),
      decode: DateTime.parse,
      encode: (d) => d.toUtc().toIso8601String(),
    );
  }

  /// Creates a schema that parses URI strings into [Uri] objects.
  ///
  /// The schema validates that the string is an absolute URI with a scheme
  /// and host (e.g., `https://example.com`) before transformation. URIs
  /// without an authority component (e.g., `mailto:` or `urn:`) are rejected.
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.uri();
  /// final result = schema.parse('https://example.com/path?x=1');
  /// ```
  static CodecSchema<String, Uri> uri() {
    return Ack.codec<String, Uri>(
      string().uri(), // Validates URI format first
      Ack.instance<Uri>(),
      decode: Uri.parse,
      encode: (u) => u.toString(),
    );
  }

  /// Creates a schema that parses millisecond integers into [Duration] objects.
  ///
  /// You can add range constraints using [.min()] and [.max()].
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.duration();
  /// final result = schema.parse(1500); // Returns Duration(milliseconds: 1500)
  ///
  /// // With range validation
  /// final timeout = Ack.duration().min(Duration(minutes: 1)).max(Duration(minutes: 2));
  /// ```
  static CodecSchema<int, Duration> duration() {
    return Ack.codec<int, Duration>(
      integer(),
      Ack.instance<Duration>(),
      decode: (ms) => Duration(milliseconds: ms),
      encode: (d) => d.inMilliseconds,
    );
  }
}
