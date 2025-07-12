import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'described_model.g.dart';

@AckModel(
  description: 'User profile with comprehensive field descriptions',
  model: true,
)
class UserProfile {
  @AckField(description: 'Unique identifier for the user')
  final String id;
  
  @AckField(description: 'User\'s full display name')
  @MinLength(2)
  final String name;
  
  @AckField(description: 'Primary email address for communication')
  @Email()
  final String email;
  
  @AckField(description: 'User age in years (must be 13 or older)')
  @Min(13)
  final int age;
  
  @AckField(description: 'Optional profile picture URL')
  @Url()
  final String? avatarUrl;
  
  final String? bio; // No description - should render normally
  
  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.age,
    this.avatarUrl,
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
    final userModel = UserProfileSchemaModel();
    final result = userModel.parse(testData);
    
    if (result.isOk) {
      final user = userModel.value!;
      print('✅ User validation successful!');
      print('   ID: ${user.id}');
      print('   Name: ${user.name}');
      print('   Email: ${user.email}');
      print('   Age: ${user.age}');
      print('   Avatar: ${user.avatarUrl ?? 'None'}');
      print('   Bio: ${user.bio ?? 'Not provided'}');
    } else {
      print('❌ Validation failed: ${result.getError()}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}