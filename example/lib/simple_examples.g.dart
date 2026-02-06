// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'simple_examples.dart';

/// Generated schema for User
/// User with flexible preferences
final userSchema = Ack.object({
  'id': Ack.string(),
  'name': Ack.string(),
  'email': Ack.string(),
}, additionalProperties: true);

/// Generated schema for Product
/// Product with flexible metadata
final productSchema = Ack.object({
  'id': Ack.string(),
  'name': Ack.string(),
  'price': Ack.double(),
}, additionalProperties: true);

/// Generated schema for SimpleItem
/// Simple model without additional properties
final simpleItemSchema = Ack.object({
  'id': Ack.string(),
  'name': Ack.string(),
  'active': Ack.boolean(),
});
