// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mixed_examples.dart';

/// Generated schema for BasicUser
/// Basic user model - generates only schema variable
final basicUserSchema = Ack.object({
  'id': Ack.string(),
  'username': Ack.string(),
  'email': Ack.string().optional().nullable(),
});

/// Generated schema for EnhancedUser
/// Enhanced user with comprehensive validation
final enhancedUserSchema = Ack.object({
  'id': Ack.string(),
  'username': Ack.string(),
  'email': Ack.string(),
  'createdAt': Ack.string(),
});

/// Generated schema for Order
/// Order with status enum - schema only
final orderSchema = Ack.object({
  'id': Ack.string(),
  'status': Ack.string().enumString([
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ]),
  'total': Ack.double(),
});

/// Generated schema for BlogPost
/// Blog post with author - demonstrates nested models
final blogPostSchema = Ack.object({
  'id': Ack.string(),
  'title': Ack.string(),
  'content': Ack.string(),
  'author': enhancedUserSchema,
  'publishedAt': Ack.string(),
  'tags': Ack.list(Ack.string()),
}, additionalProperties: true);

/// Generated schema for ProductInventory
/// Product inventory with comprehensive constraints
final productInventorySchema = Ack.object({
  'sku': Ack.string().minLength(3).maxLength(50),
  'quantity': Ack.integer(),
  'unitPrice': Ack.double().min(0.01),
  'lastRestocked': Ack.string().matches(r'''^\d{4}-\d{2}-\d{2}$'''),
  'isAvailable': Ack.boolean(),
});
