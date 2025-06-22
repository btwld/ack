// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

// // GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:ack/ack.dart';
import 'package:meta/meta.dart';

/// Generated schema for Product
/// A product model with validation
class ProductSchema extends SchemaModel {
  ProductSchema();

  ProductSchema._valid(Map<String, Object?> data) : super.validated(data);

  @override
  late final definition = Ack.object(
    {
      'id': Ack.string,
      'name': Ack.string,
      'description': Ack.string,
      'price': Ack.double,
      'contactEmail': Ack.string.nullable(),
      'imageUrl': Ack.string.nullable(),
      'category': CategorySchema().definition,
      'releaseDate': Ack.string,
      'createdAt': Ack.string,
      'updatedAt': Ack.string.nullable(),
      'stockQuantity': Ack.int,
      'status': Ack.string,
      'productCode': Ack.string,
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

  String get description => getValue<String>('description');

  double get price => getValue<double>('price');

  String? get contactEmail => getValueOrNull<String>('contactEmail');

  String? get imageUrl => getValueOrNull<String>('imageUrl');

  CategorySchema get category {
    final data = getValue<Map<String, Object?>>('category');
    return CategorySchema().parse(data);
  }

  String get releaseDate => getValue<String>('releaseDate');

  String get createdAt => getValue<String>('createdAt');

  String? get updatedAt => getValueOrNull<String>('updatedAt');

  int get stockQuantity => getValue<int>('stockQuantity');

  String get status => getValue<String>('status');

  String get productCode => getValue<String>('productCode');

  Map<String, Object?> get metadata {
    final map = toMap();
    final knownFields = {
      'id',
      'name',
      'description',
      'price',
      'contactEmail',
      'imageUrl',
      'category',
      'releaseDate',
      'createdAt',
      'updatedAt',
      'stockQuantity',
      'status',
      'productCode',
    };
    return Map.fromEntries(
      map.entries.where((e) => !knownFields.contains(e.key)),
    );
  }
}

/// Generated schema for Category
/// A category for organizing products
class CategorySchema extends SchemaModel {
  CategorySchema();

  CategorySchema._valid(Map<String, Object?> data) : super.validated(data);

  @override
  late final definition = Ack.object(
    {
      'id': Ack.string,
      'name': Ack.string,
      'description': Ack.string.nullable(),
    },
    required: ['id', 'name'],
    additionalProperties: true,
  );

  @override
  CategorySchema parse(Object? input) {
    return super.parse(input) as CategorySchema;
  }

  @override
  CategorySchema? tryParse(Object? input) {
    return super.tryParse(input) as CategorySchema?;
  }

  @override
  @protected
  CategorySchema createValidated(Map<String, Object?> data) {
    return CategorySchema._valid(data);
  }

  String get id => getValue<String>('id');

  String get name => getValue<String>('name');

  String? get description => getValueOrNull<String>('description');

  Map<String, Object?> get metadata {
    final map = toMap();
    final knownFields = {'id', 'name', 'description'};
    return Map.fromEntries(
      map.entries.where((e) => !knownFields.contains(e.key)),
    );
  }
}
