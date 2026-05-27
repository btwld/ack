import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('DiscriminatedObjectSchema', () {
    late ObjectSchema catSchema;
    late ObjectSchema dogSchema;
    late DiscriminatedObjectSchema animalSchema;

    setUp(() {
      catSchema = Ack.object({
        'type': Ack.literal('cat'),
        'meow': Ack.boolean(),
      });

      dogSchema = Ack.object({
        'type': Ack.literal('dog'),
        'bark': Ack.boolean(),
      });

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

      test('encode rejects missing branch discriminator', () {
        final result = animalSchema.safeEncode({'meow': true});

        expect(result.isFail, isTrue);
      });

      test('encode accepts a matching branch-owned discriminator', () {
        final result = animalSchema.safeEncode({'type': 'cat', 'meow': true});

        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), {'type': 'cat', 'meow': true});
      });
    });

    group('Union-owned discriminator (PR #107)', () {
      // Branches without the discriminator property are valid; the union
      // synthesizes the literal via `effectiveBranch` for parse and encode.
      late DiscriminatedObjectSchema unionOwnedSchema;

      setUp(() {
        unionOwnedSchema = Ack.discriminated<Map<String, Object?>>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({'meow': Ack.boolean()}),
            'dog': Ack.object({'bark': Ack.boolean()}),
          },
        );
      });

      test('parses a branch whose schema omits the discriminator', () {
        final result = unionOwnedSchema.safeParse({
          'type': 'cat',
          'meow': true,
        });

        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), {'type': 'cat', 'meow': true});
      });

      test('encodes a branch whose schema omits the discriminator', () {
        final result = unionOwnedSchema.safeEncode({
          'type': 'dog',
          'bark': false,
        });

        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), {'type': 'dog', 'bark': false});
      });

      test('parse against the wrong branch fails on the literal', () {
        final result = unionOwnedSchema.safeParse({
          'type': 'cat',
          'bark': true,
        });

        expect(result.isFail, isTrue);
      });
    });

    group('Constructor validation', () {
      test('rejects an empty discriminator key', () {
        expect(
          () => Ack.discriminated<Map<String, Object?>>(
            discriminatorKey: '',
            schemas: {'cat': catSchema},
          ),
          throwsArgumentError,
        );
      });

      test('rejects an empty schemas map', () {
        expect(
          () => Ack.discriminated<Map<String, Object?>>(
            discriminatorKey: 'type',
            schemas: const <String, AckSchema<JsonMap, Map<String, Object?>>>{},
          ),
          throwsArgumentError,
        );
      });

      test('rejects an empty branch key', () {
        expect(
          () => Ack.discriminated<Map<String, Object?>>(
            discriminatorKey: 'type',
            schemas: {'': catSchema},
          ),
          throwsArgumentError,
        );
      });

      test('rejects a branch whose discriminator literal does not match', () {
        expect(
          () => Ack.discriminated<Map<String, Object?>>(
            discriminatorKey: 'type',
            schemas: {
              'cat': Ack.object({
                'type': Ack.literal('dog'),
                'meow': Ack.boolean(),
              }),
            },
          ),
          throwsArgumentError,
        );
      });

      test('defensively copies schemas', () {
        final schemas = {'cat': catSchema};
        final schema = Ack.discriminated<Map<String, Object?>>(
          discriminatorKey: 'type',
          schemas: schemas,
        );

        schemas['dog'] = dogSchema;

        expect(schema.schemas, hasLength(1));
        expect(schema.schemas, containsPair('cat', catSchema));
        expect(() => schema.schemas['dog'] = dogSchema, throwsUnsupportedError);
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
          'type': Ack.literal('bird'),
          'fly': Ack.boolean(),
        });

        final newSchemas = {
          'cat': catSchema,
          'dog': dogSchema,
          'bird': birdSchema,
        };

        final updated = DiscriminatedObjectSchema<Map<String, Object?>>(
          discriminatorKey: animalSchema.discriminatorKey,
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
              'type': Ack.literal('cat'),
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
    });
  });
}
