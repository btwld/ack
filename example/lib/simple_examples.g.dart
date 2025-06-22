// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:ack/ack.dart';
import 'package:meta/meta.dart';

/// Generated schema for User
/// User with flexible preferences
class UserSchema extends SchemaModel {
  UserSchema();

  UserSchema._valid(Map<String, Object?> data) : super.validated(data);

  @override
  late final definition = Ack.object(
    {'id': Ack.string, 'name': Ack.string, 'email': Ack.string},
    required: ['id', 'name', 'email'],
    additionalProperties: true,
  );

  @override
  UserSchema parse(Object? input) {
    return super.parse(input) as UserSchema;
  }

  @override
  UserSchema? tryParse(Object? input) {
    return super.tryParse(input) as UserSchema?;
  }

  @override
  @protected
  UserSchema createValidated(Map<String, Object?> data) {
    return UserSchema._valid(data);
  }

  String get id => getValue<String>('id');

  String get name => getValue<String>('name');

  String get email => getValue<String>('email');

  Map<String, Object?> get preferences {
    final map = toMap();
    final knownFields = {'id', 'name', 'email'};
    return Map.fromEntries(
      map.entries.where((e) => !knownFields.contains(e.key)),
    );
  }
}

/// Generated schema for Product
/// Product with flexible metadata
class ProductSchema extends SchemaModel {
  ProductSchema();

  ProductSchema._valid(Map<String, Object?> data) : super.validated(data);

  @override
  late final definition = Ack.object(
    {'id': Ack.string, 'name': Ack.string, 'price': Ack.double},
    required: ['id', 'name', 'price'],
    additionalProperties: true,
  );

  @override
  ProductSchema parse(Object? input) {
    return super.parse(input) as ProductSchema;
  }

  @override
  ProductSchema? tryParse(Object? input) {
    return super.tryParse(input) as ProductSchema?;
  }

  @override
  @protected
  ProductSchema createValidated(Map<String, Object?> data) {
    return ProductSchema._valid(data);
  }

  String get id => getValue<String>('id');

  String get name => getValue<String>('name');

  double get price => getValue<double>('price');

  Map<String, Object?> get metadata {
    final map = toMap();
    final knownFields = {'id', 'name', 'price'};
    return Map.fromEntries(
      map.entries.where((e) => !knownFields.contains(e.key)),
    );
  }
}

/// Generated schema for SimpleItem
/// Simple model without additional properties
class SimpleItemSchema extends SchemaModel {
  SimpleItemSchema();

  SimpleItemSchema._valid(Map<String, Object?> data) : super.validated(data);

  @override
  late final definition = Ack.object(
    {'id': Ack.string, 'name': Ack.string, 'active': Ack.boolean},
    required: ['id', 'name', 'active'],
  );

  @override
  SimpleItemSchema parse(Object? input) {
    return super.parse(input) as SimpleItemSchema;
  }

  @override
  SimpleItemSchema? tryParse(Object? input) {
    return super.tryParse(input) as SimpleItemSchema?;
  }

  @override
  @protected
  SimpleItemSchema createValidated(Map<String, Object?> data) {
    return SimpleItemSchema._valid(data);
  }

  String get id => getValue<String>('id');

  String get name => getValue<String>('name');

  bool get active => getValue<bool>('active');
}
