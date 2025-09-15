// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'edge_case_models.dart';

/// Generated schema for LargeFieldModel
final largeFieldModelSchema = Ack.object({
  'field1': Ack.string(),
  'field2': Ack.string(),
  'field3': Ack.string(),
  'field4': Ack.string(),
  'field5': Ack.string(),
  'field6': Ack.string(),
  'field7': Ack.string(),
  'field8': Ack.string(),
  'field9': Ack.string(),
  'field10': Ack.string(),
  'field11': Ack.string(),
  'field12': Ack.string(),
  'field13': Ack.string(),
  'field14': Ack.string(),
  'field15': Ack.string(),
  'field16': Ack.string(),
  'field17': Ack.string(),
  'field18': Ack.string(),
  'field19': Ack.string(),
  'field20': Ack.string(),
});

/// Generated schema for SpecialFieldsModel
final specialFieldsModelSchema = Ack.object({
  'user-id': Ack.string(),
  'full_name': Ack.string(),
  'email.address': Ack.string(),
  'meta:data': Ack.string(),
});

/// Generated SchemaModel for [LargeFieldModel].
class LargeFieldModelSchemaModel extends SchemaModel<LargeFieldModel> {
  LargeFieldModelSchemaModel._internal(ObjectSchema this.schema);

  factory LargeFieldModelSchemaModel() {
    return LargeFieldModelSchemaModel._internal(largeFieldModelSchema);
  }

  LargeFieldModelSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  LargeFieldModel createFromMap(Map<String, dynamic> map) {
    return LargeFieldModel(
      field1: map['field1'] as String,
      field2: map['field2'] as String,
      field3: map['field3'] as String,
      field4: map['field4'] as String,
      field5: map['field5'] as String,
      field6: map['field6'] as String,
      field7: map['field7'] as String,
      field8: map['field8'] as String,
      field9: map['field9'] as String,
      field10: map['field10'] as String,
      field11: map['field11'] as String,
      field12: map['field12'] as String,
      field13: map['field13'] as String,
      field14: map['field14'] as String,
      field15: map['field15'] as String,
      field16: map['field16'] as String,
      field17: map['field17'] as String,
      field18: map['field18'] as String,
      field19: map['field19'] as String,
      field20: map['field20'] as String,
    );
  }

  /// Returns a new schema with the specified description.
  LargeFieldModelSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return LargeFieldModelSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  LargeFieldModelSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return LargeFieldModelSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  LargeFieldModelSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return LargeFieldModelSchemaModel._withSchema(newSchema);
  }
}

/// Generated SchemaModel for [SpecialFieldsModel].
class SpecialFieldsModelSchemaModel extends SchemaModel<SpecialFieldsModel> {
  SpecialFieldsModelSchemaModel._internal(ObjectSchema this.schema);

  factory SpecialFieldsModelSchemaModel() {
    return SpecialFieldsModelSchemaModel._internal(specialFieldsModelSchema);
  }

  SpecialFieldsModelSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  SpecialFieldsModel createFromMap(Map<String, dynamic> map) {
    return SpecialFieldsModel(
      userId: map['user-id'] as String,
      fullName: map['full_name'] as String,
      emailAddress: map['email.address'] as String,
      metadata: map['meta:data'] as String,
    );
  }

  /// Returns a new schema with the specified description.
  SpecialFieldsModelSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return SpecialFieldsModelSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  SpecialFieldsModelSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return SpecialFieldsModelSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  SpecialFieldsModelSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return SpecialFieldsModelSchemaModel._withSchema(newSchema);
  }
}
