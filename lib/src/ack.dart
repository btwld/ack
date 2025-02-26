import 'dart:convert';
import 'dart:developer';

import 'package:ack/src/helpers.dart';
import 'package:meta/meta.dart';

part 'converters/open_api_schema.dart';
part 'schemas/boolean/boolean_schema.dart';
part 'schemas/boolean/boolean_validators.dart';
part 'schemas/discriminated/discriminated_object_schema.dart';
part 'schemas/discriminated/discriminated_object_validators.dart';
part 'schemas/list/list_schema.dart';
part 'schemas/list/list_validators.dart';
part 'schemas/num/num_schema.dart';
part 'schemas/num/num_validators.dart';
part 'schemas/object/object_schema.dart';
part 'schemas/object/object_validators.dart';
part 'schemas/schema.dart';
part 'schemas/string/string_schema.dart';
part 'schemas/string/string_validators.dart';
part 'validation/ack_exception.dart';
part 'validation/constraint_error.dart';
part 'validation/constraint_validator.dart';
part 'validation/schema_error.dart';
part 'validation/schema_result.dart';

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
