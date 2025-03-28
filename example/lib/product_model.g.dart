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
      ProductSchema.parse,
    );
    // Register schema dependencies
    CategorySchema.ensureInitialize();
  }

  // Initialize method that calls the static method
  @override
  void initialize() {
    ProductSchema.ensureInitialize();
  }

  // Constructors
  ProductSchema([Map<String, Object?>? data]) : super(data ?? {});

  // Internal constructor for validated data
  factory ProductSchema.fromValidated(Map<String, Object?> data) {
    final schema = ProductSchema(data);
    // Mark as pre-validated (implementation detail)
    return schema;
  }

  /// Factory methods for parsing data
  static ProductSchema parse(Map<String, Object?> data) {
    final result = schema.validate(data);

    if (result.isFail) {
      throw AckException(result.getError());
    }

    return ProductSchema(result.getOrThrow());
  }

  static ProductSchema? tryParse(Map<String, Object?> data) {
    try {
      return parse(data);
    } catch (_) {
      return null;
    }
  }

  /// Static helper to validate a map
  static SchemaResult validateMap(Map<String, Object?> map) {
    return schema.validate(map);
  }

  /// Validate the current data
  @override
  SchemaResult validate() {
    return schema.validate(toMap());
  }

  // Type-safe getters
  String get id => getValue<String>('id')!;
  String get name => getValue<String>('name')!;
  String get description => getValue<String>('description')!;
  double get price => getValue<double>('price')!;
  String? get imageUrl => getValue<String>('imageUrl');
  CategorySchema get category {
    return CategorySchema.parse(getValue<Map<String, dynamic>>('category')!);
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

  /// Convert from a model instance to a schema
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

  /// Convert the schema to OpenAPI specification format
  static Map<String, Object?> toOpenApiSpec() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }

  /// Convert the schema to OpenAPI specification JSON string
  static String toOpenApiSpecString() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchemaString();
  }

  /// Validate and convert to an instance - maintaining compatibility
  static SchemaResult<Product> createFromMap(Map<String, Object?> map) {
    final result = schema.validate(map);
    if (result.isFail) {
      return SchemaResult.fail(result.getError());
    }

    return SchemaResult.ok(ProductSchema(result.getOrThrow()).toModel());
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
      CategorySchema.parse,
    );
  }

  // Initialize method that calls the static method
  @override
  void initialize() {
    CategorySchema.ensureInitialize();
  }

  // Constructors
  CategorySchema([Map<String, Object?>? data]) : super(data ?? {});

  // Internal constructor for validated data
  factory CategorySchema.fromValidated(Map<String, Object?> data) {
    final schema = CategorySchema(data);
    // Mark as pre-validated (implementation detail)
    return schema;
  }

  /// Factory methods for parsing data
  static CategorySchema parse(Map<String, Object?> data) {
    final result = schema.validate(data);

    if (result.isFail) {
      throw AckException(result.getError());
    }

    return CategorySchema(result.getOrThrow());
  }

  static CategorySchema? tryParse(Map<String, Object?> data) {
    try {
      return parse(data);
    } catch (_) {
      return null;
    }
  }

  /// Static helper to validate a map
  static SchemaResult validateMap(Map<String, Object?> map) {
    return schema.validate(map);
  }

  /// Validate the current data
  @override
  SchemaResult validate() {
    return schema.validate(toMap());
  }

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
    return Category(
      id: id,
      name: name,
      description: description,
      metadata: metadata,
    );
  }

  /// Convert from a model instance to a schema
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

  /// Convert the schema to OpenAPI specification format
  static Map<String, Object?> toOpenApiSpec() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchema();
  }

  /// Convert the schema to OpenAPI specification JSON string
  static String toOpenApiSpecString() {
    final converter = OpenApiSchemaConverter(schema: schema);
    return converter.toSchemaString();
  }

  /// Validate and convert to an instance - maintaining compatibility
  static SchemaResult<Category> createFromMap(Map<String, Object?> map) {
    final result = schema.validate(map);
    if (result.isFail) {
      return SchemaResult.fail(result.getError());
    }

    return SchemaResult.ok(CategorySchema(result.getOrThrow()).toModel());
  }
}

