import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';

enum FixtureRole { admin, member }

sealed class FirebaseAiResponseJsonSchemaCase {
  const FirebaseAiResponseJsonSchemaCase({
    required this.id,
    required this.name,
    required this.features,
  });

  final String id;
  final String name;
  final List<String> features;

  String get source;

  Map<String, Object?> buildJsonSchema();

  Map<String, Object?> buildCanonicalJsonSchema();
}

final class AckSchemaResponseJsonSchemaCase
    extends FirebaseAiResponseJsonSchemaCase {
  const AckSchemaResponseJsonSchemaCase({
    required super.id,
    required super.name,
    required super.features,
    required this.schema,
  });

  final AckSchema schema;

  @override
  String get source => 'ack_schema';

  @override
  Map<String, Object?> buildJsonSchema() {
    return schema.toFirebaseAiResponseJsonSchema();
  }

  @override
  Map<String, Object?> buildCanonicalJsonSchema() {
    return schema.toSchemaModel().toJsonSchema();
  }
}

final class SchemaModelResponseJsonSchemaCase
    extends FirebaseAiResponseJsonSchemaCase {
  const SchemaModelResponseJsonSchemaCase({
    required super.id,
    required super.name,
    required super.features,
    required this.model,
  });

  final AckSchemaModel model;

  @override
  String get source => 'schema_model';

  @override
  Map<String, Object?> buildJsonSchema() {
    return model.toJsonSchema();
  }

  @override
  Map<String, Object?> buildCanonicalJsonSchema() {
    return model.toJsonSchema();
  }
}

List<FirebaseAiResponseJsonSchemaCase> firebaseAiResponseJsonSchemaCases() => [
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_string_constraints',
    name: 'string constraints',
    features: const ['string', 'minLength', 'maxLength', 'pattern'],
    schema: Ack.string()
        .minLength(2)
        .maxLength(8)
        .matches(r'^[A-Z]+$')
        .describe('Code'),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_string_literal',
    name: 'string literal',
    features: const ['string', 'const'],
    schema: Ack.literal('ready'),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_enum_values_default',
    name: 'Dart enum values and enum default',
    features: const ['string', 'enum', 'default'],
    schema: Ack.enumValues(FixtureRole.values).withDefault(FixtureRole.member),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_integer_constraints',
    name: 'integer constraints',
    features: const [
      'integer',
      'minimum',
      'maximum',
      'exclusiveMinimum',
      'exclusiveMaximum',
      'multipleOf',
      'default',
    ],
    schema: Ack.integer()
        .min(1)
        .max(10)
        .greaterThan(0)
        .lessThan(11)
        .multipleOf(2)
        .withDefault(2),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_number_constraints',
    name: 'number constraints',
    features: const [
      'number',
      'minimum',
      'maximum',
      'exclusiveMinimum',
      'exclusiveMaximum',
      'multipleOf',
      'default',
    ],
    schema: Ack.double()
        .min(0.5)
        .max(9.5)
        .greaterThan(0)
        .lessThan(10)
        .multipleOf(0.5)
        .withDefault(1.5),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_nullable_boolean_default',
    name: 'nullable boolean default',
    features: const ['boolean', 'nullable', 'anyOf', 'default'],
    schema: Ack.boolean().nullable().withDefault(false),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_array_constraints',
    name: 'array constraints',
    features: const [
      'array',
      'items',
      'format',
      'pattern',
      'minItems',
      'maxItems',
      'uniqueItems',
      'default',
    ],
    schema: Ack.list(Ack.string().uuid())
        .minLength(1)
        .maxLength(3)
        .unique()
        .withDefault(['00000000-0000-0000-0000-000000000000']),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_object_properties_requiredness',
    name: 'object properties and requiredness',
    features: const [
      'object',
      'properties',
      'required',
      'optional',
      'additionalProperties',
    ],
    schema: Ack.object({
      'name': Ack.string().minLength(2).maxLength(50).describe('Full name'),
      'age': Ack.integer().min(0).max(120).optional(),
      'role': Ack.enumString(['admin', 'member']),
      'tags': Ack.list(Ack.string()).minLength(1).maxLength(5).optional(),
    }, additionalProperties: false).describe('User payload'),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_object_passthrough',
    name: 'object passthrough',
    features: const ['object', 'additionalProperties', 'anyOf', 'optional'],
    schema: Ack.object({
      'metadata': Ack.any().optional(),
    }, additionalProperties: true),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_anyof_nullable_composition',
    name: 'anyOf nullable composition',
    features: const ['anyOf', 'nullable'],
    schema: Ack.anyOf([Ack.string(), Ack.integer()]).nullable(),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_generic_transform',
    name: 'generic transform',
    features: const ['transform', 'extension', 'minLength'],
    schema: Ack.string().minLength(1).transform((value) => value.trim()),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_any_json_compatible_branches',
    name: 'any JSON-compatible branches',
    features: const ['any', 'anyOf'],
    schema: Ack.any(),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_date_transform_constraints',
    name: 'date transform constraints',
    features: const ['transform', 'format'],
    schema: Ack.date().min(DateTime(2026, 1, 1)).max(DateTime(2026, 12, 31)),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_datetime_transform',
    name: 'datetime transform',
    features: const ['transform', 'format'],
    schema: Ack.datetime(),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_uri_transform',
    name: 'uri transform',
    features: const ['transform', 'format'],
    schema: Ack.uri(),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_duration_transform_constraints',
    name: 'duration transform constraints',
    features: const ['transform', 'integer', 'minimum', 'maximum'],
    schema: Ack.duration()
        .min(const Duration(seconds: 1))
        .max(const Duration(seconds: 2)),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_discriminated_union',
    name: 'discriminated union',
    features: const ['anyOf', 'const', 'unionOwnedDiscriminator'],
    schema: Ack.discriminated<Map<String, Object?>>(
      discriminatorKey: 'type',
      schemas: {
        'circle': Ack.object({'radius': Ack.double().positive()}),
        'square': Ack.object({'side': Ack.double().positive()}),
      },
    ),
  ),
  AckSchemaResponseJsonSchemaCase(
    id: 'ack_schema_recursive_lazy_ref',
    name: 'recursive lazy reference',
    features: const ['object', 'array', 'definitions', r'$ref', 'allOf'],
    schema: _recursiveCategorySchema(),
  ),
  const SchemaModelResponseJsonSchemaCase(
    id: 'schema_model_string_common_options',
    name: 'string model common and string-only options',
    features: [
      'string',
      'title',
      'description',
      'format',
      'const',
      'minLength',
      'maxLength',
      'pattern',
      'extension',
    ],
    model: AckStringSchemaModel(
      title: 'Status',
      description: 'Current status',
      format: 'custom-format',
      constValue: 'ready',
      minLength: 5,
      maxLength: 5,
      pattern: r'^[a-z]+$',
      formatMinimum: 'ready',
      formatMaximum: 'ready',
      extensions: {'x-ack-test': true},
    ),
  ),
  const SchemaModelResponseJsonSchemaCase(
    id: 'schema_model_integer_const_format',
    name: 'integer model const and format',
    features: ['integer', 'format', 'const'],
    model: AckIntegerSchemaModel(format: 'int32', constValue: 7),
  ),
  const SchemaModelResponseJsonSchemaCase(
    id: 'schema_model_number_const_format',
    name: 'number model const and format',
    features: ['number', 'format', 'const'],
    model: AckNumberSchemaModel(format: 'double', constValue: 1.5),
  ),
  const SchemaModelResponseJsonSchemaCase(
    id: 'schema_model_boolean_const',
    name: 'boolean model const',
    features: ['boolean', 'const'],
    model: AckBooleanSchemaModel(constValue: true),
  ),
  const SchemaModelResponseJsonSchemaCase(
    id: 'schema_model_nullable_default_extensions',
    name: 'nullable model default and extensions',
    features: ['string', 'nullable', 'anyOf', 'const', 'default', 'extension'],
    model: AckStringSchemaModel(
      constValue: 'ready',
      nullable: true,
      defaultValue: 'ready',
      extensions: {'x-ack-test': true},
    ),
  ),
  const SchemaModelResponseJsonSchemaCase(
    id: 'schema_model_array_without_item_schema',
    name: 'array model without item schema',
    features: ['array', 'minItems', 'maxItems'],
    model: AckArraySchemaModel(minItems: 0, maxItems: 2),
  ),
  const SchemaModelResponseJsonSchemaCase(
    id: 'schema_model_object_schema_additional_properties',
    name: 'object model property count and schema additional properties',
    features: [
      'object',
      'properties',
      'required',
      'minProperties',
      'maxProperties',
      'additionalPropertiesSchema',
    ],
    model: AckObjectSchemaModel(
      properties: {'id': AckStringSchemaModel()},
      required: ['id'],
      propertyOrdering: ['id'],
      minProperties: 1,
      maxProperties: 3,
      additionalProperties: AckAdditionalPropertiesSchema(
        AckStringSchemaModel(),
      ),
    ),
  ),
  const SchemaModelResponseJsonSchemaCase(
    id: 'schema_model_null',
    name: 'null model',
    features: ['null', 'title'],
    model: AckNullSchemaModel(title: 'Nothing'),
  ),
  const SchemaModelResponseJsonSchemaCase(
    id: 'schema_model_anyof_common_fields_explicit_null',
    name: 'anyOf model common fields and explicit null branch',
    features: ['anyOf', 'nullable', 'default', 'extension', 'null'],
    model: AckAnyOfSchemaModel(
      title: 'Flexible value',
      defaultValue: 'fallback',
      nullable: true,
      extensions: {'x-ack-test': true},
      schemas: [
        AckStringSchemaModel(minLength: 1),
        AckIntegerSchemaModel(minimum: 1),
        AckNullSchemaModel(),
      ],
    ),
  ),
  const SchemaModelResponseJsonSchemaCase(
    id: 'schema_model_oneof_nullable_composition',
    name: 'oneOf model nullable composition',
    features: ['oneOf', 'nullable', 'const', 'null'],
    model: AckOneOfSchemaModel(
      nullable: true,
      schemas: [
        AckStringSchemaModel(constValue: 'ready'),
        AckIntegerSchemaModel(minimum: 1),
      ],
    ),
  ),
  const SchemaModelResponseJsonSchemaCase(
    id: 'schema_model_oneof_discriminator',
    name: 'oneOf model discriminator metadata',
    features: ['oneOf', 'const'],
    model: AckOneOfSchemaModel(
      schemas: [
        AckObjectSchemaModel(
          properties: {
            'type': AckStringSchemaModel(constValue: 'email'),
            'address': AckStringSchemaModel(format: 'email'),
          },
          required: ['type', 'address'],
        ),
        AckObjectSchemaModel(
          properties: {
            'type': AckStringSchemaModel(constValue: 'sms'),
            'number': AckStringSchemaModel(),
          },
          required: ['type', 'number'],
        ),
      ],
      discriminator: AckSchemaDiscriminatorModel(propertyName: 'type'),
    ),
  ),
  const SchemaModelResponseJsonSchemaCase(
    id: 'schema_model_allof',
    name: 'allOf model',
    features: ['allOf'],
    model: AckAllOfSchemaModel(
      schemas: [
        AckObjectSchemaModel(
          properties: {'id': AckStringSchemaModel()},
          required: ['id'],
        ),
        AckObjectSchemaModel(
          properties: {'name': AckStringSchemaModel()},
          required: ['name'],
        ),
      ],
    ),
  ),
];

ObjectSchema _recursiveCategorySchema() {
  late final ObjectSchema categorySchema;
  categorySchema = Ack.object({
    'name': Ack.string(),
    'children': Ack.list(
      Ack.lazy<JsonMap, JsonMap>('Category', () => categorySchema),
    ),
    'featured': Ack.lazy<JsonMap, JsonMap>(
      'Category',
      () => categorySchema,
    ).describe('Featured category'),
  });
  return categorySchema;
}
