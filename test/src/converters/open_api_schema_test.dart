import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('OpenApiSchemaConverter Tests', () {
    test('StringSchema converts to basic OpenAPI schema', () {
      final schema = StringSchema();
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(converter.toSchema(), equals({'type': 'string'}));
    });

    test('StringSchema with nullable includes nullable field', () {
      final schema = StringSchema(nullable: true);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(), equals({'type': 'string', 'nullable': true}));
    });

    test('StringSchema with description includes description field', () {
      final schema = StringSchema(description: 'A test string');
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(converter.toSchema(),
          equals({'type': 'string', 'description': 'A test string'}));
    });

    test('StringSchema with MinLength constraint merges correctly', () {
      final schema = StringSchema(constraints: [MinLengthStringValidator(5)]);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(converter.toSchema(), equals({'type': 'string', 'minLength': 5}));
    });

    test('DoubleSchema with Minimum and Maximum constraints', () {
      final schema = DoubleSchema(
          constraints: [MinNumValidator(0.0), MaxNumValidator(100.0)]);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(converter.toSchema(),
          equals({'type': 'number', 'minimum': 0.0, 'maximum': 100.0}));
    });

    test('IntegerSchema with MultipleOf constraint', () {
      final schema = IntegerSchema(constraints: [MultipleOfNumValidator(2)]);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(), equals({'type': 'integer', 'multipleOf': 2}));
    });

    test('BooleanSchema converts to basic OpenAPI schema', () {
      final schema = BooleanSchema();
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(converter.toSchema(), equals({'type': 'boolean'}));
    });

    test('ListSchema with StringSchema items includes items field', () {
      final itemSchema = StringSchema();
      final schema = ListSchema(itemSchema); // Assuming items parameter
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'array',
            'items': {'type': 'string'}
          }));
    });

    test('ObjectSchema with properties converts correctly', () {
      final properties = <String, Schema<Object>>{
        'name': StringSchema(),
        'age': IntegerSchema(),
      };
      final schema = ObjectSchema(properties, additionalProperties: true);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
              'age': {'type': 'integer'},
            },
            'additionalProperties': true,
          }));
    });

    test('ObjectSchema with required properties includes required field', () {
      final properties = {'name': StringSchema()};
      final schema = ObjectSchema(properties, required: ['name']);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'object',
            'properties': {
              'name': {'type': 'string'}
            },
            'required': ['name'],
            'additionalProperties': false,
          }));
    });

    test('ObjectSchema with additionalProperties false', () {
      final schema = ObjectSchema({}, additionalProperties: false);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'object',
            'properties': {},
            'additionalProperties': false,
          }));
    });
  });

  group('OpenApi3SchemaConverter Tests', () {
    test('StringSchema converts to basic OpenAPI schema', () {
      final schema = StringSchema();
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(converter.toSchema(), equals({'type': 'string'}));
    });

    test('StringSchema with nullable includes nullable field', () {
      final schema = StringSchema(nullable: true);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(), equals({'type': 'string', 'nullable': true}));
    });

    test('StringSchema with description includes description field', () {
      final schema = StringSchema(description: 'A test string');
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(converter.toSchema(),
          equals({'type': 'string', 'description': 'A test string'}));
    });

    test('StringSchema with MinLength constraint merges correctly', () {
      final schema = StringSchema(constraints: [MinLengthStringValidator(5)]);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(converter.toSchema(), equals({'type': 'string', 'minLength': 5}));
    });

    test('DoubleSchema with Minimum and Maximum constraints', () {
      final schema = DoubleSchema(
          constraints: [MinNumValidator(0.0), MaxNumValidator(100.0)]);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(converter.toSchema(),
          equals({'type': 'number', 'minimum': 0.0, 'maximum': 100.0}));
    });

    test('IntegerSchema with MultipleOf constraint', () {
      final schema = IntegerSchema(constraints: [MultipleOfNumValidator(2)]);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(), equals({'type': 'integer', 'multipleOf': 2}));
    });

    test('BooleanSchema converts to basic OpenAPI schema', () {
      final schema = BooleanSchema();
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(converter.toSchema(), equals({'type': 'boolean'}));
    });

    test('ListSchema with StringSchema items includes items field', () {
      final itemSchema = StringSchema();
      final schema = ListSchema(itemSchema);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'array',
            'items': {'type': 'string'}
          }));
    });

    test('ObjectSchema with properties converts correctly', () {
      final properties = <String, Schema<Object>>{
        'name': StringSchema(),
        'age': IntegerSchema(),
      };
      final schema = ObjectSchema(properties);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
              'age': {'type': 'integer'},
            },
            'additionalProperties': false,
          }));
    });

    test('ObjectSchema with required properties includes required field', () {
      final properties = <String, Schema<Object>>{'name': StringSchema()};
      final schema = ObjectSchema(properties, required: ['name']);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'object',
            'properties': {
              'name': {'type': 'string'}
            },
            'required': ['name'],
            'additionalProperties': false,
          }));
    });

    test('ObjectSchema with additionalProperties false', () {
      final schema = ObjectSchema({}, additionalProperties: false);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'object',
            'properties': {},
            'additionalProperties': false,
          }));
    });

    test('DiscriminatedObjectSchema includes discriminator', () {
      final schema =
          DiscriminatedObjectSchema(discriminatorKey: 'type', schemas: {
        'typeOne': ObjectSchema({'value': IntegerSchema()}),
        'typeTwo': ObjectSchema({'value': StringSchema()}),
      });
      final converter = OpenApiSchemaConverter(schema: schema);

      final schemaMap = converter.toSchema();

      expect(schemaMap['discriminator'], equals({'propertyName': 'type'}));
      expect(
          schemaMap['oneOf'],
          unorderedEquals([
            {
              'type': 'object',
              'properties': {
                'value': {'type': 'integer'}
              },
              'additionalProperties': false,
            },
            {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'}
              },
              'additionalProperties': false,
            },
          ]));
    });

    test('Nested ObjectSchema converts correctly', () {
      final nestedSchema = ObjectSchema({'id': IntegerSchema()});
      final schema = ObjectSchema({'nested': nestedSchema});
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'object',
            'properties': {
              'nested': {
                'type': 'object',
                'properties': {
                  'id': {'type': 'integer'}
                },
                'additionalProperties': false,
              }
            },
            'additionalProperties': false,
          }));
    });

    test('ListSchema with ObjectSchema items', () {
      final itemSchema = ObjectSchema({'name': StringSchema()});
      final schema = ListSchema(itemSchema);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'name': {'type': 'string'}
              },
              'additionalProperties': false,
            },
          }));
    });

    test('StringSchema with multiple constraints merges correctly', () {
      final schema = StringSchema(constraints: [
        MinLengthStringValidator(3),
        MaxLengthStringValidator(10),
        RegexPatternStringValidator(
            patternName: 'pattern', pattern: r'^[a-z]+$', example: 'a    ')
      ]);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'string',
            'format': 'pattern',
            'minLength': 3,
            'maxLength': 10,
            'pattern': r'^[a-z]+$',
          }));
    });

    test('StringSchema with format constraint', () {
      final schema = StringSchema(constraints: [DateTimeStringValidator()]);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(converter.toSchema(),
          equals({'type': 'string', 'format': 'date-time'}));
    });

    test('IntegerSchema with minimum and maximum constraints', () {
      final schema = IntegerSchema(
          constraints: [MinNumValidator(1), MaxNumValidator(100)]);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(converter.toSchema(),
          equals({'type': 'integer', 'minimum': 1, 'maximum': 100}));
    });

    test('ListSchema with minItems and maxItems constraints', () {
      final schema = ListSchema<String>(StringSchema(),
          constraints: [MinItemsListValidator(1), MaxItemsListValidator(10)]);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'array',
            'items': {'type': 'string'},
            'minItems': 1,
            'maxItems': 10,
          }));
    });

    test('ObjectSchema with nested required properties', () {
      final nestedSchema =
          ObjectSchema({'id': IntegerSchema()}, required: ['id']);
      final schema =
          ObjectSchema({'nested': nestedSchema}, required: ['nested']);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'object',
            'properties': {
              'nested': {
                'type': 'object',
                'properties': {
                  'id': {'type': 'integer'}
                },
                'required': ['id'],
                'additionalProperties': false,
              }
            },
            'required': ['nested'],
            'additionalProperties': false,
          }));
    });

    test('Schema with multiple constraints of same type merges correctly', () {
      final schema = StringSchema(constraints: [
        MinLengthStringValidator(5),
        MinLengthStringValidator(3)
      ]);
      final converter = OpenApiSchemaConverter(schema: schema);
      // Assumes the converter takes the most restrictive value
      expect(converter.toSchema(), equals({'type': 'string', 'minLength': 3}));
    });

    test('Nested ListSchema converts correctly', () {
      final innerListSchema = ListSchema(StringSchema());
      final schema = ListSchema(innerListSchema);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'array',
            'items': {
              'type': 'array',
              'items': {'type': 'string'}
            },
          }));
    });

    test('DiscriminatedObjectSchema with properties', () {
      final schema = DiscriminatedObjectSchema(
        discriminatorKey: 'key',
        schemas: {
          'keyOne':
              ObjectSchema({'value': IntegerSchema(), 'key': StringSchema()}),
          'keyTwo':
              ObjectSchema({'value': StringSchema(), 'key': StringSchema()}),
        },
      );
      final converter = OpenApiSchemaConverter(schema: schema);

      final schemaMap = converter.toSchema();

      expect(schemaMap['discriminator'], equals({'propertyName': 'key'}));

      expect(
          schemaMap['oneOf'],
          unorderedEquals([
            {
              'type': 'object',
              'properties': {
                'value': {'type': 'integer'},
                'key': {'type': 'string'},
              },
              'additionalProperties': false,
            },
            {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
                'key': {'type': 'string'},
              },
              'additionalProperties': false,
            },
          ]));
    });

    test('Empty ObjectSchema with additionalProperties true', () {
      final schema = ObjectSchema({}, additionalProperties: true);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'object',
            'properties': {},
            'additionalProperties': true,
          }));
    });

    test('DiscriminatedObjectSchema with oneOf and discriminator', () {
      final schema = DiscriminatedObjectSchema(
        discriminatorKey: 'kind',
        schemas: {
          'firstKind':
              ObjectSchema({'kind': StringSchema(), 'value': StringSchema()}),
          'secondKind':
              ObjectSchema({'kind': StringSchema(), 'count': IntegerSchema()}),
        },
      );
      final converter = OpenApiSchemaConverter(schema: schema);
      final result = converter.toSchema();

      // Check the discriminator field
      expect(result['discriminator'], equals({'propertyName': 'kind'}));

      // Check the oneOf field, ignoring order
      expect(
        result['oneOf'],
        unorderedEquals([
          {
            'type': 'object',
            'properties': {
              'kind': {'type': 'string'},
              'count': {'type': 'integer'}
            },
            'additionalProperties': false,
          },
          {
            'type': 'object',
            'properties': {
              'kind': {'type': 'string'},
              'value': {'type': 'string'}
            },
            'additionalProperties': false,
          },
        ]),
      );
    });

    test('StringSchema with enum values', () {
      final schema = StringSchema(constraints: [
        EnumStringValidator(['red', 'blue', 'green'])
      ]);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'string',
            'enum': ['red', 'blue', 'green'],
          }));
    });

    test('ObjectSchema with required properties', () {
      final schema = ObjectSchema(
        {'id': IntegerSchema(), 'name': StringSchema()},
        required: ['id'],
      );
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'object',
            'properties': {
              'id': {'type': 'integer'},
              'name': {'type': 'string'},
            },
            'required': ['id'],
            'additionalProperties': false,
          }));
    });

    test('IntegerSchema with default value', () {
      final schema = IntegerSchema(defaultValue: 42);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'integer',
            'default': 42,
          }));
    });

    test('ListSchema with items having multiple constraints', () {
      final itemSchema = StringSchema(
        constraints: [
          MinLengthStringValidator(3),
          RegexPatternStringValidator(
              patternName: 'pattern', pattern: r'^[A-Z]$', example: 'A'),
        ],
      );
      final schema = ListSchema(itemSchema);
      final converter = OpenApiSchemaConverter(schema: schema);
      expect(
          converter.toSchema(),
          equals({
            'type': 'array',
            'items': {
              'type': 'string',
              'format': 'pattern',
              'minLength': 3,
              'pattern': r'^[A-Z]$',
            },
          }));
    });
  });
}
