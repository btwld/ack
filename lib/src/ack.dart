import 'schemas/schema.dart';

final class Ack {
  static const string = StringSchema();

  static const boolean = BooleanSchema();

  static const int = IntegerSchema();

  static const double = DoubleSchema();

  const Ack._();

  static ListSchema<T> list<T extends Object, S extends Schema<T>>(S schema) {
    return ListSchema<T>(schema);
  }

  static DiscriminatedObjectSchema discriminated({
    required String discriminatorKey,
    required Map<String, ObjectSchema> schemas,
  }) {
    return DiscriminatedObjectSchema(
      discriminatorKey: discriminatorKey,
      schemas: schemas,
    );
  }

  static ObjectSchema object(
    Map<String, Schema> properties, {
    bool additionalProperties = false,
    List<String> required = const [],
  }) {
    return ObjectSchema(
      properties,
      additionalProperties: additionalProperties,
      required: required,
    );
  }

  static StringSchema enumString(List<String> values) {
    return StringSchema(constraints: [EnumStringValidator(values)]);
  }

  static StringSchema enumValues(List<Enum> values) {
    return enumString(values.map((e) => e.name).toList());
  }
}
