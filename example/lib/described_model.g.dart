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
  UserProfileSchemaModel._internal(ObjectSchema this.schema);

  factory UserProfileSchemaModel() {
    return UserProfileSchemaModel._internal(userProfileSchema);
  }

  UserProfileSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

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

  /// Returns a new schema with the specified description.
  UserProfileSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return UserProfileSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  UserProfileSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return UserProfileSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  UserProfileSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return UserProfileSchemaModel._withSchema(newSchema);
  }
}
