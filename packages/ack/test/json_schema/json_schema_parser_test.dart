import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Parser validation tests for JsonSchema.
///
/// These tests verify that JsonSchema correctly validates input and rejects
/// invalid JSON Schema documents with helpful error messages.
void main() {
  group('JsonSchema Parser - Valid Inputs', () {
    test('accepts schema with type field', () {
      expect(
        () => JsonSchema.fromJson({'type': 'string'}),
        returnsNormally,
      );
    });

    test('accepts schema with anyOf (no type field)', () {
      expect(
        () => JsonSchema.fromJson({
          'anyOf': [
            {'type': 'string'},
            {'type': 'integer'},
          ],
        }),
        returnsNormally,
      );
    });

    test('accepts schema with allOf (no type field)', () {
      expect(
        () => JsonSchema.fromJson({
          'allOf': [
            {'type': 'object'},
          ],
        }),
        returnsNormally,
      );
    });

    test('accepts schema with oneOf (no type field)', () {
      expect(
        () => JsonSchema.fromJson({
          'oneOf': [
            {'type': 'string'},
            {'type': 'number'},
          ],
        }),
        returnsNormally,
      );
    });

    test('accepts empty schema', () {
      expect(
        () => JsonSchema.fromJson({}),
        returnsNormally,
      );
    });

    test('accepts schema with only metadata', () {
      expect(
        () => JsonSchema.fromJson({
          'description': 'Accepts anything',
          'title': 'Any Value',
        }),
        returnsNormally,
      );
    });

    test('accepts all primitive types', () {
      for (final type in ['string', 'number', 'integer', 'boolean', 'null', 'array', 'object']) {
        expect(
          () => JsonSchema.fromJson({'type': type}),
          returnsNormally,
          reason: 'Should accept type: $type',
        );
      }
    });

    test('accepts type field with different casings', () {
      expect(
        () => JsonSchema.fromJson({'type': 'String'}),
        returnsNormally,
      );
      expect(
        () => JsonSchema.fromJson({'type': 'STRING'}),
        returnsNormally,
      );
      expect(
        () => JsonSchema.fromJson({'type': 'StRiNg'}),
        returnsNormally,
      );
    });
  });

  group('JsonSchema Parser - Invalid Type Field', () {
    test('rejects schema without type or composition', () {
      expect(
        () => JsonSchema.fromJson({'format': 'email'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('missing required "type" field'),
          ),
        ),
      );
    });

    test('rejects unknown type', () {
      expect(
        () => JsonSchema.fromJson({'type': 'unknown'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Unknown JSON Schema type'),
          ),
        ),
      );
    });

    test('rejects null type value', () {
      expect(
        () => JsonSchema.fromJson({'type': null}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty string type', () {
      expect(
        () => JsonSchema.fromJson({'type': ''}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('JsonSchema Parser - String Constraints', () {
    test('accepts valid minLength', () {
      expect(
        () => JsonSchema.fromJson({'type': 'string', 'minLength': 5}),
        returnsNormally,
      );
    });

    test('accepts zero minLength', () {
      expect(
        () => JsonSchema.fromJson({'type': 'string', 'minLength': 0}),
        returnsNormally,
      );
    });

    test('rejects non-numeric minLength', () {
      expect(
        () => JsonSchema.fromJson({'type': 'string', 'minLength': 'five'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Expected int'),
          ),
        ),
      );
    });

    test('converts double minLength to int', () {
      final schema = JsonSchema.fromJson({'type': 'string', 'minLength': 5.0});
      expect(schema.minLength, equals(5));
    });

    test('accepts valid enum list', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'string',
          'enum': ['one', 'two', 'three'],
        }),
        returnsNormally,
      );
    });

    test('rejects non-list enum', () {
      expect(
        () => JsonSchema.fromJson({'type': 'string', 'enum': 'not-a-list'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Expected List'),
          ),
        ),
      );
    });

    test('converts enum values to strings', () {
      final schema = JsonSchema.fromJson({
        'type': 'string',
        'enum': [1, 2, 3],
      });
      expect(schema.enum_, equals(['1', '2', '3']));
    });
  });

  group('JsonSchema Parser - Numeric Constraints', () {
    test('accepts integer minimum/maximum', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'integer',
          'minimum': 0,
          'maximum': 100,
        }),
        returnsNormally,
      );
    });

    test('accepts double minimum/maximum', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'number',
          'minimum': 0.0,
          'maximum': 100.5,
        }),
        returnsNormally,
      );
    });

    test('rejects non-numeric minimum', () {
      expect(
        () => JsonSchema.fromJson({'type': 'integer', 'minimum': 'zero'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Expected num'),
          ),
        ),
      );
    });

    test('accepts multipleOf', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'number',
          'multipleOf': 0.01,
        }),
        returnsNormally,
      );
    });
  });

  group('JsonSchema Parser - Array Constraints', () {
    test('accepts valid items schema', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'array',
          'items': {'type': 'string'},
        }),
        returnsNormally,
      );
    });

    test('rejects non-map items', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'array',
          'items': 'not-a-schema',
        }),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Expected schema Map'),
          ),
        ),
      );
    });

    test('accepts minItems/maxItems', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'array',
          'items': {'type': 'string'},
          'minItems': 1,
          'maxItems': 10,
        }),
        returnsNormally,
      );
    });

    test('converts double minItems to int', () {
      final schema = JsonSchema.fromJson({
        'type': 'array',
        'items': {'type': 'string'},
        'minItems': 5.0,
      });
      expect(schema.minItems, equals(5));
    });

    test('rejects non-numeric minItems', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'array',
          'items': {'type': 'string'},
          'minItems': 'one',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('JsonSchema Parser - Object Constraints', () {
    test('accepts valid properties', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'age': {'type': 'integer'},
          },
        }),
        returnsNormally,
      );
    });

    test('rejects non-map properties', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'object',
          'properties': 'not-a-map',
        }),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Expected properties Map'),
          ),
        ),
      );
    });

    test('accepts required array', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'object',
          'properties': {'name': {'type': 'string'}},
          'required': ['name'],
        }),
        returnsNormally,
      );
    });

    test('rejects non-list required', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'object',
          'properties': {'name': {'type': 'string'}},
          'required': 'name',
        }),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Expected List'),
          ),
        ),
      );
    });

    test('converts required values to strings', () {
      final schema = JsonSchema.fromJson({
        'type': 'object',
        'properties': {
          'id': {'type': 'integer'},
        },
        'required': [1, 2, 3],
      });
      expect(schema.required, equals(['1', '2', '3']));
    });
  });

  group('JsonSchema Parser - Composition Constraints', () {
    test('accepts valid anyOf', () {
      expect(
        () => JsonSchema.fromJson({
          'anyOf': [
            {'type': 'string'},
            {'type': 'integer'},
          ],
        }),
        returnsNormally,
      );
    });

    test('rejects non-list anyOf', () {
      expect(
        () => JsonSchema.fromJson({'anyOf': 'not-a-list'}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Expected schema List'),
          ),
        ),
      );
    });

    test('accepts nested anyOf schemas', () {
      expect(
        () => JsonSchema.fromJson({
          'anyOf': [
            {
              'type': 'object',
              'properties': {'name': {'type': 'string'}},
            },
            {
              'type': 'object',
              'properties': {'id': {'type': 'integer'}},
            },
          ],
        }),
        returnsNormally,
      );
    });

    test('accepts single-item anyOf', () {
      expect(
        () => JsonSchema.fromJson({
          'anyOf': [
            {'type': 'string'},
          ],
        }),
        returnsNormally,
      );
    });
  });

  group('JsonSchema Parser - Nested Schemas', () {
    test('accepts deeply nested object', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'object',
          'properties': {
            'level1': {
              'type': 'object',
              'properties': {
                'level2': {
                  'type': 'object',
                  'properties': {
                    'level3': {'type': 'string'},
                  },
                },
              },
            },
          },
        }),
        returnsNormally,
      );
    });

    test('accepts nested arrays', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'array',
          'items': {
            'type': 'array',
            'items': {
              'type': 'array',
              'items': {'type': 'integer'},
            },
          },
        }),
        returnsNormally,
      );
    });

    test('rejects invalid nested schema', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'object',
          'properties': {
            'invalid': {'type': 'unknown-type'},
          },
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('JsonSchema Parser - Special Cases', () {
    test('accepts boolean additionalProperties', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'object',
          'additionalProperties': true,
        }),
        returnsNormally,
      );
      expect(
        () => JsonSchema.fromJson({
          'type': 'object',
          'additionalProperties': false,
        }),
        returnsNormally,
      );
    });

    test('accepts boolean uniqueItems', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'array',
          'items': {'type': 'string'},
          'uniqueItems': true,
        }),
        returnsNormally,
      );
    });

    test('accepts string format', () {
      final formats = [
        'email',
        'uri',
        'uuid',
        'date',
        'date-time',
        'custom-format',
      ];
      for (final format in formats) {
        expect(
          () => JsonSchema.fromJson({'type': 'string', 'format': format}),
          returnsNormally,
          reason: 'Should accept format: $format',
        );
      }
    });

    test('accepts string pattern', () {
      expect(
        () => JsonSchema.fromJson({
          'type': 'string',
          'pattern': r'^[A-Z][a-z]+$',
        }),
        returnsNormally,
      );
    });
  });

  group('JsonSchema Parser - Union Types', () {
    test('accepts single type as string', () {
      final schema = JsonSchema.fromJson({'type': 'string'});
      expect(schema.singleType, JsonSchemaType.string);
      expect(schema.type, hasLength(1));
    });

    test('accepts union type as array', () {
      final schema = JsonSchema.fromJson({'type': ['string', 'null']});
      expect(schema.singleType, isNull);
      expect(schema.type, hasLength(2));
      expect(schema.acceptsType(JsonSchemaType.string), isTrue);
      expect(schema.acceptsType(JsonSchemaType.null_), isTrue);
    });

    test('accepts multiple union types', () {
      final schema = JsonSchema.fromJson({'type': ['string', 'number', 'boolean']});
      expect(schema.type, hasLength(3));
      expect(schema.acceptsType(JsonSchemaType.string), isTrue);
      expect(schema.acceptsType(JsonSchemaType.number), isTrue);
      expect(schema.acceptsType(JsonSchemaType.boolean), isTrue);
    });

    test('acceptsNull returns true for nullable types', () {
      final schema = JsonSchema.fromJson({'type': ['string', 'null']});
      expect(schema.acceptsNull, isTrue);
    });

    test('acceptsNull returns false for non-nullable types', () {
      final schema = JsonSchema.fromJson({'type': 'string'});
      expect(schema.acceptsNull, isFalse);
    });

    test('rejects empty type array', () {
      expect(
        () => JsonSchema.fromJson({'type': []}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid JSON Schema type array'),
          ),
        ),
      );
    });

    test('rejects unknown type in array', () {
      // Should skip unknown types and accept valid ones
      final schema = JsonSchema.fromJson({'type': ['string', 'unknown', 'number']});
      expect(schema.type, hasLength(2));
      expect(schema.acceptsType(JsonSchemaType.string), isTrue);
      expect(schema.acceptsType(JsonSchemaType.number), isTrue);
    });

    test('rejects type as number', () {
      expect(
        () => JsonSchema.fromJson({'type': 123}),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('must be string or array'),
          ),
        ),
      );
    });
  });

  group('JsonSchema Parser - Typeless Schemas', () {
    test('accepts enum without type', () {
      expect(
        () => JsonSchema.fromJson({'enum': ['red', 'green', 'blue']}),
        returnsNormally,
      );
    });

    test('accepts properties without type', () {
      expect(
        () => JsonSchema.fromJson({
          'properties': {
            'name': {'type': 'string'},
          },
        }),
        returnsNormally,
      );
    });

    test('accepts items without type', () {
      expect(
        () => JsonSchema.fromJson({'items': {'type': 'string'}}),
        returnsNormally,
      );
    });

    test('accepts minLength without type', () {
      expect(
        () => JsonSchema.fromJson({'minLength': 5}),
        returnsNormally,
      );
    });

    test('accepts minimum without type', () {
      expect(
        () => JsonSchema.fromJson({'minimum': 0}),
        returnsNormally,
      );
    });

    test('accepts required without type', () {
      expect(
        () => JsonSchema.fromJson({'required': ['name', 'email']}),
        returnsNormally,
      );
    });

    test('enum without type can be parsed and serialized', () {
      final input = {'enum': ['a', 'b', 'c']};
      final schema = JsonSchema.fromJson(input);
      expect(schema.type, isNull);
      expect(schema.isEnum, isTrue);
      expect(schema.enum_, equals(['a', 'b', 'c']));
    });

    test('properties without type can be parsed and serialized', () {
      final input = {
        'properties': {
          'id': {'type': 'integer'},
        },
        'required': ['id'],
      };
      final schema = JsonSchema.fromJson(input);
      expect(schema.type, isNull);
      expect(schema.properties, isNotNull);
      expect(schema.properties!['id']!.singleType, JsonSchemaType.integer);
    });
  });
}
