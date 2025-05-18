// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_this, unnecessary_new, unnecessary_const, prefer_collection_literals
// ignore_for_file: lines_longer_than_80_chars, unnecessary_null_checks, non_constant_identifier_names

part of 'product_model.dart';

/// Generated schema for Product
/// A product model with validation
class ProductSchema extends SchemaModel<Product> {
  // Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {
        'id': Ack.string.isNotEmpty(),
        'name': Ack.string.isNotEmpty(),
        'description': Ack.string.isNotEmpty(),
        'price': Ack.double,
        'imageUrl': Ack.string.nullable(),
        'category': CategorySchema.schema,
      },
      required: ['id', 'name', 'description', 'price', 'category'],
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
  AckSchema getSchema() => schema;

  // Constructor that validates input
  ProductSchema([Object? value]) : super(value);

  // Type-safe getters
  String get id => getValue<String>('id')!;
  String get name => getValue<String>('name')!;
  String get description => getValue<String>('description')!;
  double get price => getValue<double>('price')!;
  String? get imageUrl => getValue<String>('imageUrl');
  CategorySchema get category {
    return CategorySchema(getValue<Map<String, dynamic>>('category')!);
  }

  // Get metadata with fallback
  Map<String, Object?> get metadata {
    final result = <String, Object?>{};
    final knownFields = [
      'id',
      'name',
      'description',
      'price',
      'imageUrl',
      'category'
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
      imageUrl: imageUrl,
      category: category.toModel(),
      metadata: metadata,
    );
  }

  /// Parses the input and returns a Product instance.
  /// Throws an [AckException] if validation fails.
  static Product parse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    if (result.isOk) {
      return ProductSchema(result.getOrNull()).toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a Product instance.
  /// Returns null if validation fails.
  static Product? tryParse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    return result.isOk ? ProductSchema(result.getOrNull()).toModel() : null;
  }

  /// Create a schema from a model instance
  static ProductSchema fromModel(Product model) {
    return ProductSchema(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel(Product instance) {
    final Map<String, Object?> result = {
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'imageUrl': instance.imageUrl,
      'category': CategorySchema.toMapFromModel(instance.category),
    };

    // Include additional properties
    if (instance.metadata.isNotEmpty) {
      result.addAll(instance.metadata);
    }

    return result;
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}

/// Generated schema for Category
/// A category for organizing products
class CategorySchema extends SchemaModel<Category> {
  // Schema definition moved to a static field for easier access
  static final ObjectSchema schema = _createSchema();

  // Create the validation schema
  static ObjectSchema _createSchema() {
    return Ack.object(
      {
        'id': Ack.string.isNotEmpty(),
        'name': Ack.string.isNotEmpty(),
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
  AckSchema getSchema() => schema;

  // Constructor that validates input
  CategorySchema([Object? value]) : super(value);

  // Type-safe getters
  String get id => getValue<String>('id')!;
  String get name => getValue<String>('name')!;
  String? get description => getValue<String>('description');

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

  /// Parses the input and returns a Category instance.
  /// Throws an [AckException] if validation fails.
  static Category parse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    if (result.isOk) {
      return CategorySchema(result.getOrNull()).toModel();
    }
    throw AckException(result.getError()!);
  }

  /// Attempts to parse the input and returns a Category instance.
  /// Returns null if validation fails.
  static Category? tryParse(Object? input, {String? debugName}) {
    final result = schema.validate(input, debugName: debugName);
    return result.isOk ? CategorySchema(result.getOrNull()).toModel() : null;
  }

  /// Create a schema from a model instance
  static CategorySchema fromModel(Category model) {
    return CategorySchema(toMapFromModel(model));
  }

  /// Static version of toMap to maintain compatibility
  static Map<String, Object?> toMapFromModel(Category instance) {
    final Map<String, Object?> result = {
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
    };

    // Include additional properties
    if (instance.metadata.isNotEmpty) {
      result.addAll(instance.metadata);
    }

    return result;
  }

  /// Convert the schema to a JSON Schema
  static Map<String, Object?> toJsonSchema() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }
}

