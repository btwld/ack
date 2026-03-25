import 'package:ack/ack.dart';
import 'package:test/test.dart';

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
    test('supports transformed child branches', () {
      final catSchema =
          Ack.object({
            'type': Ack.literal('cat'),
            'name': Ack.string(),
            'meows': Ack.boolean().optional(),
          }).transform<Animal>(
            (map) => Cat(
              map['name'] as String,
              meows: (map['meows'] as bool?) ?? true,
            ),
          );

      final dogSchema =
          Ack.object({
            'type': Ack.literal('dog'),
            'name': Ack.string(),
            'barks': Ack.boolean().optional(),
          }).transform<Animal>(
            (map) => Dog(
              map['name'] as String,
              barks: (map['barks'] as bool?) ?? true,
            ),
          );

      final animalSchema = Ack.discriminated<Animal>(
        discriminatorKey: 'type',
        schemas: {'cat': catSchema, 'dog': dogSchema},
      );

      final cat = animalSchema.parse({'type': 'cat', 'name': 'Whiskers'});
      expect(cat, isA<Cat>());
      expect(cat!.name, equals('Whiskers'));
      expect((cat as Cat).meows, isTrue);

      final dog = animalSchema.parse({'type': 'dog', 'name': 'Buddy'});
      expect(dog, isA<Dog>());
      expect(dog!.name, equals('Buddy'));
      expect((dog as Dog).barks, isTrue);
    });

    test('supports safeParse with transformed child branches', () {
      final catSchema = Ack.object({
        'type': Ack.literal('cat'),
        'name': Ack.string(),
      }).transform<Animal>((map) => Cat(map['name'] as String));

      final dogSchema = Ack.object({
        'type': Ack.literal('dog'),
        'name': Ack.string(),
      }).transform<Animal>((map) => Dog(map['name'] as String));

      final animalSchema = Ack.discriminated<Animal>(
        discriminatorKey: 'type',
        schemas: {'cat': catSchema, 'dog': dogSchema},
      );

      final result = animalSchema.safeParse({'type': 'cat', 'name': 'Mittens'});
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), isA<Cat>());
      expect((result.getOrNull() as Cat).name, equals('Mittens'));
    });

    test('applies transformed defaults without re-parsing', () {
      final catSchema = Ack.object({
        'type': Ack.literal('cat'),
        'name': Ack.string(),
      }).transform<Animal>((map) => Cat(map['name'] as String));

      final animalSchema = Ack.discriminated<Animal>(
        discriminatorKey: 'type',
        schemas: {'cat': catSchema},
      ).copyWith(defaultValue: Cat('Default Cat'));

      final result = animalSchema.safeParse(null);

      expect(result.isOk, isTrue);
      expect(result.getOrNull(), isA<Cat>());
      expect(result.getOrThrow()!.name, equals('Default Cat'));
    });

    test('fails when a branch is not object-backed', () {
      final animalSchema = Ack.discriminated<String>(
        discriminatorKey: 'type',
        schemas: {'cat': Ack.string()},
      );

      final result = animalSchema.safeParse({'type': 'cat'});

      expect(result.isOk, isFalse);
      expect(
        result.getError().message,
        equals('Discriminated branches must be object-backed schemas'),
      );
    });

    test('transform on discriminated union itself still works', () {
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
            return switch (map['type']) {
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

      final cat = animalSchema.parse({'type': 'cat', 'name': 'Whiskers'});
      expect(cat, isA<Cat>());
      expect(cat!.name, equals('Whiskers'));
      expect((cat as Cat).meows, isTrue);

      final dog = animalSchema.parse({'type': 'dog', 'name': 'Buddy'});
      expect(dog, isA<Dog>());
      expect(dog!.name, equals('Buddy'));
      expect((dog as Dog).barks, isTrue);
    });

    test('invalid discriminator fails before branch transform runs', () {
      var transformCalled = false;
      final catSchema =
          Ack.object({
            'type': Ack.literal('cat'),
            'name': Ack.string(),
          }).transform<Animal>((map) {
            transformCalled = true;
            return Cat(map['name'] as String);
          });

      final schema = Ack.discriminated<Animal>(
        discriminatorKey: 'type',
        schemas: {'cat': catSchema},
      );

      final result = schema.safeParse({'type': 'unknown', 'name': 'Test'});

      expect(result.isOk, isFalse);
      expect(transformCalled, isFalse);
    });

    test('invalid branch payload fails before transform output', () {
      var transformCalled = false;
      final catSchema =
          Ack.object({
            'type': Ack.literal('cat'),
            'name': Ack.string(),
          }).transform<Animal>((map) {
            transformCalled = true;
            return Cat(map['name'] as String);
          });

      final schema = Ack.discriminated<Animal>(
        discriminatorKey: 'type',
        schemas: {'cat': catSchema},
      );

      // Missing required 'name' field
      final result = schema.safeParse({'type': 'cat'});

      expect(result.isOk, isFalse);
      expect(transformCalled, isFalse);
    });

    test('branch transform exceptions wrapped as SchemaTransformError', () {
      final catSchema =
          Ack.object({
            'type': Ack.literal('cat'),
            'name': Ack.string(),
          }).transform<Animal>((map) {
            throw FormatException('bad data');
          });

      final schema = Ack.discriminated<Animal>(
        discriminatorKey: 'type',
        schemas: {'cat': catSchema},
      );

      final result = schema.safeParse({'type': 'cat', 'name': 'Whiskers'});

      expect(result.isOk, isFalse);
      expect(result.getError(), isA<SchemaTransformError>());
    });

    test('multi-layer transforms dispatch correctly', () {
      final catSchema =
          Ack.object({'type': Ack.literal('cat'), 'name': Ack.string()})
              .transform<Map<String, Object?>>(
                (map) => {...map, 'transformed': true},
              )
              .transform<Animal>((map) => Cat(map['name'] as String));

      final schema = Ack.discriminated<Animal>(
        discriminatorKey: 'type',
        schemas: {'cat': catSchema},
      );

      final result = schema.parse({'type': 'cat', 'name': 'Whiskers'});

      expect(result, isA<Cat>());
      expect(result!.name, equals('Whiskers'));
    });

    test('validation errors occur before union-level transform', () {
      final catSchema = Ack.object({
        'type': Ack.literal('cat'),
        'name': Ack.string(),
      });

      final animalSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {'cat': catSchema},
      ).transform<Animal>((map) => Cat(map['name'] as String));

      final result = animalSchema.safeParse({
        'type': 'unknown',
        'name': 'Test',
      });
      expect(result.isOk, isFalse);
    });
  });
}
