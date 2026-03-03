import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

enum UserRole { admin, user, guest }

/// Tests for code snippets in docs/guides/json-schema-integration.mdx.
void main() {
  group('Docs /guides/json-schema-integration.mdx', () {
    AckSchema<Map<String, Object?>> buildUserSchema() {
      return Ack.object({
        'id': Ack.integer().positive().describe('Unique user identifier'),
        'name': Ack.string()
            .minLength(2)
            .maxLength(50)
            .describe("User's full name"),
        'email': Ack.string().email().describe("User's email address"),
        'role': Ack.enumValues(UserRole.values).withDefault(UserRole.user),
        'isActive': Ack.boolean().withDefault(true),
        'tags': Ack.list(
          Ack.string(),
        ).unique().describe('List of user tags').nullable(),
        'age': Ack.integer().min(0).max(120).nullable().describe("User's age"),
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

    test('nullable enum is emitted as anyOf(enum, null)', () {
      final schema = Ack.enumValues(UserRole.values).nullable();
      final jsonSchema = schema.toJsonSchema();

      final anyOf = jsonSchema['anyOf'] as List<Object?>;
      expect(anyOf, hasLength(2));
      expect(
        anyOf.any((e) => e is Map<String, Object?> && e['type'] == 'null'),
        isTrue,
      );

      final enumBranch =
          anyOf.firstWhere(
                (e) => e is Map<String, Object?> && e['type'] == 'string',
              )
              as Map<String, Object?>;
      expect(enumBranch['enum'], equals(['admin', 'user', 'guest']));
    });

    test('nullable discriminated schema is emitted as nested anyOf', () {
      final schema = Ack.discriminated(
        discriminatorKey: 'kind',
        schemas: {
          'circle': Ack.object({
            'kind': Ack.literal('circle'),
            'radius': Ack.double().positive(),
          }),
          'square': Ack.object({
            'kind': Ack.literal('square'),
            'size': Ack.double().positive(),
          }),
        },
      ).nullable();

      final jsonSchema = schema.toJsonSchema();
      final outerAnyOf = jsonSchema['anyOf'] as List<Object?>;
      expect(outerAnyOf, hasLength(2));
      expect(
        outerAnyOf.any((e) => e is Map<String, Object?> && e['type'] == 'null'),
        isTrue,
      );

      final unionBranch =
          outerAnyOf.firstWhere(
                (e) => e is Map<String, Object?> && e['anyOf'] is List,
              )
              as Map<String, Object?>;
      final innerAnyOf = unionBranch['anyOf'] as List<Object?>;
      expect(innerAnyOf, hasLength(2));
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
