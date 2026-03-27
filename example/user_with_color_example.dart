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
  };

  print('--- Valid data ---');
  final user = UserWithColorType.parse(validData);
  print('Name: ${user.firstName} ${user.lastName}');
  print('Age: ${user.age}');
  print('Bio: ${user.profile.bio}');
  print('Website: ${user.profile.website}');
  print('Color: ${user.color}');
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
