import 'package:test/test.dart';

import '../lib/user_with_color.dart';

Map<String, Object?> _validData() => {
  'firstName': 'Leo',
  'lastName': 'Farias',
  'age': 30,
  'profile': {'bio': 'Software engineer', 'website': 'https://example.com'},
  'color': '#FF5733',
  'pet': {'type': 'cat', 'lives': 7},
  'pets': [
    {'type': 'cat', 'lives': 9},
    {'type': 'dog', 'breed': 'Labrador'},
  ],
};

void main() {
  group('ColorSchema', () {
    test('parses valid hex color', () {
      final result = colorSchema.safeParse('#FF5733');
      expect(result.isOk, isTrue);
      expect(result.getOrThrow().toString(), '#FF5733');
    });

    test('rejects invalid hex color via refine', () {
      final result = colorSchema.safeParse('not-a-color');
      expect(result.isFail, isTrue);
    });

    test('rejects hex without hash', () {
      final result = colorSchema.safeParse('FF5733');
      expect(result.isFail, isTrue);
    });

    test('rejects short hex', () {
      final result = colorSchema.safeParse('#FFF');
      expect(result.isFail, isTrue);
    });

    test('ColorType parse works', () {
      final color = ColorType.parse('#00FF00');
      expect(color.toString(), '#00FF00');
    });
  });

  group('ProfileSchema', () {
    test('parses valid profile', () {
      final result = profileSchema.safeParse({
        'bio': 'Hello world',
        'website': 'https://example.com',
      });
      expect(result.isOk, isTrue);
    });

    test('parses profile without optional website', () {
      final result = profileSchema.safeParse({'bio': 'Hello world'});
      expect(result.isOk, isTrue);
      final profile = ProfileType.parse({'bio': 'Hello world'});
      expect(profile.bio, 'Hello world');
      expect(profile.website, isNull);
    });

    test('rejects empty bio', () {
      final result = profileSchema.safeParse({'bio': ''});
      expect(result.isFail, isTrue);
    });

    test('rejects missing bio', () {
      final result = profileSchema.safeParse({
        'website': 'https://example.com',
      });
      expect(result.isFail, isTrue);
    });
  });

  group('PetSchema - discriminated', () {
    test('parses cat', () {
      final result = petSchema.safeParse({'type': 'cat', 'lives': 7});
      expect(result.isOk, isTrue);
    });

    test('parses dog', () {
      final result = petSchema.safeParse({'type': 'dog', 'breed': 'Labrador'});
      expect(result.isOk, isTrue);
    });

    test('rejects unknown pet type', () {
      final result = petSchema.safeParse({'type': 'fish', 'scales': true});
      expect(result.isFail, isTrue);
    });

    test('rejects cat with invalid lives', () {
      final result = petSchema.safeParse({'type': 'cat', 'lives': 0});
      expect(result.isFail, isTrue);
    });

    test('rejects dog with empty breed', () {
      final result = petSchema.safeParse({'type': 'dog', 'breed': ''});
      expect(result.isFail, isTrue);
    });

    test('PetType.parse dispatches to CatType', () {
      final pet = PetType.parse({'type': 'cat', 'lives': 9});
      expect(pet.type, 'cat');
      final cat = pet as CatType;
      expect(cat.lives, 9);
    });

    test('PetType.parse dispatches to DogType', () {
      final pet = PetType.parse({'type': 'dog', 'breed': 'Poodle'});
      expect(pet.type, 'dog');
      final dog = pet as DogType;
      expect(dog.breed, 'Poodle');
    });
  });

  group('UserWithColorSchema', () {
    test('parses valid data with all fields', () {
      final user = UserWithColorType.parse(_validData());
      expect(user.firstName, 'Leo');
      expect(user.lastName, 'Farias');
      expect(user.age, 30);
      expect(user.profile.bio, 'Software engineer');
      expect(user.profile.website, Uri.parse('https://example.com'));
      expect(user.color.toString(), '#FF5733');
      expect(user.pet.type, 'cat');
      expect(user.pets.length, 2);
    });

    test('firstName validation - rejects empty', () {
      final data = _validData()..['firstName'] = '';
      final result = UserWithColorType.safeParse(data);
      expect(result.isFail, isTrue);
    });

    test('lastName validation - rejects too long', () {
      final data = _validData()..['lastName'] = 'A' * 51;
      final result = UserWithColorType.safeParse(data);
      expect(result.isFail, isTrue);
    });

    test('age validation - rejects negative', () {
      final data = _validData()..['age'] = -1;
      final result = UserWithColorType.safeParse(data);
      expect(result.isFail, isTrue);
    });

    test('age validation - rejects over 150', () {
      final data = _validData()..['age'] = 151;
      final result = UserWithColorType.safeParse(data);
      expect(result.isFail, isTrue);
    });

    test('color validation - rejects invalid hex', () {
      final data = _validData()..['color'] = 'red';
      final result = UserWithColorType.safeParse(data);
      expect(result.isFail, isTrue);
    });
  });

  group('Optional transformed schema (favoriteColor)', () {
    test('omitted favoriteColor returns null', () {
      final user = UserWithColorType.parse(_validData());
      expect(user.favoriteColor, isNull);
    });

    test('provided favoriteColor parses correctly', () {
      final data = _validData()..['favoriteColor'] = '#00FF00';
      final user = UserWithColorType.parse(data);
      expect(user.favoriteColor, isNotNull);
      expect(user.favoriteColor.toString(), '#00FF00');
    });

    test('invalid favoriteColor fails validation', () {
      final data = _validData()..['favoriteColor'] = 'bad';
      final result = UserWithColorType.safeParse(data);
      expect(result.isFail, isTrue);
    });
  });

  group('Nested discriminated type (pet)', () {
    test('accesses nested cat fields via cast', () {
      final user = UserWithColorType.parse(_validData());
      expect(user.pet.type, 'cat');
      final cat = user.pet as CatType;
      expect(cat.lives, 7);
    });

    test('nested dog in pet field', () {
      final data = _validData()..['pet'] = {'type': 'dog', 'breed': 'Husky'};
      final user = UserWithColorType.parse(data);
      expect(user.pet.type, 'dog');
      final dog = user.pet as DogType;
      expect(dog.breed, 'Husky');
    });

    test('rejects invalid nested pet', () {
      final data = _validData()..['pet'] = {'type': 'fish'};
      final result = UserWithColorType.safeParse(data);
      expect(result.isFail, isTrue);
    });
  });

  group('List of discriminated types (pets)', () {
    test('parses list with mixed pet types', () {
      final user = UserWithColorType.parse(_validData());
      expect(user.pets.length, 2);
      expect(user.pets[0].type, 'cat');
      expect(user.pets[1].type, 'dog');
    });

    test('can cast list elements to subtypes', () {
      final user = UserWithColorType.parse(_validData());
      final cat = user.pets[0] as CatType;
      expect(cat.lives, 9);
      final dog = user.pets[1] as DogType;
      expect(dog.breed, 'Labrador');
    });

    test('empty pets list is valid', () {
      final data = _validData()..['pets'] = [];
      final user = UserWithColorType.parse(data);
      expect(user.pets, isEmpty);
    });

    test('rejects list with invalid pet', () {
      final data = _validData()
        ..['pets'] = [
          {'type': 'cat', 'lives': 0}, // lives min is 1
        ];
      final result = UserWithColorType.safeParse(data);
      expect(result.isFail, isTrue);
    });
  });
}
