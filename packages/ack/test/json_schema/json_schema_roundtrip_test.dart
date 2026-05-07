import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Round-trip tests for JsonSchema serialization and deserialization.
///
/// These tests verify that JsonSchema can parse JSON Schema documents and
/// serialize them back to JSON without loss of information.
///
/// Pattern: JSON → JsonSchema → JSON (should be identical)
void main() {
  group('JsonSchema Round-Trip - Primitive Types', () {
    test('string schema round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'string',
        'minLength': 5,
        'maxLength': 100,
        'pattern': r'^[A-Z]',
        'format': 'email',
        'title': 'Email Address',
        'description': 'User email',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('integer schema round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'integer',
        'minimum': 0,
        'maximum': 120,
        'title': 'Age',
        'description': 'User age',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('number schema round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'number',
        'minimum': 0.0,
        'maximum': 999.99,
        'exclusiveMinimum': 0.0,
        'exclusiveMaximum': 1000.0,
        'multipleOf': 0.01,
        'description': 'Price',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('boolean schema round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'boolean',
        'title': 'Active Flag',
        'description': 'Whether user is active',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('null schema round-trips correctly', () {
      final input = <String, Object?>{'type': 'null'};

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });
  });

  group('JsonSchema Round-Trip - String Constraints', () {
    test('string with enum round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'string',
        'enum': ['admin', 'user', 'guest'],
        'description': 'User role',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('string with all constraints round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'string',
        'minLength': 3,
        'maxLength': 50,
        'pattern': r'^[a-z]+$',
        'format': 'hostname',
        'enum': ['alpha', 'beta', 'gamma'],
        'title': 'Environment',
        'description': 'Deployment environment',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });
  });

  group('JsonSchema Round-Trip - Numeric Constraints', () {
    test('integer with all constraints round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'integer',
        'minimum': -100,
        'maximum': 100,
        'exclusiveMinimum': -100,
        'exclusiveMaximum': 100,
        'multipleOf': 5,
        'description': 'Score',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('number with mixed int/double constraints round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'number',
        'minimum': 0,
        'maximum': 100.5,
        'multipleOf': 0.5,
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });
  });

  group('JsonSchema Round-Trip - Array Schemas', () {
    test('array schema round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'array',
        'items': {'type': 'string'},
        'minItems': 1,
        'maxItems': 10,
        'uniqueItems': true,
        'description': 'Tags',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('array of objects round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'array',
        'items': {
          'type': 'object',
          'properties': {
            'id': {'type': 'integer'},
            'name': {'type': 'string'},
          },
          'required': ['id', 'name'],
        },
        'minItems': 0,
        'maxItems': 100,
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('nested array round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'array',
        'items': {
          'type': 'array',
          'items': {'type': 'integer'},
        },
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });
  });

  group('JsonSchema Round-Trip - Object Schemas', () {
    test('simple object round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
          'age': {'type': 'integer'},
        },
        'required': ['name'],
        'additionalProperties': false,
        'title': 'User',
        'description': 'User object',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('nested object round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'object',
        'properties': {
          'user': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
              'email': {'type': 'string', 'format': 'email'},
            },
            'required': ['name', 'email'],
          },
          'settings': {
            'type': 'object',
            'properties': {
              'theme': {'type': 'string'},
              'notifications': {'type': 'boolean'},
            },
          },
        },
        'required': ['user'],
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('object with no properties round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'object',
        'additionalProperties': true,
        'description': 'Arbitrary object',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });
  });

  group('JsonSchema Round-Trip - Composition', () {
    test('anyOf schema round-trips correctly', () {
      final input = <String, Object?>{
        'anyOf': [
          {'type': 'string'},
          {'type': 'integer'},
          {'type': 'boolean'},
        ],
        'description': 'Multi-type field',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('allOf schema round-trips correctly', () {
      final input = <String, Object?>{
        'allOf': [
          {
            'type': 'object',
            'properties': {
              'id': {'type': 'integer'},
            },
          },
          {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
            },
          },
        ],
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('oneOf schema round-trips correctly', () {
      final input = <String, Object?>{
        'oneOf': [
          {'type': 'string', 'format': 'email'},
          {'type': 'string', 'format': 'uri'},
        ],
        'title': 'Contact',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('nullable pattern (anyOf with null) round-trips correctly', () {
      final input = <String, Object?>{
        'anyOf': [
          {'type': 'string'},
          {'type': 'null'},
        ],
        'description': 'Nullable string',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });
  });

  group('JsonSchema Round-Trip - Edge Cases', () {
    test('empty schema round-trips correctly', () {
      final input = <String, Object?>{};

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('schema with only description round-trips correctly', () {
      final input = <String, Object?>{'description': 'Accepts anything'};

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('schema with only title round-trips correctly', () {
      final input = <String, Object?>{'title': 'Any Value'};

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('anyOf without top-level type round-trips correctly', () {
      final input = <String, Object?>{
        'anyOf': [
          {
            'type': 'object',
            'properties': {
              'type': {'type': 'string'},
            },
          },
          {
            'type': 'object',
            'properties': {
              'kind': {'type': 'string'},
            },
          },
        ],
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('schema with zero-value constraints round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'integer',
        'minimum': 0,
        'maximum': 0,
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('array with zero-value constraints round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'array',
        'items': {'type': 'string'},
        'minItems': 0,
        'maxItems': 0,
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('string with empty string values round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'string',
        'pattern': '',
        'format': 'custom-format',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });
  });

  group('JsonSchema Round-Trip - Complex Scenarios', () {
    test('comprehensive user schema round-trips correctly', () {
      final input = <String, Object?>{
        'type': 'object',
        'properties': {
          'id': {'type': 'integer', 'minimum': 1},
          'email': {
            'type': 'string',
            'format': 'email',
            'minLength': 5,
            'maxLength': 100,
          },
          'name': {'type': 'string', 'minLength': 2, 'maxLength': 50},
          'age': {
            'anyOf': [
              {'type': 'integer', 'minimum': 0, 'maximum': 120},
              {'type': 'null'},
            ],
          },
          'tags': {
            'anyOf': [
              {
                'type': 'array',
                'items': {'type': 'string'},
              },
              {'type': 'null'},
            ],
          },
          'isActive': {'type': 'boolean'},
          'metadata': {'description': 'Any additional data'},
        },
        'required': ['id', 'email', 'name', 'isActive'],
        'additionalProperties': false,
        'title': 'User',
        'description': 'A comprehensive user object',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('discriminated union round-trips correctly', () {
      final input = <String, Object?>{
        'anyOf': [
          {
            'type': 'object',
            'properties': {
              'type': {
                'type': 'string',
                'enum': ['card'],
              },
              'cardNumber': {'type': 'string'},
              'cvv': {'type': 'string'},
            },
            'required': ['type', 'cardNumber', 'cvv'],
          },
          {
            'type': 'object',
            'properties': {
              'type': {
                'type': 'string',
                'enum': ['bank'],
              },
              'accountNumber': {'type': 'string'},
              'routingNumber': {'type': 'string'},
            },
            'required': ['type', 'accountNumber', 'routingNumber'],
          },
        ],
        'description': 'Payment method',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });
  });

  group('JsonSchema Round-Trip - Union Types', () {
    test('single type as string round-trips correctly', () {
      final input = <String, Object?>{'type': 'string'};

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('union type array round-trips correctly', () {
      final input = <String, Object?>{
        'type': ['string', 'null'],
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(
        output,
        equals({
          'anyOf': [
            {'type': 'string'},
            {'type': 'null'},
          ],
        }),
      );
    });

    test('multiple union types round-trip correctly', () {
      final input = <String, Object?>{
        'type': ['string', 'number', 'boolean'],
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(
        output,
        equals({
          'anyOf': [
            {'type': 'string'},
            {'type': 'number'},
            {'type': 'boolean'},
          ],
        }),
      );
    });

    test('nullable string with constraints round-trips correctly', () {
      final input = <String, Object?>{
        'type': ['string', 'null'],
        'minLength': 5,
        'maxLength': 100,
        'pattern': r'^[A-Z]',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(
        output,
        equals({
          'anyOf': [
            {
              'type': 'string',
              'minLength': 5,
              'maxLength': 100,
              'pattern': r'^[A-Z]',
            },
            {'type': 'null'},
          ],
        }),
      );
    });

    test('union type with description round-trips correctly', () {
      final input = <String, Object?>{
        'type': ['string', 'integer', 'null'],
        'description': 'A flexible value that can be string, int, or null',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(
        output,
        equals({
          'description': 'A flexible value that can be string, int, or null',
          'anyOf': [
            {'type': 'string'},
            {'type': 'integer'},
            {'type': 'null'},
          ],
        }),
      );
    });
  });

  group('JsonSchema Round-Trip - Nullable Composition', () {
    test('anyOf + nullable without null branch adds null schema', () {
      // When anyOf exists AND nullable=true AND no null branch present,
      // toJson should add a null branch (valid JSON Schema), NOT emit
      // "nullable: true" (OpenAPI style, invalid JSON Schema).
      final schema = JsonSchema(
        anyOf: [JsonSchema(type: JsonSchemaType.string)],
        nullable: true,
      );
      final json = schema.toJson();

      // Verify null branch was added to anyOf
      final anyOf = json['anyOf'] as List;
      expect(anyOf, hasLength(2));
      expect(anyOf[1], equals({'type': 'null'}));
      // Verify nullable property is NOT emitted (that's OpenAPI, not JSON Schema)
      expect(json.containsKey('nullable'), isFalse);
    });

    test('oneOf + nullable wraps composition instead of adding a branch', () {
      final schema = JsonSchema(
        oneOf: [JsonSchema(type: JsonSchemaType.string)],
        nullable: true,
      );
      final json = schema.toJson();

      final anyOf = json['anyOf'] as List;
      expect(anyOf, hasLength(2));
      expect(anyOf[0], {
        'oneOf': [
          {'type': 'string'},
        ],
      });
      expect(anyOf[1], equals({'type': 'null'}));
      expect(json.containsKey('nullable'), isFalse);
    });

    test('oneOf nullable branch is not duplicated by top-level nullable', () {
      final schema = JsonSchema(
        oneOf: [JsonSchema(type: JsonSchemaType.string, nullable: true)],
        nullable: true,
      );
      final json = schema.toJson();

      final anyOf = json['anyOf'] as List;
      expect(anyOf, hasLength(2));
      final nonNullSchema = anyOf[0] as Map<String, Object?>;
      final oneOf = nonNullSchema['oneOf'] as List;
      expect(oneOf, hasLength(1));
      expect(anyOf[1], equals({'type': 'null'}));
      expect(json.containsKey('nullable'), isFalse);
    });

    test('oneOf null branch is parsed as nullable', () {
      final schema = JsonSchema.fromJson({
        'oneOf': [
          {'type': 'string'},
          {'type': 'null'},
        ],
      });

      expect(schema.nullable, isTrue);
      expect(schema.acceptsNull, isTrue);
    });

    test('anyOf with existing null branch does not duplicate', () {
      final schema = JsonSchema(
        anyOf: [
          JsonSchema(type: JsonSchemaType.string),
          JsonSchema(type: JsonSchemaType.null_),
        ],
        nullable: true,
      );
      final json = schema.toJson();

      // Should not add another null branch
      final anyOf = json['anyOf'] as List;
      expect(anyOf, hasLength(2));
      expect(json.containsKey('nullable'), isFalse);
    });

    test('simple type + nullable wraps in anyOf with null', () {
      // Existing behavior: type + nullable wraps in anyOf
      final schema = JsonSchema(type: JsonSchemaType.string, nullable: true);
      final json = schema.toJson();

      final anyOf = json['anyOf'] as List;
      expect(anyOf, hasLength(2));
      expect(anyOf[0], equals({'type': 'string'}));
      expect(anyOf[1], equals({'type': 'null'}));
    });

    test('type with oneOf and nullable wraps the whole non-null schema', () {
      final schema = JsonSchema(
        type: JsonSchemaType.string,
        oneOf: [
          JsonSchema(format: 'ipv4'),
          JsonSchema(format: 'ipv6'),
        ],
        nullable: true,
      );

      final json = schema.toJson();

      final anyOf = json['anyOf'] as List;
      expect(anyOf, hasLength(2));
      expect(anyOf[0], {
        'type': 'string',
        'oneOf': [
          {'format': 'ipv4'},
          {'format': 'ipv6'},
        ],
      });
      expect(anyOf[1], {'type': 'null'});
    });
  });

  group('JsonSchema Round-Trip - Null-valued annotations', () {
    test('explicit const null round-trips', () {
      final schema = JsonSchema.fromJson({'const': null});

      expect(schema.hasConstValue, isTrue);
      expect(schema.constValue, isNull);
      expect(schema.toJson(), equals({'const': null}));
    });

    test('explicit default null round-trips', () {
      final schema = JsonSchema.fromJson({'default': null});

      expect(schema.hasDefaultValue, isTrue);
      expect(schema.defaultValue, isNull);
      expect(schema.toJson(), equals({'default': null}));
    });

    test('constructor can represent explicit const null', () {
      const schema = JsonSchema(hasConstValue: true);

      expect(schema.toJson(), equals({'const': null}));
    });

    test('copyWith can set explicit null annotations', () {
      const schema = JsonSchema(
        type: JsonSchemaType.string,
        constValue: 'fixed',
        defaultValue: 'fallback',
      );

      final copy = schema.copyWith(constValue: null, defaultValue: null);

      expect(copy.hasConstValue, isTrue);
      expect(copy.hasDefaultValue, isTrue);
      expect(copy.toJson(), {'type': 'string', 'const': null, 'default': null});
    });

    test('copyWith clears hidden annotation values when flags are false', () {
      const schema = JsonSchema(
        type: JsonSchemaType.string,
        constValue: 'fixed',
        defaultValue: 'fallback',
      );

      final copy = schema.copyWith(
        hasConstValue: false,
        hasDefaultValue: false,
      );

      expect(copy.constValue, isNull);
      expect(copy.defaultValue, isNull);
      expect(copy.toJson(), equals({'type': 'string'}));
    });
  });

  group('JsonSchema Round-Trip - Typeless Schemas', () {
    test('enum without type round-trips correctly', () {
      final input = <String, Object?>{
        'enum': ['red', 'green', 'blue'],
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('properties without type round-trips correctly', () {
      final input = <String, Object?>{
        'properties': {
          'name': {'type': 'string'},
          'age': {'type': 'integer'},
        },
        'required': ['name'],
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('items without type round-trips correctly', () {
      final input = <String, Object?>{
        'items': {'type': 'string'},
        'minItems': 1,
        'maxItems': 10,
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('string constraints without type round-trips correctly', () {
      final input = <String, Object?>{
        'minLength': 5,
        'maxLength': 100,
        'pattern': r'^\d+$',
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });

    test('numeric constraints without type round-trips correctly', () {
      final input = <String, Object?>{
        'minimum': 0,
        'maximum': 100,
        'multipleOf': 5,
      };

      final schema = JsonSchema.fromJson(input);
      final output = schema.toJson();

      expect(output, equals(input));
    });
  });
}
