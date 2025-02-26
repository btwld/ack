import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('OpenApiSchemaConverter Tests', () {
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
  });

  group('OpenApiSchemaConverter.toJson', () {
    test('should return a valid JSON string matching toSchema()', () {
      final schema = ObjectSchema({'name': StringSchema()});
      final converter = OpenApiSchemaConverter(schema: schema);
      final jsonString = converter.toSchemaString();
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      expect(jsonMap, equals(converter.toSchema()));
    });
  });

  group('OpenApiSchemaConverter.toResponsePrompt', () {
    test('should wrap JSON with the correct start and end delimiters', () {
      final schema = ObjectSchema({'name': StringSchema()});
      final converter = OpenApiSchemaConverter(
        schema: schema,
        startDelimeter: '<response2>',
        endDelimeter: '</response2>',
        stopSequence: '<stop_response2>',
      );
      final responsePrompt = converter.toResponsePrompt();
      expect(responsePrompt.contains(converter.startDelimeter), isTrue);
      final schemaString = converter.toSchemaString();
      expect(responsePrompt.contains(schemaString), isTrue);
      expect(
        responsePrompt
            .trim()
            .endsWith('${converter.endDelimeter}\n${converter.stopSequence}'),
        isTrue,
      );
    });
  });

  group('OpenApiSchemaConverter.parseResponse', () {
    test('should successfully parse a valid response', () {
      final schema =
          ObjectSchema({'value': StringSchema()}, required: ['value']);
      final converter = OpenApiSchemaConverter(
        schema: schema,
        startDelimeter: '<start>',
        endDelimeter: '<end>',
      );
      final validJson = '{"value": "test"}';
      final response = '<start>$validJson<end>';
      final result = converter.parseResponse(response);
      expect(result, equals({"value": "test"}));
    });

    test('should throw a JSON decode error for invalid JSON content', () {
      final schema =
          ObjectSchema({'value': StringSchema()}, required: ['value']);
      final converter = OpenApiSchemaConverter(
        schema: schema,
        startDelimeter: '<start>',
        endDelimeter: '<end>',
      );
      final invalidJson = '{"value": "test"';
      final response = '<start>$invalidJson<end>';
      expect(
        () => converter.parseResponse(response),
        throwsA(isA<OpenApiConverterException>().having(
            (e) => e.message, 'message', contains('Invalid JSON format'))),
      );
    });

    test('should throw an unknown error when the start delimiter is missing',
        () {
      final schema =
          ObjectSchema({'value': StringSchema()}, required: ['value']);
      final converter = OpenApiSchemaConverter(
        schema: schema,
        startDelimeter: '<start>',
        endDelimeter: '<end>',
      );
      final validJson = '{"value": "test"}';
      final response = '$validJson<end>';
      expect(
        () => converter.parseResponse(response),
        throwsA(isA<OpenApiConverterException>().having(
            (e) => e.message, 'message', contains('Invalid JSON format'))),
      );
    });

    test('should throw an unknown error when the end delimiter is missing', () {
      final schema =
          ObjectSchema({'value': StringSchema()}, required: ['value']);
      final converter = OpenApiSchemaConverter(
        schema: schema,
        startDelimeter: '<start>',
        endDelimeter: '<end>',
      );
      final validJson = '{"value": "test"}';
      final response = '<start>$validJson';
      expect(
        () => converter.parseResponse(response),
        throwsA(isA<OpenApiConverterException>()
            .having((e) => e.message, 'message', contains('Unknown error'))),
      );
    });

    test('should throw a validation error when schema validation fails', () {
      final schema =
          ObjectSchema({'value': StringSchema()}, required: ['value']);
      final converter = OpenApiSchemaConverter(
        schema: schema,
        startDelimeter: '<start>',
        endDelimeter: '<end>',
      );
      final invalidData = '{}';
      final response = '<start>$invalidData<end>';
      expect(
        () => converter.parseResponse(response),
        throwsA(isA<OpenApiConverterException>()
            .having((e) => e.message, 'message', contains('Validation error'))),
      );
    });
  });

  group('OpenApiConverterException', () {
    test('toString should include the error message and details', () {
      final exception =
          OpenApiConverterException('Test error', error: 'some error');
      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('some error'));
    });

    test(
        'isValidationError should return true when an AckException is provided',
        () {
      final schema = ObjectSchema({'value': BooleanSchema()});
      final resultErrors =
          schema.validate({'value': 'not_boolean'}).getErrors();
      final ackEx = AckException(resultErrors);
      final exception = OpenApiConverterException.validationError(ackEx);
      expect(exception.isValidationError, isTrue);
    });
  });
}
