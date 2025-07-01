// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:ack/ack.dart';

/// Generated schema for User
/// User with flexible preferences
ObjectSchema userSchema() {
  return Ack.object(
    {'id': Ack.string(), 'name': Ack.string(), 'email': Ack.string()},
    required: ['id', 'name', 'email'],
    additionalProperties: true,
  );
}

/// Generated schema for Product
/// Product with flexible metadata
ObjectSchema productSchema() {
  return Ack.object(
    {'id': Ack.string(), 'name': Ack.string(), 'price': Ack.double()},
    required: ['id', 'name', 'price'],
    additionalProperties: true,
  );
}

/// Generated schema for SimpleItem
/// Simple model without additional properties
ObjectSchema simpleItemSchema() {
  return Ack.object(
    {'id': Ack.string(), 'name': Ack.string(), 'active': Ack.boolean()},
    required: ['id', 'name', 'active'],
  );
}
