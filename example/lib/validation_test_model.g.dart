// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'validation_test_model.dart';

/// Generated schema for SimpleValidationModel
final simpleValidationModelSchema = Ack.object({
  'id': Ack.string(),
  'name': Ack.string(),
  'tags': Ack.list(Ack.string()),
});

/// Generated SchemaModel for [SimpleValidationModel].
class SimpleValidationModelSchemaModel
    extends SchemaModel<SimpleValidationModel> {
  SimpleValidationModelSchemaModel._internal(ObjectSchema this.schema);

  factory SimpleValidationModelSchemaModel() {
    return SimpleValidationModelSchemaModel._internal(
      simpleValidationModelSchema,
    );
  }

  SimpleValidationModelSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  SimpleValidationModel createFromMap(Map<String, dynamic> map) {
    return SimpleValidationModel(
      id: map['id'] as String,
      name: map['name'] as String,
      tags: (map['tags'] as List).cast<String>(),
    );
  }

  /// Returns a new schema with the specified description.
  SimpleValidationModelSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return SimpleValidationModelSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  SimpleValidationModelSchemaModel withDefault(
    Map<String, dynamic> defaultValue,
  ) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return SimpleValidationModelSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  SimpleValidationModelSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return SimpleValidationModelSchemaModel._withSchema(newSchema);
  }
}
