import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('JsonSchemaConverter Tests', () {
    group('Schema Type Conversion', () {
      test('converts basic schema types correctly', () {
        final schema = ObjectSchema({
          'string': StringSchema(),
          'integer': IntegerSchema(),
          'double': DoubleSchema(),
          'boolean': BooleanSchema(),
        });
        final converter = JsonSchemaConverter(schema: schema);
        expect(
          converter.toSchema(),
          equals({
            '\$schema': 'http://json-schema.org/draft-07/schema#',
            'type': 'object',
            'properties': {
              'string': {'type': 'string'},
              'integer': {'type': 'integer'},
              'double': {'type': 'number'},
              'boolean': {'type': 'boolean'},
            },
            'additionalProperties': false,
          }),
        );
      });

      test('converts list schema correctly', () {
        final schema = ObjectSchema({
          'items': ListSchema(StringSchema()),
        });
        final converter = JsonSchemaConverter(schema: schema);
        expect(
          converter.toSchema(),
          equals({
            '\$schema': 'http://json-schema.org/draft-07/schema#',
            'type': 'object',
            'properties': {
              'items': {
                'type': 'array',
                'items': {'type': 'string'},
              },
            },
            'additionalProperties': false,
          }),
        );
      });

      test('converts discriminated object schema correctly', () {
        final schema = ObjectSchema({
          'pet': DiscriminatedObjectSchema(
            discriminatorKey: 'animalType',
            schemas: {
              'dog': ObjectSchema({
                'animalType': StringSchema(),
                'name': StringSchema(),
              }, required: [
                'animalType',
                'name'
              ]),
              'cat': ObjectSchema({
                'animalType': StringSchema(),
                'breed': StringSchema(),
              }, required: [
                'animalType',
                'breed'
              ]),
            },
          ),
        });
        final converter = JsonSchemaConverter(schema: schema);
        expect(
          converter.toSchema(),
          equals({
            '\$schema': 'http://json-schema.org/draft-07/schema#',
            'type': 'object',
            'properties': {
              'pet': {
                'allOf': [
                  {
                    'if': {
                      'type': 'object',
                      'properties': {
                        'animalType': {'const': 'dog'}
                      },
                      'required': ['animalType']
                    },
                    'then': {
                      'type': 'object',
                      'properties': {
                        'animalType': {'type': 'string'},
                        'name': {'type': 'string'},
                      },
                      'required': ['animalType', 'name'],
                      'additionalProperties': false,
                    }
                  },
                  {
                    'if': {
                      'type': 'object',
                      'properties': {
                        'animalType': {'const': 'cat'}
                      },
                      'required': ['animalType']
                    },
                    'then': {
                      'type': 'object',
                      'properties': {
                        'animalType': {'type': 'string'},
                        'breed': {'type': 'string'},
                      },
                      'required': ['animalType', 'breed'],
                      'additionalProperties': false,
                    }
                  },
                ],
              },
            },
            'additionalProperties': false,
          }),
        );
      });

      test('handles nested discriminated schemas', () {
        // Removed unused baseSchema variable

        final circleSchema = ObjectSchema({
          'type': StringSchema(),
          'name': StringSchema(),
          'radius': DoubleSchema(),
        }, required: [
          'type',
          'name',
          'radius'
        ]);

        final rectangleSchema = ObjectSchema({
          'type': StringSchema(),
          'name': StringSchema(),
          'width': DoubleSchema(),
          'height': DoubleSchema(),
        }, required: [
          'type',
          'name',
          'width',
          'height'
        ]);

        // Create a discriminated schema
        final shapeSchema = DiscriminatedObjectSchema(
          discriminatorKey: 'type',
          schemas: {
            'circle': circleSchema,
            'rectangle': rectangleSchema,
          },
        );

        // Create a container schema that contains shapes
        final containerSchema = ObjectSchema({
          'id': StringSchema(),
          'shapes': ListSchema(shapeSchema),
        }, required: [
          'id',
          'shapes'
        ]);

        final converter = JsonSchemaConverter(schema: containerSchema);
        final result = converter.toSchema();

        // Verify the schema structure with new JSON Schema draft-7 format
        expect(result['\$schema'],
            equals('http://json-schema.org/draft-07/schema#'));
        expect(result['type'], equals('object'));
        final properties = result['properties'] as Map<String, dynamic>;
        expect(properties['id']!['type'], equals('string'));
        expect(properties['shapes']!['type'], equals('array'));

        final shapesSchema =
            properties['shapes']!['items'] as Map<String, dynamic>;
        expect(shapesSchema['allOf'], isA<List>());

        final allOf = shapesSchema['allOf'] as List;
        expect(allOf.length, equals(2));

        // Verify the discriminated schemas use if/then/else pattern
        final circleCondition = allOf[0] as Map<String, dynamic>;
        final rectangleCondition = allOf[1] as Map<String, dynamic>;

        expect(circleCondition['if']['properties']['type']['const'],
            equals('circle'));
        expect(circleCondition['then']['properties']['radius']['type'],
            equals('number'));
        expect(rectangleCondition['if']['properties']['type']['const'],
            equals('rectangle'));
        expect(rectangleCondition['then']['properties']['width']['type'],
            equals('number'));
      });
    });

    group('Schema Properties', () {
      test('handles nullable schemas', () {
        final schema = ObjectSchema({
          'optional': StringSchema().nullable(),
        });
        final converter = JsonSchemaConverter(schema: schema);
        expect(
          converter.toSchema(),
          equals({
            '\$schema': 'http://json-schema.org/draft-07/schema#',
            'type': 'object',
            'properties': {
              'optional': {
                'type': ['string', 'null'],
              },
            },
            'additionalProperties': false,
          }),
        );
      });

      test('includes schema descriptions', () {
        final schema = ObjectSchema({
          'name': StringSchema(description: 'The user\'s name'),
        });
        final converter = JsonSchemaConverter(schema: schema);
        expect(
          converter.toSchema(),
          equals({
            '\$schema': 'http://json-schema.org/draft-07/schema#',
            'type': 'object',
            'properties': {
              'name': {
                'type': 'string',
                'description': 'The user\'s name',
              },
            },
            'additionalProperties': false,
          }),
        );
      });

      test('includes default values', () {
        final schema = ObjectSchema({
          'active': BooleanSchema(defaultValue: true),
        });
        final converter = JsonSchemaConverter(schema: schema);
        expect(
          converter.toSchema(),
          equals({
            '\$schema': 'http://json-schema.org/draft-07/schema#',
            'type': 'object',
            'properties': {
              'active': {
                'type': 'boolean',
                'default': true,
              },
            },
            'additionalProperties': false,
          }),
        );
      });

      test('can disable schema declaration for backward compatibility', () {
        final schema = ObjectSchema({
          'name': StringSchema(),
        });
        final converter = JsonSchemaConverter(
          schema: schema,
          includeSchemaVersion: false,
        );
        expect(
          converter.toSchema(),
          equals({
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
            },
            'additionalProperties': false,
          }),
        );
      });
    });

    group('Response Parsing', () {
      test('parses raw JSON response', () {
        final schema = ObjectSchema({'value': StringSchema()});
        final converter = JsonSchemaConverter(schema: schema);
        final mapValue = {
          'value': 'test',
        };
        final result = converter.parseResponse(jsonEncode(mapValue));
        expect(result, equals(mapValue));
      });

      test('parses delimited response', () {
        final schema = ObjectSchema({'value': StringSchema()});
        final converter = JsonSchemaConverter(
          schema: schema,
          startDelimeter: '<response>',
          endDelimeter: '</response>',
        );
        final result = converter.parseResponse(
          '<response>{"value": "test"}</response>',
        );
        expect(result, equals({'value': 'test'}));
      });

      test('throws on invalid JSON', () {
        final schema = ObjectSchema({'value': StringSchema()});
        final converter = JsonSchemaConverter(schema: schema);
        expect(
          () => converter.parseResponse('{"value": invalid}'),
          throwsA(isA<JsonSchemaConverterException>().having(
            (e) => e.message,
            'message',
            contains('Invalid JSON format'),
          )),
        );
      });

      test('throws on schema validation failure', () {
        final schema = ObjectSchema(
          {'value': StringSchema()},
          required: ['value'],
        );
        final converter = JsonSchemaConverter(schema: schema);
        expect(
          () => converter.parseResponse('{}'),
          throwsA(isA<JsonSchemaConverterException>().having(
            (e) => e.message,
            'message',
            contains('Validation error'),
          )),
        );
      });
    });

    group('Response Formatting', () {
      test('generates correct response prompt', () {
        final schema = ObjectSchema({'value': StringSchema()});
        final converter = JsonSchemaConverter(
          schema: schema,
          startDelimeter: '<start>',
          endDelimeter: '</end>',
          stopSequence: '<stop>',
        );
        final prompt = converter.toResponsePrompt();

        expect(prompt, contains('<schema>'));
        expect(prompt, contains('</schema>'));
        expect(prompt, contains('<start>'));
        expect(prompt, contains('</end>'));
        expect(prompt, contains('<stop>'));
        expect(prompt, contains(converter.toSchemaString()));
      });
    });
  });
}
