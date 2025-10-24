import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// ACK integration tests for JsonSchema.
///
/// These tests verify that JsonSchema works correctly with ACK's toJsonSchema()
/// output, ensuring the typed abstraction can parse and work with real ACK
/// schema conversions.
void main() {
  group('JsonSchema ACK Integration - String Schemas', () {
    test('parses basic string schema', () {
      final ackSchema = Ack.string();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.string);
      expect(jsonSchema.format, isNull);
      expect(jsonSchema.minLength, isNull);
      expect(jsonSchema.maxLength, isNull);
    });

    test('parses string with constraints', () {
      final ackSchema = Ack.string().minLength(5).maxLength(100);
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.string);
      expect(jsonSchema.minLength, 5);
      expect(jsonSchema.maxLength, 100);
    });

    test('parses string with email format', () {
      final ackSchema = Ack.string().email();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.string);
      expect(jsonSchema.format, 'email');
      expect(jsonSchema.wellKnownFormat, WellKnownFormat.email);
    });

    test('parses string with url format', () {
      final ackSchema = Ack.string().url();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.string);
      expect(jsonSchema.format, 'uri');
      expect(jsonSchema.wellKnownFormat, WellKnownFormat.uri);
    });

    test('parses string with uuid format', () {
      final ackSchema = Ack.string().uuid();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.string);
      expect(jsonSchema.format, 'uuid');
      expect(jsonSchema.wellKnownFormat, WellKnownFormat.uuid);
    });

    test('parses string with pattern', () {
      final ackSchema = Ack.string().matches(r'^[A-Z]');
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.string);
      expect(jsonSchema.pattern, r'^[A-Z]');
    });

    test('parses nullable string', () {
      final ackSchema = Ack.string().nullable();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      // Nullable schemas use anyOf pattern
      expect(jsonSchema.anyOf, isNotNull);
      expect(jsonSchema.anyOf, hasLength(2));
      expect(
        jsonSchema.anyOf!.any((s) => s.singleType == JsonSchemaType.string),
        isTrue,
      );
      expect(
        jsonSchema.anyOf!.any((s) => s.singleType == JsonSchemaType.null_),
        isTrue,
      );
    });

    test('parses string with description', () {
      final ackSchema = Ack.string().describe('User email address');
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.string);
      expect(jsonSchema.description, 'User email address');
    });
  });

  group('JsonSchema ACK Integration - Integer Schemas', () {
    test('parses basic integer schema', () {
      final ackSchema = Ack.integer();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.integer);
    });

    test('parses integer with min/max', () {
      final ackSchema = Ack.integer().min(0).max(120);
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.integer);
      expect(jsonSchema.minimum, 0);
      expect(jsonSchema.maximum, 120);
    });

    test('parses positive integer', () {
      final ackSchema = Ack.integer().positive();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.integer);
      expect(jsonSchema.exclusiveMinimum, 0);
    });

    test('parses negative integer', () {
      final ackSchema = Ack.integer().negative();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.integer);
      expect(jsonSchema.exclusiveMaximum, 0);
    });

    test('parses nullable integer', () {
      final ackSchema = Ack.integer().nullable();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.anyOf, isNotNull);
      expect(jsonSchema.anyOf, hasLength(2));
    });
  });

  group('JsonSchema ACK Integration - Double Schemas', () {
    test('parses basic double schema', () {
      final ackSchema = Ack.double();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.number);
    });

    test('parses double with min/max', () {
      final ackSchema = Ack.double().min(0.0).max(100.5);
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.number);
      expect(jsonSchema.minimum, 0.0);
      expect(jsonSchema.maximum, 100.5);
    });

    test('parses positive double', () {
      final ackSchema = Ack.double().positive();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.number);
      expect(jsonSchema.exclusiveMinimum, 0);
    });

    test('parses nullable double', () {
      final ackSchema = Ack.double().nullable();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.anyOf, isNotNull);
      expect(jsonSchema.anyOf, hasLength(2));
    });
  });

  group('JsonSchema ACK Integration - Boolean Schemas', () {
    test('parses basic boolean schema', () {
      final ackSchema = Ack.boolean();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.boolean);
    });

    test('parses nullable boolean', () {
      final ackSchema = Ack.boolean().nullable();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.anyOf, isNotNull);
      expect(jsonSchema.anyOf, hasLength(2));
    });
  });

  group('JsonSchema ACK Integration - Any Schemas', () {
    test('parses any schema as empty', () {
      final ackSchema = Ack.any();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      // AnySchema produces empty schema
      expect(jsonSchema.singleType, isNull);
    });

    test('parses nullable any schema', () {
      final ackSchema = Ack.any().nullable();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      // Nullable AnySchema uses anyOf
      expect(jsonSchema.anyOf, isNotNull);
    });

    test('parses any with description', () {
      final ackSchema = Ack.any().describe('Accepts any value');
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.description, 'Accepts any value');
    });
  });

  group('JsonSchema ACK Integration - List Schemas', () {
    test('parses list of strings', () {
      final ackSchema = Ack.list(Ack.string());
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.array);
      expect(jsonSchema.items, isNotNull);
      expect(jsonSchema.items!.singleType, JsonSchemaType.string);
    });

    test('parses list with minItems/maxItems', () {
      final ackSchema = Ack.list(Ack.string()).minItems(1).maxItems(10);
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.array);
      expect(jsonSchema.minItems, 1);
      expect(jsonSchema.maxItems, 10);
    });

    test('parses list of objects', () {
      final ackSchema = Ack.list(
        Ack.object({
          'id': Ack.integer(),
          'name': Ack.string(),
        }),
      );
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.array);
      expect(jsonSchema.items, isNotNull);
      expect(jsonSchema.items!.singleType, JsonSchemaType.object);
      expect(jsonSchema.items!.properties, isNotNull);
      expect(jsonSchema.items!.properties!['id']!.singleType, JsonSchemaType.integer);
      expect(jsonSchema.items!.properties!['name']!.singleType, JsonSchemaType.string);
    });

    test('parses nullable list', () {
      final ackSchema = Ack.list(Ack.string()).nullable();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.anyOf, isNotNull);
      expect(jsonSchema.anyOf, hasLength(2));
    });
  });

  group('JsonSchema ACK Integration - Object Schemas', () {
    test('parses simple object', () {
      final ackSchema = Ack.object({
        'name': Ack.string(),
        'age': Ack.integer(),
      });
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.object);
      expect(jsonSchema.properties, isNotNull);
      expect(jsonSchema.properties!['name']!.singleType, JsonSchemaType.string);
      expect(jsonSchema.properties!['age']!.singleType, JsonSchemaType.integer);
      expect(jsonSchema.required, containsAll(['name', 'age']));
    });

    test('parses object with optional fields', () {
      final ackSchema = Ack.object({
        'name': Ack.string(),
        'nickname': Ack.string().optional(),
      });
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.object);
      expect(jsonSchema.properties, hasLength(2));
      expect(jsonSchema.required, contains('name'));
      expect(jsonSchema.required, isNot(contains('nickname')));
    });

    test('parses nested object', () {
      final ackSchema = Ack.object({
        'user': Ack.object({
          'name': Ack.string(),
          'email': Ack.string().email(),
        }),
      });
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.object);
      expect(jsonSchema.properties!['user']!.singleType, JsonSchemaType.object);
      expect(
        jsonSchema.properties!['user']!.properties!['name']!.singleType,
        JsonSchemaType.string,
      );
    });

    test('parses object with additionalProperties', () {
      final ackSchema = Ack.object(
        {'name': Ack.string()},
        additionalProperties: true,
      );
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.object);
      expect(jsonSchema.additionalProperties, isTrue);
    });

    test('parses nullable object', () {
      final ackSchema = Ack.object({}).nullable();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.anyOf, isNotNull);
      expect(jsonSchema.anyOf, hasLength(2));
    });
  });

  group('JsonSchema ACK Integration - AnyOf Schemas', () {
    test('parses anyOf with primitives', () {
      final ackSchema = Ack.anyOf([
        Ack.string(),
        Ack.integer(),
        Ack.boolean(),
      ]);
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.anyOf, isNotNull);
      expect(jsonSchema.anyOf, hasLength(3));
      expect(jsonSchema.anyOf![0].singleType, JsonSchemaType.string);
      expect(jsonSchema.anyOf![1].singleType, JsonSchemaType.integer);
      expect(jsonSchema.anyOf![2].singleType, JsonSchemaType.boolean);
    });

    test('parses anyOf with objects', () {
      final ackSchema = Ack.anyOf([
        Ack.object({'type': Ack.literal('text'), 'content': Ack.string()}),
        Ack.object({'type': Ack.literal('number'), 'value': Ack.integer()}),
      ]);
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.anyOf, isNotNull);
      expect(jsonSchema.anyOf, hasLength(2));
      expect(jsonSchema.anyOf![0].singleType, JsonSchemaType.object);
      expect(jsonSchema.anyOf![1].singleType, JsonSchemaType.object);
    });

    test('parses nullable anyOf', () {
      final ackSchema = Ack.anyOf([
        Ack.string(),
        Ack.integer(),
      ]).nullable();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.anyOf, isNotNull);
      // ACK wraps nullable anyOf as: anyOf([anyOf([string, integer]), null])
      expect(jsonSchema.anyOf, hasLength(2));
      // One should be the inner anyOf, one should be null
      expect(
        jsonSchema.anyOf!.any((s) => s.anyOf != null),
        isTrue,
        reason: 'Should have nested anyOf',
      );
      expect(
        jsonSchema.anyOf!.any((s) => s.singleType == JsonSchemaType.null_),
        isTrue,
        reason: 'Should have null type',
      );
    });
  });

  group('JsonSchema ACK Integration - Enum Schemas', () {
    test('parses enum schema', () {
      final ackSchema = Ack.enumValues(TestRole.values);
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.string);
      expect(jsonSchema.enum_, isNotNull);
      expect(jsonSchema.enum_, hasLength(3));
      expect(jsonSchema.isEnum, isTrue);
    });

    test('parses nullable enum', () {
      final ackSchema = Ack.enumValues(TestRole.values).nullable();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.anyOf, isNotNull);
      expect(jsonSchema.anyOf, hasLength(2));
    });
  });

  group('JsonSchema ACK Integration - Discriminated Schemas', () {
    test('parses discriminated union', () {
      final ackSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'user': Ack.object({
            'name': Ack.string(),
            'email': Ack.string(),
          }),
          'admin': Ack.object({
            'name': Ack.string(),
            'role': Ack.string(),
          }),
        },
      );
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      // Discriminated unions use anyOf
      expect(jsonSchema.anyOf, isNotNull);
      expect(jsonSchema.anyOf, hasLength(2));
      expect(jsonSchema.anyOf![0].singleType, JsonSchemaType.object);
      expect(jsonSchema.anyOf![1].singleType, JsonSchemaType.object);
    });

    test('parses nullable discriminated union', () {
      final ackSchema = Ack.discriminated(
        discriminatorKey: 'kind',
        schemas: {
          'text': Ack.object({'content': Ack.string()}),
          'image': Ack.object({'url': Ack.string().url()}),
        },
      ).nullable();
      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.anyOf, isNotNull);
      // ACK wraps nullable discriminated as: anyOf([anyOf([...discriminated...]), null])
      expect(jsonSchema.anyOf, hasLength(2));
      // One should be the inner anyOf with discriminated options, one should be null
      expect(
        jsonSchema.anyOf!.any((s) => s.anyOf != null),
        isTrue,
        reason: 'Should have nested anyOf for discriminated options',
      );
      expect(
        jsonSchema.anyOf!.any((s) => s.singleType == JsonSchemaType.null_),
        isTrue,
        reason: 'Should have null type',
      );
    });
  });

  group('JsonSchema ACK Integration - Complex Scenarios', () {
    test('parses comprehensive user schema', () {
      final ackSchema = Ack.object({
        'id': Ack.integer().positive(),
        'email': Ack.string().email().minLength(5).maxLength(100),
        'name': Ack.string().minLength(2).maxLength(50),
        'age': Ack.integer().min(0).max(120).nullable(),
        'tags': Ack.list(Ack.string()).nullable(),
        'isActive': Ack.boolean().withDefault(true),
        'metadata': Ack.any().optional(),
      }).describe('A comprehensive user object');

      final jsonMap = ackSchema.toJsonSchema();
      final jsonSchema = JsonSchema.fromJson(jsonMap);

      expect(jsonSchema.singleType, JsonSchemaType.object);
      expect(jsonSchema.description, 'A comprehensive user object');
      expect(jsonSchema.properties, hasLength(7));

      // Verify id field
      expect(jsonSchema.properties!['id']!.singleType, JsonSchemaType.integer);
      expect(jsonSchema.properties!['id']!.exclusiveMinimum, 0);

      // Verify email field
      expect(jsonSchema.properties!['email']!.singleType, JsonSchemaType.string);
      expect(jsonSchema.properties!['email']!.format, 'email');
      expect(jsonSchema.properties!['email']!.minLength, 5);
      expect(jsonSchema.properties!['email']!.maxLength, 100);

      // Verify required fields
      expect(jsonSchema.required, isNotNull);
      expect(jsonSchema.required, contains('id'));
      expect(jsonSchema.required, contains('email'));
      expect(jsonSchema.required, contains('name'));
      expect(jsonSchema.required, contains('isActive'));
      expect(jsonSchema.required, isNot(contains('metadata')));
    });

    test('round-trip ACK schema through JsonSchema', () {
      final ackSchema = Ack.object({
        'name': Ack.string().email(),
        'count': Ack.integer().min(0),
        'items': Ack.list(Ack.string()),
      });

      // ACK → JSON
      final jsonMap1 = ackSchema.toJsonSchema();

      // JSON → JsonSchema
      final jsonSchema = JsonSchema.fromJson(jsonMap1);

      // JsonSchema → JSON
      final jsonMap2 = jsonSchema.toJson();

      // Should be identical
      expect(jsonMap2, equals(jsonMap1));
    });
  });
}

enum TestRole { admin, user, guest }
