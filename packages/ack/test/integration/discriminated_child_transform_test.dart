import 'package:ack/ack.dart';
import 'package:test/test.dart';

// Simple classes for demonstration
class Animal {
  final String name;
  Animal(this.name);
}

class Cat extends Animal {
  final bool meows;
  Cat(super.name, {this.meows = true});
}

class Dog extends Animal {
  final bool barks;
  Dog(super.name, {this.barks = true});
}

void main() {
  group('Discriminated schema with transforms', () {
    test(
      'compile-time type constraint ensures only Map-returning schemas are accepted',
      () {
        // The type constraint Map<String, AckSchema<MapValue>> on Ack.discriminated()
        // prevents passing transformed schemas at compile time.
        //
        // The following code would NOT compile:
        //
        // final catSchema = Ack.object({...}).transform<Cat>(...);
        // Ack.discriminated(
        //   discriminatorKey: 'type',
        //   schemas: {'cat': catSchema},  // Compile error: type mismatch
        // );
        //
        // This is the intended behavior - users get a compile-time error
        // rather than a runtime error when trying to use transformed schemas
        // as children of discriminated unions.

        // Verify that ObjectSchema IS accepted (it's AckSchema<MapValue>)
        final catSchema = Ack.object({
          'type': Ack.literal('cat'),
          'name': Ack.string(),
        });

        // This compiles because catSchema is ObjectSchema which is AckSchema<MapValue>
        final animalSchema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {'cat': catSchema},
        );

        // And it works correctly
        final result = animalSchema.safeParse({
          'type': 'cat',
          'name': 'Whiskers',
        });
        expect(result.isOk, isTrue);
      },
    );

    test('correct pattern: transform on discriminated union itself', () {
      // This is the CORRECT pattern - transform the discriminated union
      final catSchema = Ack.object({
        'type': Ack.literal('cat'),
        'name': Ack.string(),
        'meows': Ack.boolean().optional(),
      });

      final dogSchema = Ack.object({
        'type': Ack.literal('dog'),
        'name': Ack.string(),
        'barks': Ack.boolean().optional(),
      });

      final animalSchema =
          Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {'cat': catSchema, 'dog': dogSchema},
          ).transform<Animal>((map) {
            return switch (map!['type']) {
              'cat' => Cat(
                map['name'] as String,
                meows: (map['meows'] as bool?) ?? true,
              ),
              'dog' => Dog(
                map['name'] as String,
                barks: (map['barks'] as bool?) ?? true,
              ),
              _ => throw StateError('Unknown type'),
            };
          });

      // This works correctly
      final cat = animalSchema.parse({'type': 'cat', 'name': 'Whiskers'});
      expect(cat, isA<Cat>());
      expect(cat!.name, equals('Whiskers'));
      expect((cat as Cat).meows, isTrue);

      final dog = animalSchema.parse({'type': 'dog', 'name': 'Buddy'});
      expect(dog, isA<Dog>());
      expect(dog!.name, equals('Buddy'));
      expect((dog as Dog).barks, isTrue);
    });

    test('correct pattern works with safeParse', () {
      final catSchema = Ack.object({
        'type': Ack.literal('cat'),
        'name': Ack.string(),
      });

      final dogSchema = Ack.object({
        'type': Ack.literal('dog'),
        'name': Ack.string(),
      });

      final animalSchema =
          Ack.discriminated(
            discriminatorKey: 'type',
            schemas: {'cat': catSchema, 'dog': dogSchema},
          ).transform<Animal>((map) {
            return switch (map!['type']) {
              'cat' => Cat(map['name'] as String),
              'dog' => Dog(map['name'] as String),
              _ => throw StateError('Unknown type'),
            };
          });

      final result = animalSchema.safeParse({'type': 'cat', 'name': 'Mittens'});
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), isA<Cat>());
      expect((result.getOrNull() as Cat).name, equals('Mittens'));
    });

    test('validation errors occur before transform', () {
      final catSchema = Ack.object({
        'type': Ack.literal('cat'),
        'name': Ack.string(),
      });

      final animalSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {'cat': catSchema},
      ).transform<Animal>((map) => Cat(map!['name'] as String));

      // Unknown discriminator value should fail validation
      final result = animalSchema.safeParse({
        'type': 'unknown',
        'name': 'Test',
      });
      expect(result.isOk, isFalse);
    });
  });
}
