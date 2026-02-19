import 'common_types.dart';
import 'constraints/pattern_constraint.dart';
import 'constraints/string_literal_constraint.dart';
import 'schemas/extensions/ack_schema_extensions.dart';
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
  static DiscriminatedObjectSchema discriminated({
    required String discriminatorKey,
    required Map<String, AckSchema<MapValue>> schemas,
  }) => DiscriminatedObjectSchema(
    discriminatorKey: discriminatorKey,
    schemas: schemas,
  );

  /// Creates a list schema with the given item schema.
  static ListSchema<T> list<T extends Object>(AckSchema<T> itemSchema) =>
      ListSchema(itemSchema);

  /// Creates an enum schema for validating enum values.
  static EnumSchema<T> enumValues<T extends Enum>(List<T> values) =>
      EnumSchema(values: values);

  static StringSchema enumString(List<String> values) =>
      string().withConstraint(PatternConstraint.enumString(values));

  /// Creates a schema that can be one of many types.
  static AnyOfSchema anyOf(List<AckSchema> schemas) => AnyOfSchema(schemas);

  /// Creates a schema that accepts any value without type conversion or validation.
  /// Useful for dynamic content or when you need maximum flexibility.
  static AnySchema any() => const AnySchema();

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
  static TransformedSchema<String, DateTime> date() {
    return string()
        .date() // Validates ISO 8601 date format (YYYY-MM-DD) first
        .transform<DateTime>((s) => DateTime.parse(s!));
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
  static TransformedSchema<String, DateTime> datetime() {
    return string()
        .datetime() // Validates ISO 8601 datetime format with timezone first
        .transform<DateTime>((s) => DateTime.parse(s!));
  }
}
