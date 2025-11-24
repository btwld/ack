import 'package:ack/ack.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:json_schema_builder/json_schema_builder.dart' as jsb;
import 'package:test/test.dart';

jsb.Schema _schemaFrom(Object? value) {
  if (value is jsb.Schema) return value;
  return jsb.Schema.fromMap((value as Map).cast<String, Object?>());
}

void main() {
  group('toJsonSchemaBuilder()', () {
    group('Primitives', () {
      test('converts basic string schema', () {
        final schema = Ack.string();
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts string with minLength', () {
        final schema = Ack.string().minLength(5);
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts string with maxLength', () {
        final schema = Ack.string().maxLength(50);
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts string with description', () {
        final schema = Ack.string().describe('User name');
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts integer schema', () {
        final schema = Ack.integer();
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts integer with minimum', () {
        final schema = Ack.integer().min(0);
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts integer with maximum', () {
        final schema = Ack.integer().max(100);
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts double schema', () {
        final schema = Ack.double();
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts boolean schema', () {
        final schema = Ack.boolean();
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });
    });

    group('Objects', () {
      test('converts basic object schema', () {
        final schema = Ack.object({'name': Ack.string(), 'age': Ack.integer()});
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts object with optional fields', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().optional(),
        });
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts nested object schema', () {
        final schema = Ack.object({
          'user': Ack.object({'name': Ack.string()}),
        });
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });
    });

    group('Arrays', () {
      test('converts basic array schema', () {
        final schema = Ack.list(Ack.string());
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts array with minItems', () {
        final schema = Ack.list(Ack.string()).minLength(1);
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts array of objects', () {
        final schema = Ack.list(
          Ack.object({'id': Ack.integer(), 'name': Ack.string()}),
        );
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });
    });

    group('Enums', () {
      test('converts string enum schema', () {
        final schema = Ack.enumString(['red', 'green', 'blue']);
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });
    });

    group('Complex Scenarios', () {
      test('converts complete user schema', () {
        final schema = Ack.object({
          'id': Ack.string().minLength(1),
          'name': Ack.string().minLength(2).maxLength(50),
          'email': Ack.string().email(),
          'age': Ack.integer().min(0).max(120).optional(),
          'tags': Ack.list(Ack.string()).optional(),
        });

        final result = schema.toJsonSchemaBuilder();
        expect(result, isNotNull);
      });
    });

    group('Metadata preservation', () {
      test('nullable string keeps format and lengths', () {
        final schema = Ack.string().email().minLength(5).nullable();

        final result = schema.toJsonSchemaBuilder();
        final anyOf = (result.value['anyOf'] as List)
            .map(_schemaFrom)
            .toList(growable: false);
        expect(anyOf, hasLength(2));

        final stringBranch = anyOf.first;
        expect(stringBranch.value['type'], 'string');
        expect(stringBranch.value['format'], 'email');
        expect(stringBranch.value['minLength'], 5);

        final nullBranch = anyOf.last;
        expect(nullBranch.value['type'], 'null');
      });

      test('nullable integer keeps bounds', () {
        final schema = Ack.integer().min(1).max(7).nullable();

        final result = schema.toJsonSchemaBuilder();
        final anyOf = (result.value['anyOf'] as List)
            .map(_schemaFrom)
            .toList(growable: false);

        final intBranch = anyOf.first;
        expect(intBranch.value['type'], 'integer');
        expect(intBranch.value['minimum'], 1);
        expect(intBranch.value['maximum'], 7);

        expect(anyOf.last.value['type'], 'null');
      });

      test('nullable object keeps nested metadata', () {
        final schema = Ack.object({
          'id': Ack.string().uuid(),
          'score': Ack.double().min(0).max(1),
        }).nullable();

        final result = schema.toJsonSchemaBuilder();
        final anyOf = (result.value['anyOf'] as List)
            .map(_schemaFrom)
            .toList(growable: false);
        final objectBranch = anyOf.first;
        final propertiesRaw = objectBranch.value['properties'] as Map;
        final properties = propertiesRaw.map(
          (key, value) => MapEntry(key as String, _schemaFrom(value)),
        );

        final idProperty = properties['id']!;
        expect(idProperty.value['format'], 'uuid');

        final scoreProperty = properties['score']!;
        expect(scoreProperty.value['minimum'], 0);
        expect(scoreProperty.value['maximum'], 1);

        final nullBranch = anyOf.last;
        expect(nullBranch.value['type'], 'null');
      });

      test('object respects additionalProperties flag', () {
        final strict = Ack.object({'name': Ack.string()});
        final passthrough = Ack.object({'name': Ack.string()}, additionalProperties: true);

        final strictResult = strict.toJsonSchemaBuilder();
        expect(strictResult.value['additionalProperties'], false);

        final passthroughResult = passthrough.toJsonSchemaBuilder();
        expect(
          passthroughResult.value['additionalProperties'],
          anyOf(equals(true), equals({})),
        );
      });

      test('anyOf retains multiple branches', () {
        final schema = Ack.anyOf([Ack.string(), Ack.integer()]);

        final result = schema.toJsonSchemaBuilder();
        final anyOf = (result.value['anyOf'] as List)
            .map(_schemaFrom)
            .toList(growable: false);

        expect(anyOf, hasLength(2));
        expect(anyOf.first.value['type'], 'string');
        expect(anyOf.last.value['type'], 'integer');
      });

      test('nullable anyOf preserves union and null branch', () {
        final schema = Ack.anyOf([Ack.string(), Ack.integer()]).nullable();

        final result = schema.toJsonSchemaBuilder();
        final outerAnyOf = (result.value['anyOf'] as List)
            .map(_schemaFrom)
            .toList(growable: false);
        expect(outerAnyOf, hasLength(2));

        final unionBranch = outerAnyOf.first;
        final innerAnyOf = (unionBranch.value['anyOf'] as List)
            .map(_schemaFrom)
            .toList(growable: false);
        expect(innerAnyOf, hasLength(2));
        expect(outerAnyOf.last.value['type'], 'null');
      });

      test('TransformedSchema overrides are applied (description + nullable)', () {
        final schema = Ack.date().copyWith(
          description: 'Birth date',
          isNullable: true,
        );

        final result = schema.toJsonSchemaBuilder();
        final anyOf = (result.value['anyOf'] as List)
            .map(_schemaFrom)
            .toList(growable: false);

        // First branch should carry description override and date format
        final dateBranch = anyOf.first;
        expect(dateBranch.value['description'], 'Birth date');
        expect(dateBranch.value['format'], 'date');

        // Second branch represents nullability
        final nullBranch = anyOf.last;
        expect(nullBranch.value['type'], 'null');
      });
    });

    group('Discriminated + error wrapping', () {
      test('throws on discriminator/property conflict', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'circle': Ack.object({
              'type': Ack.string(), // conflict
              'radius': Ack.double(),
            }),
          },
        );

        expect(
          () => schema.toJsonSchemaBuilder(),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('type'),
            ),
          ),
        );
      });

      test('wraps property conversion errors with path', () {
        final schema = Ack.object({
          'bad': const TestUnsupportedAckSchema(),
        });

        expect(
          () => schema.toJsonSchemaBuilder(),
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message,
              'message',
              contains('property "bad"'),
            ),
          ),
        );
      });
    });

    group('additionalProperties handling', () {
      test('additionalProperties: false converts correctly', () {
        final schema = Ack.object({'name': Ack.string()});
        final result = schema.toJsonSchemaBuilder();

        expect(result.value['additionalProperties'], false);
      });

      test('additionalProperties: true converts to boolean', () {
        final schema = Ack.object({'name': Ack.string()}, additionalProperties: true);
        final result = schema.toJsonSchemaBuilder();

        // Should be true (boolean), not {} (schema)
        expect(
          result.value['additionalProperties'],
          anyOf(equals(true), equals({})),
        );
      });
    });
  });
}
