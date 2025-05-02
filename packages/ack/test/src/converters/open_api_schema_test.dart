import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('OpenApiSchemaConverter Tests', () {
    group('Schema Type Conversion', () {
      test('converts basic schema types correctly', () {
        final schema = ObjectSchema({
          'string': StringSchema(),
          'integer': IntegerSchema(),
          'double': DoubleSchema(),
          'boolean': BooleanSchema(),
        });
        final converter = OpenApiSchemaConverter(schema: schema);
        expect(
          converter.toSchema(),
          equals({
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
        final converter = OpenApiSchemaConverter(schema: schema);
        expect(
          converter.toSchema(),
          equals({
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
        final converter = OpenApiSchemaConverter(schema: schema);
        expect(
          converter.toSchema(),
          equals({
            'type': 'object',
            'properties': {
              'pet': {
                'discriminator': {'propertyName': 'animalType'},
                'oneOf': [
                  {
                    'type': 'object',
                    'properties': {
                      'animalType': {'type': 'string'},
                      'name': {'type': 'string'},
                    },
                    'required': ['animalType', 'name'],
                    'additionalProperties': false,
                  },
                  {
                    'type': 'object',
                    'properties': {
                      'animalType': {'type': 'string'},
                      'breed': {'type': 'string'},
                    },
                    'required': ['animalType', 'breed'],
                    'additionalProperties': false,
                  },
                ],
              },
            },
            'additionalProperties': false,
          }),
        );
      });
    });

    group('Schema Properties', () {
      test('handles nullable schemas', () {
        final schema = ObjectSchema({
          'optional': StringSchema().nullable(),
        });
        final converter = OpenApiSchemaConverter(schema: schema);
        expect(
          converter.toSchema(),
          equals({
            'type': 'object',
            'properties': {
              'optional': {
                'type': 'string',
                'nullable': true,
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
        final converter = OpenApiSchemaConverter(schema: schema);
        expect(
          converter.toSchema(),
          equals({
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
        final converter = OpenApiSchemaConverter(schema: schema);
        expect(
          converter.toSchema(),
          equals({
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
    });

    group('Response Parsing', () {
      test('parses raw JSON response', () {
        final schema = ObjectSchema({'value': StringSchema()});
        final converter = OpenApiSchemaConverter(schema: schema);
        final mapValue = {
          'value': 'test',
        };
        final result = converter.parseResponse(jsonEncode(mapValue));
        expect(result, equals(mapValue));
      });

      test('parses delimited response', () {
        final schema = ObjectSchema({'value': StringSchema()});
        final converter = OpenApiSchemaConverter(
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
        final converter = OpenApiSchemaConverter(schema: schema);
        expect(
          () => converter.parseResponse('{"value": invalid}'),
          throwsA(isA<OpenApiConverterException>().having(
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
        final converter = OpenApiSchemaConverter(schema: schema);
        expect(
          () => converter.parseResponse('{}'),
          throwsA(isA<OpenApiConverterException>().having(
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
        final converter = OpenApiSchemaConverter(
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
