import 'package:ack_example/pet.dart' as explicit;
import 'package:ack_example/schema_types_discriminated.dart' as omitted;
import 'package:test/test.dart';

void main() {
  group('discriminated generated types with omitted branch discriminators', () {
    test('base parser returns the matching subtype', () {
      final cat = omitted.PetType.parse({'kind': 'cat', 'lives': 9});
      final dog = omitted.PetType.parse({'kind': 'dog', 'bark': true});

      expect(cat, isA<omitted.CatType>());
      expect(dog, isA<omitted.DogType>());
    });

    test('subtype parser rejects another valid union branch', () {
      final result = omitted.CatType.safeParse({'kind': 'dog', 'bark': true});

      expect(result.isFail, isTrue);
      expect(
        () => omitted.CatType.parse({'kind': 'dog', 'bark': true}),
        throwsA(anything),
      );
    });
  });

  group('discriminated generated types with explicit branch literals', () {
    test('base parser returns the matching subtype', () {
      final cat = explicit.PetType.parse({'type': 'cat', 'lives': 9});
      final dog = explicit.PetType.parse({'type': 'dog', 'breed': 'Poodle'});

      expect(cat, isA<explicit.CatType>());
      expect(dog, isA<explicit.DogType>());
    });

    test('subtype parser rejects another valid union branch', () {
      final result = explicit.CatType.safeParse({
        'type': 'dog',
        'breed': 'Poodle',
      });

      expect(result.isFail, isTrue);
      expect(
        () => explicit.CatType.parse({'type': 'dog', 'breed': 'Poodle'}),
        throwsA(anything),
      );
    });
  });
}
