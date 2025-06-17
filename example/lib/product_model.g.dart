// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_this, unnecessary_new, unnecessary_const, prefer_collection_literals
// ignore_for_file: lines_longer_than_80_chars, unnecessary_null_checks, non_constant_identifier_names

part of 'product_model.dart';

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

/// Generated schema for Product
/// A product model with validation
class ProductSchema extends BaseSchema<ProductSchema> {
  /// Default constructor for parser instances
  const ProductSchema();

  /// Private constructor for validated instances
  const ProductSchema._valid(Map<String, Object?> data) : super.valid(data);

  static final ObjectSchema schema = Ack.object(
    {
      'id': Ack.string.notEmpty(),
      'name': Ack.string.notEmpty().minLength(3).maxLength(100),
      'description': Ack.string.notEmpty().maxLength(500),
      'price': Ack.double.min(0.01).max(999999.99),
      'contactEmail': Ack.string.email().nullable(),
      'imageUrl': Ack.string.nullable(),
      'category': CategorySchema.schema,
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

  /// Parse with validation - core implementation
  @override
  ProductSchema parse(Object? data) {
    final result = definition.validate(data);
    if (result.isOk) {
      final validatedData = Map<String, Object?>.from(
        result.getOrThrow(),
      );
      return ProductSchema._valid(validatedData);
    }
    throw AckException(result.getError());
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<ProductSchema>(
      (data) => const ProductSchema().parse(data),
    );
    // Register schema dependencies
    CategorySchema.ensureInitialize();
  }

  @override
  ObjectSchema get definition => schema;

  String get id => getValue<String>('id')!;

  String get name => getValue<String>('name')!;

  String get description => getValue<String>('description')!;

  double get price => getValue<double>('price')!;

  String? get contactEmail => getValue<String>('contactEmail');

  String? get imageUrl => getValue<String>('imageUrl');

  CategorySchema get category {
    return const CategorySchema()
        .parse(getValue<Map<String, Object?>>('category')!);
  }

  String get releaseDate => getValue<String>('releaseDate')!;

  String get createdAt => getValue<String>('createdAt')!;

  String? get updatedAt => getValue<String>('updatedAt');

  int get stockQuantity => getValue<int>('stockQuantity')!;

  String get status => getValue<String>('status')!;

  String get productCode => getValue<String>('productCode')!;

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
  static Map<String, Object?> toJsonSchema() =>
      JsonSchemaConverter(schema: schema).toSchema();
}

/// Generated schema for Category
/// A category for organizing products
class CategorySchema extends BaseSchema<CategorySchema> {
  /// Default constructor for parser instances
  const CategorySchema();

  /// Private constructor for validated instances
  const CategorySchema._valid(Map<String, Object?> data) : super.valid(data);

  static final ObjectSchema schema = Ack.object(
    {
      'id': Ack.string.notEmpty(),
      'name': Ack.string.notEmpty(),
      'description': Ack.string.nullable(),
    },
    required: ['id', 'name'],
    additionalProperties: true,
  );

  /// Parse with validation - core implementation
  @override
  CategorySchema parse(Object? data) {
    final result = definition.validate(data);
    if (result.isOk) {
      final validatedData = Map<String, Object?>.from(
        result.getOrThrow(),
      );
      return CategorySchema._valid(validatedData);
    }
    throw AckException(result.getError());
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<CategorySchema>(
      (data) => const CategorySchema().parse(data),
    );
  }

  @override
  ObjectSchema get definition => schema;

  String get id => getValue<String>('id')!;

  String get name => getValue<String>('name')!;

  String? get description => getValue<String>('description');

  Map<String, Object?> get metadata {
    final map = toMap();
    final knownFields = {'id', 'name', 'description'};
    return Map.fromEntries(
        map.entries.where((e) => !knownFields.contains(e.key)));
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() =>
      JsonSchemaConverter(schema: schema).toSchema();
}
