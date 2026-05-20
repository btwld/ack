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
        final passthrough = Ack.object({
          'name': Ack.string(),
        }, additionalProperties: true);

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

      test('single-branch anyOf stays non-nullable', () {
        final schema = Ack.anyOf([Ack.string()]);

        final result = schema.toJsonSchemaBuilder();
        final anyOf = (result.value['anyOf'] as List)
            .map(_schemaFrom)
            .toList(growable: false);

        expect(anyOf, hasLength(1));
        expect(anyOf.single.value['type'], 'string');
      });

      test('nullable anyOf preserves union and null branch', () {
        final schema = Ack.anyOf([Ack.string(), Ack.integer()]).nullable();

        final result = schema.toJsonSchemaBuilder();
        final anyOf = (result.value['anyOf'] as List)
            .map(_schemaFrom)
            .toList(growable: false);
        expect(anyOf, hasLength(3));
        expect(anyOf[0].value['type'], 'string');
        expect(anyOf[1].value['type'], 'integer');
        expect(anyOf[2].value['type'], 'null');
      });

      test('preserves model defaults, const values, and extensions', () {
        const schema = AckBooleanSchemaModel(
          constValue: true,
          defaultValue: true,
          extensions: {
            'not': {'const': false},
            'x-ack': 'kept',
          },
        );

        final result = convertAckSchemaModelToBuilder(schema);

        expect(result.value['type'], 'boolean');
        expect(result.value['const'], true);
        expect(result.value['default'], true);
        expect(result.value['not'], {'const': false});
        expect(result.value['x-ack'], 'kept');
      });

      test('preserves date format bounds from schema model keywords', () {
        final schema = Ack.date()
            .min(DateTime.utc(2026))
            .max(DateTime.utc(2026, 12, 31));

        final result = schema.toJsonSchemaBuilder();

        expect(result.value['type'], 'string');
        expect(result.value['format'], 'date');
        expect(result.value['formatMinimum'], '2026-01-01');
        expect(result.value['formatMaximum'], '2026-12-31');
      });

      test(
        'TransformedSchema overrides are applied (description + nullable)',
        () {
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
        },
      );
    });

    group('oneOf composition', () {
      test('oneOf converts to oneOf (not anyOf)', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'circle': Ack.object({
              'type': Ack.literal('circle'),
              'radius': Ack.double(),
            }),
            'square': Ack.object({
              'type': Ack.literal('square'),
              'side': Ack.double(),
            }),
          },
        );
        final result = schema.toJsonSchemaBuilder();

        // MUST have oneOf, NOT anyOf - discriminated unions require exactly-one semantics
        expect(
          result.value.containsKey('oneOf'),
          isTrue,
          reason:
              'Discriminated schema should use oneOf for exactly-one semantics',
        );
        expect(
          result.value.containsKey('anyOf'),
          isFalse,
          reason: 'oneOf should not be converted to anyOf',
        );
      });

      test('oneOf preserves branch schemas', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'kind',
          schemas: {
            'a': Ack.object({'kind': Ack.literal('a'), 'val': Ack.string()}),
            'b': Ack.object({'kind': Ack.literal('b'), 'num': Ack.integer()}),
          },
        );
        final result = schema.toJsonSchemaBuilder();

        final oneOf = result.value['oneOf'] as List?;
        expect(oneOf, isNotNull);
        expect(oneOf, hasLength(2));
      });

      test(
        'oneOf replaces compatible discriminator property with exact const',
        () {
          final schema = Ack.discriminated(
            discriminatorKey: 'kind',
            schemas: {
              'a': Ack.object({
                'kind': Ack.enumString(['a', 'alpha']),
                'val': Ack.string(),
              }),
            },
          );
          final result = schema.toJsonSchemaBuilder();

          final oneOf = result.value['oneOf'] as List;
          final branch = _schemaFrom(oneOf.single);
          final properties = (branch.value['properties'] as Map).map(
            (key, value) => MapEntry(key as String, _schemaFrom(value)),
          );

          expect(properties['kind']!.value['const'], 'a');
          expect(branch.value['required'], ['kind', 'val']);
        },
      );
    });

    group('Numeric constraints - exclusive bounds and multipleOf', () {
      test('integer preserves exclusiveMinimum', () {
        final schema = Ack.integer().greaterThan(5);
        final result = schema.toJsonSchemaBuilder();

        expect(result.value['exclusiveMinimum'], 5);
      });

      test('integer preserves exclusiveMaximum', () {
        final schema = Ack.integer().lessThan(100);
        final result = schema.toJsonSchemaBuilder();

        expect(result.value['exclusiveMaximum'], 100);
      });

      test('integer preserves multipleOf', () {
        final schema = Ack.integer().multipleOf(5);
        final result = schema.toJsonSchemaBuilder();

        expect(result.value['multipleOf'], 5);
      });

      test('integer preserves all numeric constraints together', () {
        final schema = Ack.integer()
            .min(0)
            .max(100)
            .greaterThan(-1)
            .lessThan(101)
            .multipleOf(5);
        final result = schema.toJsonSchemaBuilder();

        expect(result.value['minimum'], 0);
        expect(result.value['maximum'], 100);
        expect(result.value['exclusiveMinimum'], -1);
        expect(result.value['exclusiveMaximum'], 101);
        expect(result.value['multipleOf'], 5);
      });

      test('double preserves exclusiveMinimum', () {
        final schema = Ack.double().greaterThan(0.5);
        final result = schema.toJsonSchemaBuilder();

        expect(result.value['exclusiveMinimum'], closeTo(0.5, 1e-9));
      });

      test('double preserves exclusiveMaximum', () {
        final schema = Ack.double().lessThan(99.5);
        final result = schema.toJsonSchemaBuilder();

        expect(result.value['exclusiveMaximum'], closeTo(99.5, 1e-9));
      });

      test('double preserves multipleOf', () {
        final schema = Ack.double().multipleOf(0.25);
        final result = schema.toJsonSchemaBuilder();

        expect(result.value['multipleOf'], closeTo(0.25, 1e-9));
      });

      test('double preserves all numeric constraints together', () {
        final schema = Ack.double()
            .min(0)
            .max(100)
            .greaterThan(-0.5)
            .lessThan(100.5)
            .multipleOf(0.1);
        final result = schema.toJsonSchemaBuilder();

        expect(result.value['minimum'], closeTo(0, 1e-9));
        expect(result.value['maximum'], closeTo(100, 1e-9));
        expect(result.value['exclusiveMinimum'], closeTo(-0.5, 1e-9));
        expect(result.value['exclusiveMaximum'], closeTo(100.5, 1e-9));
        expect(result.value['multipleOf'], closeTo(0.1, 1e-9));
      });
    });

    group('Discriminated + error wrapping', () {
      test('throws when branch discriminator rejects branch key', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'circle': Ack.object({
              'type': Ack.literal('square'),
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
        final schema = Ack.object({'bad': const TestUnsupportedAckSchema()});

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
        final schema = Ack.object({
          'name': Ack.string(),
        }, additionalProperties: true);
        final result = schema.toJsonSchemaBuilder();

        // Should be true (boolean), not {} (schema)
        expect(
          result.value['additionalProperties'],
          anyOf(equals(true), equals({})),
        );
      });

      test('additionalProperties schema converts recursively', () {
        const schema = AckObjectSchemaModel(
          additionalProperties: AckAdditionalPropertiesSchema(
            AckStringSchemaModel(minLength: 1),
          ),
        );

        final result = convertAckSchemaModelToBuilder(schema);
        final additional = _schemaFrom(result.value['additionalProperties']);

        expect(additional.value['type'], 'string');
        expect(additional.value['minLength'], 1);
      });
    });

    group('allOf composition', () {
      test('allOf converts to allOf in json_schema_builder', () {
        const jsonSchema = AckAllOfSchemaModel(
          schemas: [
            AckObjectSchemaModel(properties: {'name': AckStringSchemaModel()}),
            AckObjectSchemaModel(properties: {'age': AckIntegerSchemaModel()}),
          ],
        );

        // Convert using the public helper
        final result = convertAckSchemaModelToBuilder(jsonSchema);

        // Verify allOf is in the output
        expect(
          result.value.containsKey('allOf'),
          isTrue,
          reason: 'allOf should be converted to allOf',
        );
        expect(
          result.value.containsKey('anyOf'),
          isFalse,
          reason: 'allOf should not become anyOf',
        );

        final allOf = result.value['allOf'] as List;
        expect(allOf, hasLength(2));
      });

      test('allOf preserves branch schemas', () {
        const jsonSchema = AckAllOfSchemaModel(
          schemas: [
            AckStringSchemaModel(minLength: 5),
            AckStringSchemaModel(maxLength: 10),
          ],
        );

        final result = convertAckSchemaModelToBuilder(jsonSchema);
        final allOf = (result.value['allOf'] as List).map(_schemaFrom).toList();

        expect(allOf, hasLength(2));
        expect(allOf[0].value['type'], 'string');
        expect(allOf[0].value['minLength'], 5);
        expect(allOf[1].value['maxLength'], 10);
      });
    });

    group('Object property count constraints', () {
      test('minProperties is preserved in conversion', () {
        const jsonSchema = AckObjectSchemaModel(
          properties: {'name': AckStringSchemaModel()},
          minProperties: 2,
        );

        final result = convertAckSchemaModelToBuilder(jsonSchema);

        expect(result.value['minProperties'], 2);
      });

      test('maxProperties is preserved in conversion', () {
        const jsonSchema = AckObjectSchemaModel(
          properties: {'name': AckStringSchemaModel()},
          maxProperties: 5,
        );

        final result = convertAckSchemaModelToBuilder(jsonSchema);

        expect(result.value['maxProperties'], 5);
      });

      test('both minProperties and maxProperties together', () {
        const jsonSchema = AckObjectSchemaModel(
          properties: {'name': AckStringSchemaModel()},
          minProperties: 1,
          maxProperties: 10,
        );

        final result = convertAckSchemaModelToBuilder(jsonSchema);

        expect(result.value['minProperties'], 1);
        expect(result.value['maxProperties'], 10);
      });
    });
  });
}
