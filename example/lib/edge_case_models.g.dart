// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'edge_case_models.dart';

/// Generated schema for ComplexGenericModel
final complexGenericModelSchema = Ack.object({
  'id': Ack.string(),
  'nestedData': Ack.list(Ack.object({}, additionalProperties: true)),
  'complexMap': Ack.object({}, additionalProperties: true),
});

/// Generated schema for NodeModel
final nodeModelSchema = Ack.object({
  'id': Ack.string(),
  'name': Ack.string(),
  'children': Ack.list(nodeModelSchema).optional().nullable(),
  'parent': nodeModelSchema.optional().nullable(),
});

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

/// Generated SchemaModel for [ComplexGenericModel].
class ComplexGenericModelSchemaModel extends SchemaModel<ComplexGenericModel> {
  ComplexGenericModelSchemaModel._();

  factory ComplexGenericModelSchemaModel() {
    return _instance;
  }

  static final _instance = ComplexGenericModelSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return complexGenericModelSchema;
  }

  @override
  ComplexGenericModel createFromMap(Map<String, dynamic> map) {
    return ComplexGenericModel(
      id: map['id'] as String,
      nestedData: (map['nestedData'] as List)
          .map(
            (item) => Map < String,
            List <
                String >>
                    SchemaModel._instance.createFromMap(
                      item as Map<String, dynamic>,
                    ),
          )
          .toList(),
      complexMap: map['complexMap'] as Map<String, List<Map<String, dynamic>>>,
    );
  }
}

/// Generated SchemaModel for [NodeModel].
class NodeModelSchemaModel extends SchemaModel<NodeModel> {
  NodeModelSchemaModel._();

  factory NodeModelSchemaModel() {
    return _instance;
  }

  static final _instance = NodeModelSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return nodeModelSchema;
  }

  @override
  NodeModel createFromMap(Map<String, dynamic> map) {
    return NodeModel(
      id: map['id'] as String,
      name: map['name'] as String,
      children: (map['children'] as List?)
          ?.map(
            (item) => NodeModelSchemaModel._instance.createFromMap(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      parent: map['parent'] != null
          ? NodeModelSchemaModel._instance.createFromMap(
              map['parent'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// Generated SchemaModel for [LargeFieldModel].
class LargeFieldModelSchemaModel extends SchemaModel<LargeFieldModel> {
  LargeFieldModelSchemaModel._();

  factory LargeFieldModelSchemaModel() {
    return _instance;
  }

  static final _instance = LargeFieldModelSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return largeFieldModelSchema;
  }

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
}

/// Generated SchemaModel for [SpecialFieldsModel].
class SpecialFieldsModelSchemaModel extends SchemaModel<SpecialFieldsModel> {
  SpecialFieldsModelSchemaModel._();

  factory SpecialFieldsModelSchemaModel() {
    return _instance;
  }

  static final _instance = SpecialFieldsModelSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return specialFieldsModelSchema;
  }

  @override
  SpecialFieldsModel createFromMap(Map<String, dynamic> map) {
    return SpecialFieldsModel(
      userId: map['user-id'] as String,
      fullName: map['full_name'] as String,
      emailAddress: map['email.address'] as String,
      metadata: map['meta:data'] as String,
    );
  }
}
