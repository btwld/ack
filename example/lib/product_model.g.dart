// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_this, unnecessary_new, unnecessary_const, prefer_collection_literals
// ignore_for_file: lines_longer_than_80_chars, unnecessary_null_checks, non_constant_identifier_names

part of 'product_model.dart';

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

/// Generated schema for Product
/// A product model with validation
class ProductSchema extends BaseSchema<Product> {
  // Constructor that validates input
  ProductSchema([Object? value = null]) : super(value);

// Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

// Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
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
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<Product, ProductSchema>(
      (data) => ProductSchema(data),
    );
    // Register schema dependencies
    CategorySchema.ensureInitialize();
  }

// Override to return the schema for validation
  @override
  AckSchema getSchema() {
    return schema;
  }

// Type-safe getters
  String get id {
    return getValue<String>('id')!;
  }

// Type-safe getters
  String get name {
    return getValue<String>('name')!;
  }

// Type-safe getters
  String get description {
    return getValue<String>('description')!;
  }

// Type-safe getters
  double get price {
    return getValue<double>('price')!;
  }

// Type-safe getters
  String? get contactEmail {
    return getValue<String>('contactEmail');
  }

// Type-safe getters
  String? get imageUrl {
    return getValue<String>('imageUrl');
  }

// Type-safe getters
  CategorySchema get category {
    return CategorySchema(getValue<Map<String, dynamic>>('category')!);
  }

// Type-safe getters
  String get releaseDate {
    return getValue<String>('releaseDate')!;
  }

// Type-safe getters
  String get createdAt {
    return getValue<String>('createdAt')!;
  }

// Type-safe getters
  String? get updatedAt {
    return getValue<String>('updatedAt');
  }

// Type-safe getters
  int get stockQuantity {
    return getValue<int>('stockQuantity')!;
  }

// Type-safe getters
  String get status {
    return getValue<String>('status')!;
  }

// Type-safe getters
  String get productCode {
    return getValue<String>('productCode')!;
  }

// Get metadata with fallback
  Map<String, Object?> get metadata {
    final result = <String, Object?>{};
    final knownFields = [
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
    ];

    for (final key in toMap().keys) {
      if (!knownFields.contains(key)) {
        result[key] = toMap()[key];
      }
    }
    return result;
  }

// Model conversion methods
  @override
  Product toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      contactEmail: contactEmail,
      imageUrl: imageUrl,
      category: category.toModel(),
      releaseDate: releaseDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      stockQuantity: stockQuantity,
      status: status,
      productCode: productCode,
      metadata: metadata,
    );
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = JsonSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}

/// Generated schema for Category
/// A category for organizing products
class CategorySchema extends BaseSchema<Category> {
  // Constructor that validates input
  CategorySchema([Object? value = null]) : super(value);

// Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

// Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {
        'id': Ack.string.notEmpty(),
        'name': Ack.string.notEmpty(),
        'description': Ack.string.nullable(),
      },
      required: ['id', 'name'],
      additionalProperties: true,
    );
  }

  /// Ensures this schema and its dependencies are registered
  static void ensureInitialize() {
    SchemaRegistry.register<Category, CategorySchema>(
      (data) => CategorySchema(data),
    );
  }

// Override to return the schema for validation
  @override
  AckSchema getSchema() {
    return schema;
  }

// Type-safe getters
  String get id {
    return getValue<String>('id')!;
  }

// Type-safe getters
  String get name {
    return getValue<String>('name')!;
  }

// Type-safe getters
  String? get description {
    return getValue<String>('description');
  }

// Get metadata with fallback
  Map<String, Object?> get metadata {
    final result = <String, Object?>{};
    final knownFields = ['id', 'name', 'description'];

    for (final key in toMap().keys) {
      if (!knownFields.contains(key)) {
        result[key] = toMap()[key];
      }
    }
    return result;
  }

// Model conversion methods
  @override
  Category toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }
    return Category(
      id: id,
      name: name,
      description: description,
      metadata: metadata,
    );
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = JsonSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}
