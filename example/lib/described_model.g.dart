// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

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
