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

      test('withDescription() adds description', () {
        const description = 'An animal discriminated by type';
        final describedSchema = animalSchema.withDescription(description);

        expect(describedSchema.description, equals(description));
        expect(animalSchema.description, isNull); // Original unchanged
      });

      test('fluent methods can be chained (excluding default)', () {
        const description = 'Nullable animal schema';

        final fullyConfiguredSchema = animalSchema.nullable().withDescription(
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
  });
}
