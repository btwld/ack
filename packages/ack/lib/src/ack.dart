import 'schemas/schema.dart';

/// The main entry point for creating schemas with the Ack validation library.
///
/// Provides a fluent API for creating various schema types.
final class Ack {
  /// Creates a string schema.
  static StringSchema string() => const StringSchema();

  /// Creates an integer schema.
  static IntegerSchema integer() => const IntegerSchema();

  /// Creates a double schema.
  static DoubleSchema double() => const DoubleSchema();

  /// Creates a boolean schema.
  static BooleanSchema boolean() => const BooleanSchema();

  /// Creates an object schema with the given properties.
  static ObjectSchema object(
    Map<String, AckSchema> properties, {
    List<String> requiredProperties = const [],
    bool allowAdditionalProperties = false,
  }) =>
      ObjectSchema(
        properties.cast(),
        requiredProperties: requiredProperties,
        allowAdditionalProperties: allowAdditionalProperties,
      );

  /// Creates a discriminated object schema for polymorphic validation.
  static DiscriminatedObjectSchema discriminatedObject({
    required String discriminatorKey,
    required Map<String, ObjectSchema> subSchemas,
  }) =>
      DiscriminatedObjectSchema(
        discriminatorKey: discriminatorKey,
        subSchemas: subSchemas,
      );

  /// Creates a list schema with the given item schema.
  static ListSchema<T> list<T extends Object>(AckSchema<T> itemSchema) =>
      ListSchema(itemSchema);

  /// Creates an enum schema for validating enum values.
  static EnumSchema<T> enumValues<T extends Enum>(List<T> values) =>
      EnumSchema(values: values);

  /// Creates a schema that can be one of many types.
  static AnyOfSchema anyOf(List<AckSchema> schemas) => AnyOfSchema(schemas);
}
