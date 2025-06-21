// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_this, unnecessary_new, unnecessary_const, prefer_collection_literals
// ignore_for_file: lines_longer_than_80_chars, unnecessary_null_checks, non_constant_identifier_names

part of 'product_model.dart';

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

/// Generated schema for Product
/// A product model with validation
class ProductSchema extends SchemaModel {
  /// Default constructor for parser instances
  ProductSchema();

  /// Private constructor for validated instances
  ProductSchema._valid(Map<String, Object?> data) : super.validated(data);

  @override
  late final definition = Ack.object(
    {
      'id': Ack.string.notEmpty(),
      'name': Ack.string.notEmpty().minLength(3).maxLength(100),
      'description': Ack.string.notEmpty().maxLength(500),
      'price': Ack.double.min(0.01).max(999999.99),
      'contactEmail': Ack.string.email().nullable(),
      'imageUrl': Ack.string.nullable(),
      'category': CategorySchema().definition,
      'releaseDate': Ack.string.date(),
      'createdAt': Ack.string.dateTime(),
      'updatedAt': Ack.string.dateTime().nullable(),
      'stockQuantity': Ack.int.positive(),
      'status': Ack.string.enumValues(['draft', 'published', 'archived']),
      'productCode': Ack.string.matches('^[A-Z]{2,3}-\\d{4}\$'),
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
      'productCode'
    ],
    additionalProperties: true,
  );

  /// Override with covariant return type - returns ProductSchema!
  @override
  ProductSchema parse(Object? input) {
    return super.parse(input) as ProductSchema;
  }

  /// Override with covariant return type
  @override
  ProductSchema? tryParse(Object? input) {
    return super.tryParse(input) as ProductSchema?;
  }

  @override
  ProductSchema createValidated(Map<String, Object?> data) {
    return ProductSchema._valid(data);
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<ProductSchema>(
      (data) => ProductSchema().parse(data),
    );
    // Register schema dependencies
    CategorySchema.ensureInitialize();
  }

  String get id => getValue<String>('id');

  String get name => getValue<String>('name');

  String get description => getValue<String>('description');

  double get price => getValue<double>('price');

  String? get contactEmail => getValueOrNull<String>('contactEmail');

  String? get imageUrl => getValueOrNull<String>('imageUrl');

  CategorySchema get category {
    return CategorySchema().parse(getValue<Map<String, Object?>>('category'));
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
      'productCode'
    };
    return Map.fromEntries(
        map.entries.where((e) => !knownFields.contains(e.key)));
  }

  /// Convert the schema to a JSON Schema
  Map<String, Object?> toJsonSchema() =>
      JsonSchemaConverter(schema: definition).toSchema();
}

/// Generated schema for Category
/// A category for organizing products
class CategorySchema extends SchemaModel {
  /// Default constructor for parser instances
  CategorySchema();

  /// Private constructor for validated instances
  CategorySchema._valid(Map<String, Object?> data) : super.validated(data);

  @override
  late final definition = Ack.object(
    {
      'id': Ack.string.notEmpty(),
      'name': Ack.string.notEmpty(),
      'description': Ack.string.nullable(),
    },
    required: ['id', 'name'],
    additionalProperties: true,
  );

  /// Override with covariant return type - returns CategorySchema!
  @override
  CategorySchema parse(Object? input) {
    return super.parse(input) as CategorySchema;
  }

  /// Override with covariant return type
  @override
  CategorySchema? tryParse(Object? input) {
    return super.tryParse(input) as CategorySchema?;
  }

  @override
  CategorySchema createValidated(Map<String, Object?> data) {
    return CategorySchema._valid(data);
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<CategorySchema>(
      (data) => CategorySchema().parse(data),
    );
  }

  String get id => getValue<String>('id');

  String get name => getValue<String>('name');

  String? get description => getValueOrNull<String>('description');

  Map<String, Object?> get metadata {
    final map = toMap();
    final knownFields = {'id', 'name', 'description'};
    return Map.fromEntries(
        map.entries.where((e) => !knownFields.contains(e.key)));
  }

  /// Convert the schema to a JSON Schema
  Map<String, Object?> toJsonSchema() =>
      JsonSchemaConverter(schema: definition).toSchema();
}
