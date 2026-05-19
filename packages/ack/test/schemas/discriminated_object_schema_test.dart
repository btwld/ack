import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('DiscriminatedObjectSchema', () {
    late ObjectSchema catSchema;
    late ObjectSchema dogSchema;
    late DiscriminatedObjectSchema animalSchema;

    setUp(() {
      catSchema = Ack.object({'type': Ack.string(), 'meow': Ack.boolean()});

      dogSchema = Ack.object({'type': Ack.string(), 'bark': Ack.boolean()});

      animalSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {'cat': catSchema, 'dog': dogSchema},
      );
    });

    group('Basic validation', () {
      test('validates cat correctly', () {
        final result = animalSchema.safeParse({'type': 'cat', 'meow': true});
        expect(result.isOk, isTrue);
      });

      test('validates dog correctly', () {
        final result = animalSchema.safeParse({'type': 'dog', 'bark': false});
        expect(result.isOk, isTrue);
      });

      test('fails for unknown discriminator value', () {
        final result = animalSchema.safeParse({'type': 'bird', 'fly': true});
        expect(result.isOk, isFalse);
      });

      test('fails for missing discriminator', () {
        final result = animalSchema.safeParse({'meow': true});
        expect(result.isOk, isFalse);
      });

      test('fails when schemas map is empty', () {
        final emptySchema = Ack.discriminated<Map<String, Object?>>(
          discriminatorKey: 'type',
          schemas: const <String, AckSchema<Map<String, Object?>>>{},
        );

        final result = emptySchema.safeParse({'type': 'cat'});
        expect(result.isOk, isFalse);
      });
    });

    group('Union-owned discriminator policy', () {
      test(
        'branch_without_discriminator_parses_when_union_input_has_discriminator',
        () {
          final cat = Ack.object({'lives': Ack.integer()});
          final pet = Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {'cat': cat},
          );

          final result = pet.safeParse({'type': 'cat', 'lives': 9});

          expect(result.isOk, isTrue);
          expect(result.getOrThrow(), equals({'type': 'cat', 'lives': 9}));
        },
      );

      test(
        'branch_without_discriminator_rejects_missing_discriminator_on_union_input',
        () {
          final cat = Ack.object({'lives': Ack.integer()});
          final pet = Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {'cat': cat},
          );

          final result = pet.safeParse({'lives': 9});

          expect(result.isOk, isFalse);
        },
      );

      test('branch_with_matching_literal_discriminator_parses', () {
        final cat = Ack.object({
          'type': Ack.literal('cat'),
          'lives': Ack.integer(),
        });
        final pet = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {'cat': cat},
        );

        final result = pet.safeParse({'type': 'cat', 'lives': 9});

        expect(result.isOk, isTrue);
      });

      test(
        'branch_with_broad_string_discriminator_parses_and_exports_literal',
        () {
          final cat = Ack.object({
            'type': Ack.string(),
            'lives': Ack.integer(),
          });
          final pet = Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {'cat': cat},
          );

          final result = pet.safeParse({'type': 'cat', 'lives': 9});
          final jsonSchema = pet.toJsonSchema();
          final branch = ((jsonSchema['anyOf'] as List<Object?>).single as Map)
              .cast<String, Object?>();
          final properties = (branch['properties'] as Map)
              .cast<String, Object?>();

          expect(result.isOk, isTrue);
          expect(
            properties['type'],
            equals({'type': 'string', 'const': 'cat'}),
          );
        },
      );

      test('branch_with_conflicting_literal_discriminator_fails', () {
        final cat = Ack.object({
          'type': Ack.literal('dog'),
          'lives': Ack.integer(),
        });
        final pet = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {'cat': cat},
        );

        final result = pet.safeParse({'type': 'cat', 'lives': 9});

        expect(result.isOk, isFalse);
      });

      test(
        'toJsonSchema_injects_required_literal_discriminator_for_omitted_branch_property',
        () {
          final cat = Ack.object({'lives': Ack.integer()});
          final pet = Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {'cat': cat},
          );

          final jsonSchema = pet.toJsonSchema();
          final branch = ((jsonSchema['anyOf'] as List<Object?>).single as Map)
              .cast<String, Object?>();
          final properties = (branch['properties'] as Map)
              .cast<String, Object?>();

          expect(
            properties['type'],
            equals({'type': 'string', 'const': 'cat'}),
          );
          expect(branch['required'], equals(['type', 'lives']));
        },
      );

      test(
        'toJsonSchema_preserves_branch_properties_and_adds_discriminator_first',
        () {
          final cat = Ack.object({
            'lives': Ack.integer(),
            'name': Ack.string(),
          });
          final pet = Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {'cat': cat},
          );

          final jsonSchema = pet.toJsonSchema();
          final branch = ((jsonSchema['anyOf'] as List<Object?>).single as Map)
              .cast<String, Object?>();
          final properties = (branch['properties'] as Map)
              .cast<String, Object?>();

          expect(properties.keys.toList(), equals(['type', 'lives', 'name']));
          expect(branch['required'], equals(['type', 'lives', 'name']));
        },
      );

      test(
        'effective_branch_injection_does_not_mutate_original_branch_schema',
        () {
          final cat = Ack.object({'lives': Ack.integer()});
          final pet = Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {'cat': cat},
          );

          final result = pet.safeParse({'type': 'cat', 'lives': 9});

          expect(result.isOk, isTrue);
          expect(cat.properties, isNot(contains('type')));
        },
      );

      test('effectiveBranch validates a specific branch schema', () {
        final cat = Ack.object({'lives': Ack.integer()});
        final dog = Ack.object({'breed': Ack.string()});
        final pet = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {'cat': cat, 'dog': dog},
        );

        final catBranch = pet.effectiveBranch('cat');

        expect(catBranch.safeParse({'type': 'cat', 'lives': 9}).isOk, isTrue);
        expect(
          catBranch.safeParse({'type': 'dog', 'breed': 'Poodle'}).isFail,
          isTrue,
        );
      });

      test('effectiveBranch rejects unknown discriminator values', () {
        final cat = Ack.object({'lives': Ack.integer()});
        final pet = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {'cat': cat},
        );

        expect(() => pet.effectiveBranch('dog'), throwsArgumentError);
      });
    });

    group('Fluent methods', () {
      test('nullable() creates nullable schema', () {
        final nullableSchema = animalSchema.nullable();

        expect(nullableSchema.isNullable, isTrue);
        expect(animalSchema.isNullable, isFalse); // Original unchanged

        // Test null validation
        final nullResult = nullableSchema.safeParse(null);
        expect(nullResult.isOk, isTrue);
      });

      test('describe() adds description', () {
        const description = 'An animal discriminated by type';
        final describedSchema = animalSchema.describe(description);

        expect(describedSchema.description, equals(description));
        expect(animalSchema.description, isNull); // Original unchanged
      });

      test('fluent methods can be chained (excluding default)', () {
        const description = 'Nullable animal schema';

        final fullyConfiguredSchema = animalSchema.nullable().describe(
          description,
        );

        expect(fullyConfiguredSchema.isNullable, isTrue);
        expect(fullyConfiguredSchema.description, equals(description));

        // Original remains unchanged
        expect(animalSchema.isNullable, isFalse);
        expect(animalSchema.description, isNull);
      });

      test('nullable(false) creates non-nullable schema', () {
        final nullableSchema = animalSchema.nullable();
        final nonNullableAgain = nullableSchema.nullable(value: false);

        expect(nonNullableAgain.isNullable, isFalse);
        expect(nullableSchema.isNullable, isTrue); // Previous version unchanged
      });
    });

    group('copyWith method', () {
      test(
        'copyWith preserves original values when no parameters provided',
        () {
          final copy = animalSchema.copyWith();

          expect(copy.discriminatorKey, equals(animalSchema.discriminatorKey));
          expect(copy.schemas, equals(animalSchema.schemas));
          expect(copy.isNullable, equals(animalSchema.isNullable));
          expect(copy.description, equals(animalSchema.description));
          // No default expected on discriminated schema
        },
      );

      test('copyWith updates specific values', () {
        final birdSchema = Ack.object({
          'type': Ack.string(),
          'fly': Ack.boolean(),
        });

        final newSchemas = {
          'cat': catSchema,
          'dog': dogSchema,
          'bird': birdSchema,
        };

        final updated = animalSchema.copyWith(
          schemas: newSchemas,
          isNullable: true,
          description: 'Updated schema',
        );

        expect(updated.schemas, equals(newSchemas));
        expect(updated.isNullable, isTrue);
        expect(updated.description, equals('Updated schema'));
        expect(updated.discriminatorKey, equals(animalSchema.discriminatorKey));
      });
    });

    group('Equality', () {
      test('supports equality across different generic type arguments', () {
        final branch = Ack.object({
          'type': Ack.literal('cat'),
          'name': Ack.string(),
        });

        final mapTyped = Ack.discriminated<Map<String, Object?>>(
          discriminatorKey: 'type',
          schemas: {'cat': branch},
        );
        final objectTyped = Ack.discriminated<Object>(
          discriminatorKey: 'type',
          schemas: {'cat': branch},
        );

        expect(() => mapTyped == objectTyped, returnsNormally);
        expect(() => objectTyped == mapTyped, returnsNormally);
        expect(mapTyped == objectTyped, isTrue);
        expect(objectTyped == mapTyped, isTrue);
        expect(mapTyped.hashCode, equals(objectTyped.hashCode));
      });
    });

    group('JSON Schema', () {
      test('supports transformed child branches in toJsonSchema', () {
        final schema = Ack.discriminated<String>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({
              'name': Ack.string(),
            }).transform<String>((map) => map['name'] as String),
          },
        );

        final jsonSchema = schema.toJsonSchema();
        final branch = ((jsonSchema['anyOf'] as List<Object?>).single as Map)
            .cast<String, Object?>();
        final properties = (branch['properties'] as Map)
            .cast<String, Object?>();

        expect(branch['x-transformed'], isTrue);
        expect(properties['type'], equals({'type': 'string', 'const': 'cat'}));
        expect(branch['required'], equals(['type', 'name']));
      });

      test('rejects non-object-backed child branches in toJsonSchema', () {
        final schema = Ack.discriminated<String>(
          discriminatorKey: 'type',
          schemas: {'cat': Ack.string()},
        );

        expect(() => schema.toJsonSchema(), throwsArgumentError);
      });

      test('rejects non-object-backed child branches in toJsonSchemaModel', () {
        final schema = Ack.discriminated<String>(
          discriminatorKey: 'type',
          schemas: {'cat': Ack.string()},
        );

        expect(() => schema.toJsonSchemaModel(), throwsArgumentError);
      });

      test('omits non-JSON defaults for transformed discriminated schemas', () {
        final schema = Ack.discriminated<Object>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({
              'name': Ack.string(),
            }).transform<Object>((map) => map['name'] as Object),
          },
        ).copyWith(defaultValue: Object());

        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema.containsKey('default'), isFalse);
        expect(() => jsonEncode(jsonSchema), returnsNormally);
      });

      test(
        'omits non-JSON defaults for nullable transformed discriminated schemas',
        () {
          final schema = Ack.discriminated<Object>(
            discriminatorKey: 'type',
            schemas: {
              'cat': Ack.object({
                'name': Ack.string(),
              }).transform<Object>((map) => map['name'] as Object),
            },
          ).nullable().copyWith(defaultValue: Object());

          final jsonSchema = schema.toJsonSchema();

          expect(jsonSchema.containsKey('default'), isFalse);
          expect(() => jsonEncode(jsonSchema), returnsNormally);
        },
      );
    });
  });
}
