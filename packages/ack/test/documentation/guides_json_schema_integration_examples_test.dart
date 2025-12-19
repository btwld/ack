import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Tests for code snippets in docs/guides/json-schema-integration.mdx.
void main() {
  group('Docs /guides/json-schema-integration.mdx', () {
    AckSchema<Map<String, Object?>> buildUserSchema() {
      return Ack.object({
        'id': Ack.integer().positive().describe(
          'Unique user identifier',
        ),
        'name': Ack.string()
            .minLength(2)
            .maxLength(50)
            .describe("User's full name"),
        'email': Ack.string().email().describe("User's email address"),
        'role': Ack.enumString(['admin', 'user', 'guest']).withDefault('user'),
        'isActive': Ack.boolean().withDefault(true),
        'tags': Ack.list(
          Ack.string(),
        ).unique().describe('List of user tags').nullable(),
        'age': Ack.integer()
            .min(0)
            .max(120)
            .nullable()
            .describe("User's age"),
      }).describe('Represents a user in the system');
    }

    test('toJsonSchema produces expected metadata', () {
      final schema = buildUserSchema();
      final jsonSchema = schema.toJsonSchema();

      expect(jsonSchema['type'], equals('object'));
      expect(
        jsonSchema['description'],
        equals('Represents a user in the system'),
      );
      final properties = jsonSchema['properties'] as Map<String, Object?>;
      expect(properties['id'], isA<Map<String, Object?>>());
      final required = jsonSchema['required'] as List<Object?>;
      expect(required, containsAll(['id', 'name', 'email']));
    });

    test('API specification example includes referenced schema', () {
      Map<String, Object?> buildApiSpecification() {
        final userJsonSchema = buildUserSchema().toJsonSchema();

        return {
          'schemas': {'User': userJsonSchema},
          'endpoints': {
            '/users': {
              'post': {
                'summary': 'Create a new user',
                'requestBody': {
                  'required': true,
                  'content': {
                    'application/json': {
                      'schema': {'\$ref': '#/schemas/User'},
                    },
                  },
                },
              },
            },
          },
        };
      }

      final spec = buildApiSpecification();
      final encoded = JsonEncoder.withIndent('  ').convert(spec);
      expect(encoded, contains('"#/schemas/User"'));
    });
  });
}
