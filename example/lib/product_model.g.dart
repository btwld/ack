// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:ack/ack.dart';

/// Generated schema for Product
/// A product model with validation
final productSchema = Ack.object(
  {
    'id': Ack.string().minLength(1),
    'name': Ack.string().minLength(3),
    'description': Ack.string(),
    'price': Ack.double().min(0.01),
    'contactEmail': Ack.string().email().nullable(),
    'imageUrl': Ack.string().url().nullable(),
    'category': categorySchema,
    'releaseDate': Ack.string().matches(r'^\d{4}-\d{2}-\d{2}$'),
    'createdAt': Ack.string().matches(
      r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$',
    ),
    'updatedAt': Ack.string()
        .matches(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$')
        .nullable(),
    'stockQuantity': Ack.integer().positive(),
    'status': Ack.string().enumString(['draft', 'published', 'archived']),
    'productCode': Ack.string().matches(r'^[A-Z]{2,3}-\d{4}$'),
  },
  required: [
    'id',
    'name',
    'description',
    'price',
    'category',
    'releaseDate',
    'createdAt',
    'stockQuantity',
    'status',
    'productCode',
  ],
  additionalProperties: true,
);

/// Generated schema for Category
/// A category for organizing products
final categorySchema = Ack.object(
  {
    'id': Ack.string(),
    'name': Ack.string(),
    'description': Ack.string().nullable(),
  },
  required: ['id', 'name'],
  additionalProperties: true,
);
