// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:ack/ack.dart';

/// Generated schema for Product
/// A product model with validation
ObjectSchema productSchema() {
  return Ack.object(
    {
      'id': Ack.string(),
      'name': Ack.string(),
      'description': Ack.string(),
      'price': Ack.double(),
      'contactEmail': Ack.string().nullable(),
      'imageUrl': Ack.string().nullable(),
      'category': categorySchema(),
      'releaseDate': Ack.string(),
      'createdAt': Ack.string(),
      'updatedAt': Ack.string().nullable(),
      'stockQuantity': Ack.integer(),
      'status': Ack.string(),
      'productCode': Ack.string(),
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
}

/// Generated schema for Category
/// A category for organizing products
ObjectSchema categorySchema() {
  return Ack.object(
    {
      'id': Ack.string(),
      'name': Ack.string(),
      'description': Ack.string().nullable(),
    },
    required: ['id', 'name'],
    additionalProperties: true,
  );
}
