// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

/// Generated schema for Product
/// A product model with validation
final productSchema = Ack.object({
  'id': Ack.string().minLength(1),
  'name': Ack.string().minLength(3),
  'description': Ack.string(),
  'price': Ack.double().min(0.01),
  'contactEmail': Ack.string().email().optional().nullable(),
  'imageUrl': Ack.string().url().optional().nullable(),
  'category': categorySchema,
  'releaseDate': Ack.string(),
  'createdAt': Ack.string(),
  'updatedAt': Ack.string().optional().nullable(),
  'stockQuantity': Ack.integer().positive(),
  'status': Ack.string().enumString(['draft', 'published', 'archived']),
  'productCode': Ack.string().matches(r'''^[A-Z]{2,3}-\d{4}$'''),
}, additionalProperties: true);

/// Generated schema for Category
/// A category for organizing products
final categorySchema = Ack.object({
  'id': Ack.string(),
  'name': Ack.string(),
  'description': Ack.string().optional().nullable(),
}, additionalProperties: true);
