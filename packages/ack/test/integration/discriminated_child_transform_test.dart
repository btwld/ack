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
    test('throws helpful error when child schema has non-Map transform', () {
      // This is the INCORRECT pattern - transforming child schemas
      final catSchema = Ack.object({
        'type': Ack.literal('cat'),
        'name': Ack.string(),
      }).transform<Cat>((map) => Cat(map!['name'] as String));

      final dogSchema = Ack.object({
        'type': Ack.literal('dog'),
        'name': Ack.string(),
      }).transform<Dog>((map) => Dog(map!['name'] as String));

      final animalSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'cat': catSchema,
          'dog': dogSchema,
        },
      );

      // Should throw StateError with helpful message
      expect(
        () => animalSchema.parse({'type': 'cat', 'name': 'Whiskers'}),
        throwsA(
          allOf(
            isA<StateError>(),
            predicate<StateError>(
              (e) =>
                  e.message.contains('returned Cat instead of Map') &&
                  e.message.contains('Ack.discriminated()') &&
                  e.message.contains('.transform()'),
            ),
          ),
        ),
      );
    });

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

      final animalSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'cat': catSchema,
          'dog': dogSchema,
        },
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

      final animalSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'cat': catSchema,
          'dog': dogSchema,
        },
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
        schemas: {
          'cat': catSchema,
        },
      ).transform<Animal>((map) => Cat(map!['name'] as String));

      // Unknown discriminator value should fail validation
      final result = animalSchema.safeParse({'type': 'unknown', 'name': 'Test'});
      expect(result.isOk, isFalse);
    });
  });
}
