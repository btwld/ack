import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'described_model.g.dart';

@Schemable(description: 'User profile with comprehensive field descriptions')
class UserProfile {
  final String id;

  final String name;

  final String email;

  final int age;

  final String? avatarUrl;

  final String? bio; // No description - should render normally

  UserProfile({
    @Description('Unique identifier for the user') required this.id,
    @Description('User\'s full display name') @MinLength(2) required this.name,
    @Description('Primary email address for communication')
    @Email()
    required this.email,
    @Description('User age in years (must be 13 or older)')
    @Min(13)
    required this.age,
    @Description('Optional profile picture URL') @Url() this.avatarUrl,
    this.bio,
  });
}

void main() {
  print('🎯 Field Description Example\n');

  final testData = {
    'id': 'user_123',
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 25,
    'avatarUrl': 'https://example.com/avatar.jpg',
    'bio': 'Software developer',
  };

  try {
    final result = userProfileSchema.parse(testData) as Map<String, dynamic>;
    print('✅ User validation successful!');
    print('   ID: ${result['id']}');
    print('   Name: ${result['name']}');
    print('   Email: ${result['email']}');
    print('   Age: ${result['age']}');
    print('   Avatar: ${result['avatarUrl'] ?? 'None'}');
    print('   Bio: ${result['bio'] ?? 'Not provided'}');
  } catch (e) {
    print('❌ Validation error: $e');
  }
}
