// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

part of 'described_model.dart';

/// Generated schema for UserProfile
/// User profile with comprehensive field descriptions
final userProfileSchema = Ack.object({
  'id': Ack.string().optional().withDescription(
    'Unique identifier for the user',
  ),
  'name': Ack.string()
      .minLength(2)
      .optional()
      .withDescription('User\'s full display name'),
  'email': Ack.string().email().optional().withDescription(
    'Primary email address for communication',
  ),
  'age': Ack.integer().optional().withDescription(
    'User age in years (must be 13 or older)',
  ),
  'avatarUrl': Ack.string().url().optional().nullable().withDescription(
    'Optional profile picture URL',
  ),
  'bio': Ack.string().optional().nullable(),
});
