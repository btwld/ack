// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_extension_types.dart';

/// Generated schema for SimpleUser
final simpleUserSchema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
  'email': Ack.string().optional().nullable(),
});

/// Generated schema for Address
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
final blogPostSchema = Ack.object({
  'title': Ack.string(),
  'content': Ack.string(),
  'tags': Ack.list(Ack.string()),
  'locations': Ack.list(addressSchema),
});
