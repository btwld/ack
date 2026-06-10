import 'package:ack/ack.dart';
import 'package:ack/src/constraints/pattern_constraint.dart';
import 'package:ack/src/constraints/validators.dart';
import 'package:test/test.dart';

final class _Cat {
  const _Cat(this.name);

  final String name;
}

final class _Dog {
  const _Dog(this.name);

  final String name;
}

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

      test('parse and encode missing-discriminator errors stay aligned', () {
        final input = {'meow': true};

        final parseResult = animalSchema.safeParse(input);
        final encodeResult = animalSchema.safeEncode(input);

        expect(parseResult.isFail, isTrue);
        expect(encodeResult.isFail, isTrue);

        final parseError = parseResult.getError();
        final encodeError = encodeResult.getError();
        expect(encodeError.runtimeType, parseError.runtimeType);

        final parseConstraint =
            (parseError as SchemaConstraintsError).constraints.first;
        final encodeConstraint =
            (encodeError as SchemaConstraintsError).constraints.first;
        expect(
          encodeConstraint.constraint.runtimeType,
          parseConstraint.constraint.runtimeType,
        );
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

      test('JSON Schema marks the synthesized discriminator required and '
          'does not export a discriminator default', () {
        final jsonSchema = unionOwnedSchema.toJsonSchema();
        final branches = (jsonSchema['anyOf'] as List).cast<Map>();

        for (final branch in branches) {
          final required = (branch['required'] as List).cast<String>();
          expect(required, contains('type'));

          final properties = (branch['properties'] as Map)
              .cast<String, Object?>();
          final typeProp = (properties['type'] as Map).cast<String, Object?>();
          expect(typeProp.containsKey('default'), isFalse);
        }
      });

      test('parse against the wrong branch fails on the literal', () {
        final result = unionOwnedSchema.safeParse({
          'type': 'cat',
          'bark': true,
        });

        expect(result.isFail, isTrue);
      });

      test(
        'encodes a map-runtime branch codec that emits the discriminator',
        () {
          final codecSchema = Ack.discriminated<Map<String, Object?>>(
            discriminatorKey: 'type',
            schemas: {
              'cat': Ack.object({'name': Ack.string()})
                  .codec<Map<String, Object?>>(
                    decode: (data) => {'name': data['name']!},
                    encode: (cat) => {'type': 'cat', 'name': cat['name']},
                  ),
            },
          );

          final result = codecSchema.safeEncode({
            'type': 'cat',
            'name': 'Mittens',
          });

          expect(result.isOk, isTrue);
          expect(result.getOrThrow(), {'type': 'cat', 'name': 'Mittens'});
        },
      );

      test(
        'encodes a map-runtime branch codec that omits the discriminator',
        () {
          final codecSchema = Ack.discriminated<Map<String, Object?>>(
            discriminatorKey: 'type',
            schemas: {
              'cat': Ack.object({'name': Ack.string()})
                  .codec<Map<String, Object?>>(
                    decode: (data) => {'name': data['name']!},
                    encode: (cat) => {'name': cat['name']},
                  ),
            },
          );

          final result = codecSchema.safeEncode({
            'type': 'cat',
            'name': 'Mittens',
          });

          expect(result.isOk, isTrue);
          expect(result.getOrThrow(), {'type': 'cat', 'name': 'Mittens'});
        },
      );

      test('round-trips through a map-runtime branch codec that omits the '
          'discriminator', () {
        final codecSchema = Ack.discriminated<Map<String, Object?>>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({'name': Ack.string()})
                .codec<Map<String, Object?>>(
                  decode: (data) => {'name': data['name']!},
                  encode: (cat) => {'name': cat['name']},
                ),
          },
        );

        final parsed = codecSchema.parse({'type': 'cat', 'name': 'Mittens'});
        final encoded = codecSchema.safeEncode(parsed);

        expect(parsed, {'type': 'cat', 'name': 'Mittens'});
        expect(() => parsed!['type'] = 'dog', throwsUnsupportedError);
        expect(encoded.isOk, isTrue);
        expect(encoded.getOrThrow(), {'type': 'cat', 'name': 'Mittens'});
      });

      test('normalizes narrower map-backed codec outputs during parse', () {
        final codecSchema = Ack.discriminated<Map<String, String>>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({'name': Ack.string()})
                .codec<Map<String, String>>(
                  decode: (data) => {'name': data['name']! as String},
                  encode: (cat) => {'name': cat['name']!},
                ),
          },
        );

        final parsed = codecSchema.parse({'type': 'cat', 'name': 'Mittens'});
        final encoded = codecSchema.safeEncode(parsed);

        expect(parsed, {'type': 'cat', 'name': 'Mittens'});
        expect(() => parsed!['type'] = 'dog', throwsUnsupportedError);
        expect(encoded.isOk, isTrue);
        expect(encoded.getOrThrow(), {'type': 'cat', 'name': 'Mittens'});
      });

      test(
        'rejects a decoded map runtime with a conflicting discriminator',
        () {
          final codecSchema = Ack.discriminated<Map<String, Object?>>(
            discriminatorKey: 'type',
            schemas: {
              'cat': Ack.object({'name': Ack.string()})
                  .codec<Map<String, Object?>>(
                    decode: (data) => {'type': 'dog', 'name': data['name']!},
                    encode: (cat) => {'name': cat['name']},
                  ),
            },
          );

          final result = codecSchema.safeParse({
            'type': 'cat',
            'name': 'Mittens',
          });

          expect(result.isFail, isTrue);
          final error = result.getError();
          expect(error, isA<SchemaValidationError>());
          expect(
            (error as SchemaValidationError).message,
            contains('conflicting "type" value: dog'),
          );
        },
      );

      test('rejects a map-runtime branch codec missing the discriminator', () {
        final codecSchema = Ack.discriminated<Map<String, Object?>>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({'name': Ack.string()})
                .codec<Map<String, Object?>>(
                  decode: (data) => {'name': data['name']!},
                  encode: (cat) => {'name': cat['name']},
                ),
          },
        );

        final result = codecSchema.safeEncode({'name': 'Mittens'});

        expect(result.isFail, isTrue);
        final error = result.getError() as SchemaConstraintsError;
        expect(
          error.constraints.first.constraint,
          isA<ObjectRequiredPropertiesConstraint>(),
        );
      });

      test('rejects a map-shaped object runtime missing the discriminator', () {
        final codecSchema = Ack.discriminated<Object>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({'name': Ack.string()}).codec<Object>(
              decode: (data) => <Object?, Object?>{'name': data['name']},
              encode: (value) {
                final map = value as Map<Object?, Object?>;
                return {'name': map['name']};
              },
            ),
          },
        );

        final result = codecSchema.safeEncode(<Object?, Object?>{
          'name': 'Mittens',
        });

        expect(result.isFail, isTrue);
        final error = result.getError() as SchemaConstraintsError;
        expect(
          error.constraints.first.constraint,
          isA<ObjectRequiredPropertiesConstraint>(),
        );
      });

      test('encodes passthrough extras once for a branch codec that omits the '
          'discriminator', () {
        final codecSchema = Ack.discriminated<Map<String, Object?>>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({'name': Ack.string()})
                .passthrough()
                .codec<Map<String, Object?>>(
                  decode: (data) => Map<String, Object?>.from(data),
                  encode: (cat) => Map<String, Object?>.from(cat),
                ),
          },
        );

        final result = codecSchema.safeEncode({
          'type': 'cat',
          'name': 'Mittens',
          'color': 'tabby',
        });

        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), {
          'type': 'cat',
          'name': 'Mittens',
          'color': 'tabby',
        });
      });

      test('encodes the matching typed codec branch when codecs omit the '
          'discriminator', () {
        final codecSchema = Ack.discriminated<Object>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({'name': Ack.string()}).codec<_Cat>(
              decode: (data) => _Cat(data['name']! as String),
              encode: (cat) => {'name': cat.name},
            ),
            'dog': Ack.object({'name': Ack.string()}).codec<_Dog>(
              decode: (data) => _Dog(data['name']! as String),
              encode: (dog) => {'name': dog.name},
            ),
          },
        );

        final result = codecSchema.safeEncode(const _Dog('Spot'));

        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), {'type': 'dog', 'name': 'Spot'});
      });

      test(
        'rejects a typed runtime that matches multiple branches as ambiguous',
        () {
          // Two typed codec branches share the same runtime type, so branch
          // probing must still reject the runtime instead of silently encoding
          // through whichever branch is declared first.
          final ambiguousSchema = Ack.discriminated<Object>(
            discriminatorKey: 'type',
            schemas: {
              'cat': Ack.object({'name': Ack.string()}).codec<_Cat>(
                decode: (data) => _Cat(data['name']! as String),
                encode: (cat) => {'name': cat.name},
              ),
              'dog': Ack.object({'name': Ack.string()}).codec<_Cat>(
                decode: (data) => _Cat(data['name']! as String),
                encode: (cat) => {'name': cat.name},
              ),
            },
          );

          final result = ambiguousSchema.safeEncode(const _Cat('Mittens'));

          expect(result.isFail, isTrue);
          final error = result.getError();
          expect(error, isA<SchemaEncodeError>());
          expect((error as SchemaEncodeError).message, contains('"cat"'));
          expect(error.message, contains('"dog"'));
        },
      );

      test(
        'nested default and codec wrappers synthesize the discriminator only '
        'under codecs',
        () {
          final defaultCodecSchema = Ack.discriminated<Map<String, Object?>>(
            discriminatorKey: 'type',
            schemas: {
              'cat': Ack.object({'name': Ack.string()})
                  .codec<Map<String, Object?>>(
                    decode: (data) => {'name': data['name']!},
                    encode: (cat) => {'name': cat['name']},
                  )
                  .withDefault(const {'name': 'Default'}),
            },
          );
          final codecDefaultSchema = Ack.discriminated<Map<String, Object?>>(
            discriminatorKey: 'type',
            schemas: {
              'cat': Ack.object({'name': Ack.string()})
                  .withDefault(const {'name': 'Default'})
                  .codec<Map<String, Object?>>(
                    decode: (data) => {'name': data['name']!},
                    encode: (cat) => {'name': cat['name']},
                  ),
            },
          );
          final defaultOnlySchema = Ack.discriminated<Map<String, Object?>>(
            discriminatorKey: 'type',
            schemas: {
              'cat': Ack.object({
                'name': Ack.string(),
              }).withDefault(const {'name': 'Default'}),
            },
          );

          final defaultCodecResult = defaultCodecSchema.safeEncode({
            'type': 'cat',
            'name': 'Mittens',
          });
          final codecDefaultResult = codecDefaultSchema.safeEncode({
            'type': 'cat',
            'name': 'Mittens',
          });
          final defaultOnlyResult = defaultOnlySchema.safeEncode({
            'name': 'Mittens',
          });

          expect(defaultCodecResult.isOk, isTrue);
          expect(defaultCodecResult.getOrThrow(), {
            'type': 'cat',
            'name': 'Mittens',
          });
          expect(codecDefaultResult.isOk, isTrue);
          expect(codecDefaultResult.getOrThrow(), {
            'type': 'cat',
            'name': 'Mittens',
          });
          expect(defaultOnlyResult.isFail, isTrue);
          final error = defaultOnlyResult.getError() as SchemaConstraintsError;
          expect(
            error.constraints.first.constraint,
            isA<ObjectRequiredPropertiesConstraint>(),
          );
        },
      );

      test(
        'plain branch still rejects encode input missing the discriminator',
        () {
          final plainSchema = Ack.discriminated<Map<String, Object?>>(
            discriminatorKey: 'type',
            schemas: {
              'cat': Ack.object({'name': Ack.string()}),
            },
          );

          final result = plainSchema.safeEncode({'name': 'Mittens'});

          expect(result.isFail, isTrue);
          final error = result.getError() as SchemaConstraintsError;
          expect(
            error.constraints.first.constraint,
            isA<ObjectRequiredPropertiesConstraint>(),
          );
        },
      );

      group('Encode error messages (union-owned)', () {
        test(
          'fails with a required-property constraint when type is missing',
          () {
            final result = unionOwnedSchema.safeEncode({'bark': false});

            expect(result.isFail, isTrue);
            final error = result.getError() as SchemaConstraintsError;
            final constraint = error.constraints.first;

            expect(
              constraint.constraint,
              isA<ObjectRequiredPropertiesConstraint>(),
            );
            expect(constraint.message, contains('"type"'));
          },
        );

        test(
          'fails with an invalid-type constraint when type is not a string',
          () {
            final result = unionOwnedSchema.safeEncode({
              'type': 123,
              'bark': false,
            });

            expect(result.isFail, isTrue);
            final error = result.getError() as SchemaConstraintsError;
            final constraint = error.constraints.first;

            expect(constraint.constraint, isA<InvalidTypeConstraint>());
            expect(
              (constraint.constraint as InvalidTypeConstraint).expectedType,
              String,
            );
          },
        );

        test(
          'fails with an enum constraint when type names an unknown branch',
          () {
            final result = unionOwnedSchema.safeEncode({
              'type': 'bird',
              'fly': true,
            });

            expect(result.isFail, isTrue);
            final error = result.getError() as SchemaConstraintsError;
            final constraint = error.constraints.first;

            expect(constraint.constraint, isA<PatternConstraint>());
            final pattern = constraint.constraint as PatternConstraint;
            expect(pattern.type, PatternType.enumString);
            expect(pattern.allowedValues, ['cat', 'dog']);
          },
        );
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

      test('rejects lazy branches', () {
        late final ObjectSchema categorySchema;
        categorySchema = Ack.object({
          'name': Ack.string(),
          'children': Ack.list(
            Ack.lazy<JsonMap, JsonMap>('Category', () => categorySchema),
          ),
        });

        expect(
          () => Ack.discriminated<JsonMap>(
            discriminatorKey: 'type',
            schemas: {
              'category': Ack.lazy<JsonMap, JsonMap>(
                'Category',
                () => categorySchema,
              ),
            },
          ),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              contains('Discriminated branches cannot be Ack.lazy(...)'),
            ),
          ),
        );
      });

      test('rejects wrapped lazy branches with the lazy-specific error', () {
        late final ObjectSchema categorySchema;
        categorySchema = Ack.object({
          'name': Ack.string(),
          'children': Ack.list(
            Ack.lazy<JsonMap, JsonMap>('Category', () => categorySchema),
          ),
        });

        expect(
          () => Ack.discriminated<JsonMap>(
            discriminatorKey: 'type',
            schemas: {
              'category': Ack.lazy<JsonMap, JsonMap>(
                'Category',
                () => categorySchema,
              ).withDefault(const {'name': 'root', 'children': <Object?>[]}),
            },
          ),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              contains('Discriminated branches cannot be Ack.lazy(...)'),
            ),
          ),
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
