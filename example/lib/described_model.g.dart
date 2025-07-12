// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'described_model.dart';

/// Generated schema for UserProfile
/// User profile with comprehensive field descriptions
final userProfileSchema = Ack.object({
  // Unique identifier for the user
  'id': Ack.string().optional(),
  // User's full display name
  'name': Ack.string().minLength(2).optional(),
  // Primary email address for communication
  'email': Ack.string().email().optional(),
  // User age in years (must be 13 or older)
  'age': Ack.integer().optional(),
  // Optional profile picture URL
  'avatarUrl': Ack.string().url().optional().nullable(),
  'bio': Ack.string().optional().nullable(),
});

/// Generated SchemaModel for [UserProfile].
/// User profile with comprehensive field descriptions
class UserProfileSchemaModel extends SchemaModel<UserProfile> {
  UserProfileSchemaModel._();

  factory UserProfileSchemaModel() {
    return _instance;
  }

  static final _instance = UserProfileSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return userProfileSchema;
  }

  @override
  UserProfile createFromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      age: map['age'] as int,
      avatarUrl: map['avatarUrl'] as String?,
      bio: map['bio'] as String?,
    );
  }
}
