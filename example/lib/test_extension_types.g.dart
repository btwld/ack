// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'test_extension_types.dart';

/// Generated schema for SimpleUser
/// Simple model to test basic extension type generation
final simpleUserSchema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
  'email': Ack.string().optional().nullable(),
});

/// Generated schema for Address
/// Model with nested types to test dependency ordering
final addressSchema = Ack.object({
  'street': Ack.string(),
  'city': Ack.string(),
  'country': Ack.string(),
});

/// Generated schema for UserWithAddress
final userWithAddressSchema = Ack.object({
  'name': Ack.string(),
  'address': addressSchema,
  'billingAddress': addressSchema.optional().nullable(),
});

/// Generated schema for BlogPost
/// Model with collections to test list handling
final blogPostSchema = Ack.object({
  'title': Ack.string(),
  'content': Ack.string(),
  'tags': Ack.list(Ack.string()),
  'locations': Ack.list(addressSchema),
});
