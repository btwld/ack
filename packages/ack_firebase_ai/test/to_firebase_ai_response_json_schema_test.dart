import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:ack_firebase_ai/ack_firebase_ai.dart';
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'package:test/test.dart';

enum Role { admin, member }

void main() {
  group('toFirebaseAiResponseJsonSchema()', () {
    for (final schemaCase in _ackSchemaCases()) {
      test('matches Firebase responseJsonSchema for ${schemaCase.name}', () {
        final jsonSchema = schemaCase.schema.toFirebaseAiResponseJsonSchema();

        expect(jsonSchema, schemaCase.expected);
        expect(jsonSchema, schemaCase.schema.toSchemaModel().toJsonSchema());
        _expectFirebaseGenerationConfigSerializes(jsonSchema);
      });
    }
  });

  group('convertAckSchemaModelToFirebaseAiResponseJsonSchema()', () {
    for (final schemaCase in _schemaModelCases()) {
      test('matches Firebase responseJsonSchema for ${schemaCase.name}', () {
        final jsonSchema = convertAckSchemaModelToFirebaseAiResponseJsonSchema(
          schemaCase.model,
        );

        expect(jsonSchema, schemaCase.expected);
        expect(jsonSchema, schemaCase.model.toJsonSchema());
        _expectFirebaseGenerationConfigSerializes(jsonSchema);
      });
    }
  });
}

List<_AckSchemaCase> _ackSchemaCases() => [
  _AckSchemaCase(
    name: 'string constraints',
    schema: Ack.string()
        .minLength(2)
        .maxLength(8)
        .matches(r'^[A-Z]+$')
        .describe('Code'),
    expected: {
      'type': 'string',
      'minLength': 2,
      'maxLength': 8,
      'pattern': r'^[A-Z]+$',
      'description': 'Code',
    },
  ),
  _AckSchemaCase(
    name: 'string literal',
    schema: Ack.literal('ready'),
    expected: {'type': 'string', 'const': 'ready'},
  ),
  _AckSchemaCase(
    name: 'Dart enum values and enum default',
    schema: Ack.enumValues(Role.values).withDefault(Role.member),
    expected: {
      'type': 'string',
      'enum': ['admin', 'member'],
      'default': 'member',
    },
  ),
  _AckSchemaCase(
    name: 'integer constraints',
    schema: Ack.integer()
        .min(1)
        .max(10)
        .greaterThan(0)
        .lessThan(11)
        .multipleOf(2)
        .withDefault(2),
    expected: {
      'type': 'integer',
      'minimum': 1,
      'maximum': 10,
      'exclusiveMinimum': 0,
      'exclusiveMaximum': 11,
      'multipleOf': 2,
      'default': 2,
    },
  ),
  _AckSchemaCase(
    name: 'number constraints',
    schema: Ack.double()
        .min(0.5)
        .max(9.5)
        .greaterThan(0)
        .lessThan(10)
        .multipleOf(0.5)
        .withDefault(1.5),
    expected: {
      'type': 'number',
      'minimum': 0.5,
      'maximum': 9.5,
      'exclusiveMinimum': 0.0,
      'exclusiveMaximum': 10.0,
      'multipleOf': 0.5,
      'default': 1.5,
    },
  ),
  _AckSchemaCase(
    name: 'nullable boolean default',
    schema: Ack.boolean().nullable().withDefault(false),
    expected: {
      'default': false,
      'anyOf': [
        {'type': 'boolean'},
        {'type': 'null'},
      ],
    },
  ),
  _AckSchemaCase(
    name: 'array constraints',
    schema: Ack.list(Ack.string().uuid())
        .minLength(1)
        .maxLength(3)
        .unique()
        .withDefault(['00000000-0000-0000-0000-000000000000']),
    expected: {
      'type': 'array',
      'items': {
        'type': 'string',
        'format': 'uuid',
        'pattern':
            r'^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}|00000000-0000-0000-0000-000000000000|ffffffff-ffff-ffff-ffff-ffffffffffff)$',
      },
      'minItems': 1,
      'maxItems': 3,
      'uniqueItems': true,
      'default': ['00000000-0000-0000-0000-000000000000'],
    },
  ),
  _AckSchemaCase(
    name: 'object properties and requiredness',
    schema: Ack.object({
      'name': Ack.string().minLength(2).maxLength(50).describe('Full name'),
      'age': Ack.integer().min(0).max(120).optional(),
      'role': Ack.enumString(['admin', 'member']),
      'tags': Ack.list(Ack.string()).minLength(1).maxLength(5).optional(),
    }, additionalProperties: false).describe('User payload'),
    expected: {
      'type': 'object',
      'description': 'User payload',
      'properties': {
        'name': {
          'type': 'string',
          'description': 'Full name',
          'minLength': 2,
          'maxLength': 50,
        },
        'age': {'type': 'integer', 'minimum': 0, 'maximum': 120},
        'role': {
          'type': 'string',
          'enum': ['admin', 'member'],
        },
        'tags': {
          'type': 'array',
          'items': {'type': 'string'},
          'minItems': 1,
          'maxItems': 5,
        },
      },
      'required': ['name', 'role'],
      'propertyOrdering': ['name', 'age', 'role', 'tags'],
      'additionalProperties': false,
    },
  ),
  _AckSchemaCase(
    name: 'object passthrough',
    schema: Ack.object({
      'metadata': Ack.any().optional(),
    }, additionalProperties: true),
    expected: {
      'type': 'object',
      'properties': {
        'metadata': {
          'anyOf': [
            {'type': 'string'},
            {'type': 'number'},
            {'type': 'integer'},
            {'type': 'boolean'},
            {'type': 'object'},
            {'type': 'array'},
          ],
        },
      },
      'propertyOrdering': ['metadata'],
      'additionalProperties': true,
    },
  ),
  _AckSchemaCase(
    name: 'anyOf nullable composition',
    schema: Ack.anyOf([Ack.string(), Ack.integer()]).nullable(),
    expected: {
      'anyOf': [
        {'type': 'string'},
        {'type': 'integer'},
        {'type': 'null'},
      ],
    },
  ),
  _AckSchemaCase(
    name: 'generic transform',
    schema: Ack.string().minLength(1).transform((value) => value.trim()),
    expected: {'type': 'string', 'minLength': 1, 'x-transformed': true},
  ),
  _AckSchemaCase(
    name: 'any JSON-compatible branches',
    schema: Ack.any(),
    expected: {
      'anyOf': [
        {'type': 'string'},
        {'type': 'number'},
        {'type': 'integer'},
        {'type': 'boolean'},
        {'type': 'object'},
        {'type': 'array'},
      ],
    },
  ),
  _AckSchemaCase(
    name: 'date transform constraints',
    schema: Ack.date().min(DateTime(2026, 1, 1)).max(DateTime(2026, 12, 31)),
    expected: {
      'type': 'string',
      'format': 'date',
      'formatMinimum': '2026-01-01',
      'formatMaximum': '2026-12-31',
      'x-transformed': true,
    },
  ),
  _AckSchemaCase(
    name: 'datetime transform',
    schema: Ack.datetime(),
    expected: {'type': 'string', 'format': 'date-time', 'x-transformed': true},
  ),
  _AckSchemaCase(
    name: 'uri transform',
    schema: Ack.uri(),
    expected: {'type': 'string', 'format': 'uri', 'x-transformed': true},
  ),
  _AckSchemaCase(
    name: 'duration transform constraints',
    schema: Ack.duration()
        .min(const Duration(seconds: 1))
        .max(const Duration(seconds: 2)),
    expected: {
      'type': 'integer',
      'minimum': 1000,
      'maximum': 2000,
      'x-transformed': true,
    },
  ),
  _AckSchemaCase(
    name: 'discriminated union',
    schema: Ack.discriminated<Map<String, Object?>>(
      discriminatorKey: 'type',
      schemas: {
        'circle': Ack.object({'radius': Ack.double().positive()}),
        'square': Ack.object({'side': Ack.double().positive()}),
      },
    ),
    expected: {
      'oneOf': [
        {
          'type': 'object',
          'properties': {
            'type': {'type': 'string', 'const': 'circle'},
            'radius': {'type': 'number', 'exclusiveMinimum': 0.0},
          },
          'required': ['type', 'radius'],
          'propertyOrdering': ['type', 'radius'],
          'additionalProperties': false,
        },
        {
          'type': 'object',
          'properties': {
            'type': {'type': 'string', 'const': 'square'},
            'side': {'type': 'number', 'exclusiveMinimum': 0.0},
          },
          'required': ['type', 'side'],
          'propertyOrdering': ['type', 'side'],
          'additionalProperties': false,
        },
      ],
      'discriminator': {'propertyName': 'type'},
    },
  ),
];

List<_SchemaModelCase> _schemaModelCases() => [
  const _SchemaModelCase(
    name: 'string model common and string-only options',
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
      extensions: {'x-firebase-test': true},
    ),
    expected: {
      'type': 'string',
      'format': 'custom-format',
      'const': 'ready',
      'minLength': 5,
      'maxLength': 5,
      'pattern': r'^[a-z]+$',
      'formatMinimum': 'ready',
      'formatMaximum': 'ready',
      'title': 'Status',
      'description': 'Current status',
      'x-firebase-test': true,
    },
  ),
  const _SchemaModelCase(
    name: 'integer model const and format',
    model: AckIntegerSchemaModel(format: 'int32', constValue: 7),
    expected: {'type': 'integer', 'format': 'int32', 'const': 7},
  ),
  const _SchemaModelCase(
    name: 'number model const and format',
    model: AckNumberSchemaModel(format: 'double', constValue: 1.5),
    expected: {'type': 'number', 'format': 'double', 'const': 1.5},
  ),
  const _SchemaModelCase(
    name: 'boolean model const',
    model: AckBooleanSchemaModel(constValue: true),
    expected: {'type': 'boolean', 'const': true},
  ),
  const _SchemaModelCase(
    name: 'nullable model default and extensions',
    model: AckStringSchemaModel(
      constValue: 'ready',
      nullable: true,
      defaultValue: 'ready',
      extensions: {'x-firebase-test': true},
    ),
    expected: {
      'default': 'ready',
      'anyOf': [
        {'type': 'string', 'const': 'ready', 'x-firebase-test': true},
        {'type': 'null'},
      ],
    },
  ),
  const _SchemaModelCase(
    name: 'array model without item schema',
    model: AckArraySchemaModel(minItems: 0, maxItems: 2),
    expected: {'type': 'array', 'minItems': 0, 'maxItems': 2},
  ),
  const _SchemaModelCase(
    name: 'object model property count and schema additional properties',
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
    expected: {
      'type': 'object',
      'properties': {
        'id': {'type': 'string'},
      },
      'required': ['id'],
      'propertyOrdering': ['id'],
      'minProperties': 1,
      'maxProperties': 3,
      'additionalProperties': {'type': 'string'},
    },
  ),
  const _SchemaModelCase(
    name: 'null model',
    model: AckNullSchemaModel(title: 'Nothing'),
    expected: {'type': 'null', 'title': 'Nothing'},
  ),
  const _SchemaModelCase(
    name: 'anyOf model common fields and explicit null branch',
    model: AckAnyOfSchemaModel(
      title: 'Flexible value',
      defaultValue: 'fallback',
      nullable: true,
      extensions: {'x-firebase-test': true},
      schemas: [
        AckStringSchemaModel(minLength: 1),
        AckIntegerSchemaModel(minimum: 1),
        AckNullSchemaModel(),
      ],
    ),
    expected: {
      'title': 'Flexible value',
      'default': 'fallback',
      'x-firebase-test': true,
      'anyOf': [
        {'type': 'string', 'minLength': 1},
        {'type': 'integer', 'minimum': 1},
        {'type': 'null'},
      ],
    },
  ),
  const _SchemaModelCase(
    name: 'oneOf model nullable composition',
    model: AckOneOfSchemaModel(
      nullable: true,
      schemas: [
        AckStringSchemaModel(constValue: 'ready'),
        AckIntegerSchemaModel(minimum: 1),
      ],
    ),
    expected: {
      'oneOf': [
        {'type': 'string', 'const': 'ready'},
        {'type': 'integer', 'minimum': 1},
        {'type': 'null'},
      ],
    },
  ),
  const _SchemaModelCase(
    name: 'oneOf model discriminator',
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
    expected: {
      'oneOf': [
        {
          'type': 'object',
          'properties': {
            'type': {'type': 'string', 'const': 'email'},
            'address': {'type': 'string', 'format': 'email'},
          },
          'required': ['type', 'address'],
        },
        {
          'type': 'object',
          'properties': {
            'type': {'type': 'string', 'const': 'sms'},
            'number': {'type': 'string'},
          },
          'required': ['type', 'number'],
        },
      ],
      'discriminator': {'propertyName': 'type'},
    },
  ),
  const _SchemaModelCase(
    name: 'allOf model',
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
    expected: {
      'allOf': [
        {
          'type': 'object',
          'properties': {
            'id': {'type': 'string'},
          },
          'required': ['id'],
        },
        {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
          },
          'required': ['name'],
        },
      ],
    },
  ),
];

void _expectFirebaseGenerationConfigSerializes(
  Map<String, Object?> jsonSchema,
) {
  _expectJsonValue(jsonSchema);
  expect(() => jsonEncode(jsonSchema), returnsNormally);

  final configJson = firebase_ai.GenerationConfig(
    responseMimeType: 'application/json',
    responseJsonSchema: jsonSchema,
  ).toJson();

  expect(configJson['responseMimeType'], 'application/json');
  expect(configJson['responseJsonSchema'], jsonSchema);
}

void _expectJsonValue(Object? value, [String path = r'$']) {
  if (value == null || value is String || value is num || value is bool) {
    return;
  }

  if (value is List) {
    for (var index = 0; index < value.length; index += 1) {
      _expectJsonValue(value[index], '$path[$index]');
    }
    return;
  }

  if (value is Map) {
    for (final entry in value.entries) {
      expect(entry.key, isA<String>(), reason: '$path keys must be strings');
      _expectJsonValue(entry.value, '$path.${entry.key}');
    }
    return;
  }

  fail('Expected $path to be JSON-compatible, got ${value.runtimeType}.');
}

final class _AckSchemaCase {
  const _AckSchemaCase({
    required this.name,
    required this.schema,
    required this.expected,
  });

  final String name;
  final AckSchema schema;
  final Map<String, Object?> expected;
}

final class _SchemaModelCase {
  const _SchemaModelCase({
    required this.name,
    required this.model,
    required this.expected,
  });

  final String name;
  final AckSchemaModel model;
  final Map<String, Object?> expected;
}
