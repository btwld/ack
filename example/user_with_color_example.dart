import 'lib/user_with_color.dart';

void main() {
  // Valid user data
  final validData = {
    'firstName': 'Leo',
    'lastName': 'Farias',
    'age': 30,
    'profile': {
      'bio': 'Software engineer',
      'website': 'https://example.com',
    },
    'color': '#FF5733',
    'pet': {'type': 'cat', 'lives': 7},
    'pets': [
      {'type': 'cat', 'lives': 9},
      {'type': 'dog', 'breed': 'Labrador'},
    ],
  };

  print('--- Valid data ---');
  final user = UserWithColorType.parse(validData);
  print('Name: ${user.firstName} ${user.lastName}');
  print('Age: ${user.age}');
  print('Bio: ${user.profile.bio}');
  print('Website: ${user.profile.website}');
  print('Color: ${user.color}');
  print('Favorite color: ${user.favoriteColor}'); // null - optional, not provided
  print('');

  // Valid with favoriteColor provided
  print('--- With favorite color ---');
  final withFav = {...validData, 'favoriteColor': '#00FF00'};
  final userFav = UserWithColorType.parse(withFav);
  print('Favorite color: ${userFav.favoriteColor}');
  print('');

  // Nested discriminated pet
  print('--- Nested discriminated pet ---');
  final userPet = user;
  print('Pet type: ${userPet.pet.type}');
  print('Pets count: ${userPet.pets.length}');
  for (final p in userPet.pets) {
    print('  - ${p.type}');
  }
  // Can access discriminated subtype fields via cast
  final cat = userPet.pet as CatType;
  print('Cat lives: ${cat.lives}');
  print('');

  // Invalid hex color
  print('--- Invalid hex color ---');
  final badColor = {...validData, 'color': 'not-a-color'};
  final colorResult = UserWithColorType.safeParse(badColor);
  colorResult.match(
    onOk: (val) => print('OK: $val'),
    onFail: (error) => print('Error: $error'),
  );
  print('');

  // Age out of range
  print('--- Age out of range ---');
  final badAge = {...validData, 'age': -5};
  final ageResult = UserWithColorType.safeParse(badAge);
  ageResult.match(
    onOk: (val) => print('OK: $val'),
    onFail: (error) => print('Error: $error'),
  );
  print('');

  // Missing profile bio
  print('--- Missing profile bio ---');
  final badProfile = {
    ...validData,
    'profile': {'website': 'https://example.com'},
  };
  final profileResult = UserWithColorType.safeParse(badProfile);
  profileResult.match(
    onOk: (val) => print('OK: $val'),
    onFail: (error) => print('Error: $error'),
  );
}
