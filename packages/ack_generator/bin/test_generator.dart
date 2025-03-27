import 'dart:io';

import 'package:path/path.dart' as p;

void main() async {
  print('Running schema generator test...');

  // Create mock product_model file with necessary imports and class definitions
  const productModelContent = '''
import 'package:ack_generator/ack_generator.dart';
import 'package:ack/ack.dart';

// Mock necessary base classes for analyzer
abstract class SchemaModel<T> {
  final Map<String, dynamic> _data;
  SchemaModel(this._data);
  SchemaModel._validated(this._data);
  Map<String, dynamic> toMap() => _data;
  T? getValue<T>(String key) => _data[key] as T?;
  T toModel();
}

abstract class SchemaResult<T> {
  bool get isFail;
  dynamic getError();
  T getOrThrow();
  static SchemaResult<T> fail<T>(dynamic error) => throw UnimplementedError();
  static SchemaResult<T> ok<T>(T value) => throw UnimplementedError();
}

class AckException {
  final dynamic error;
  AckException(this.error);
}

class ObjectSchema {
  SchemaResult validate(Map<String, dynamic> data) => throw UnimplementedError();
}

class OpenApiSchemaConverter {
  OpenApiSchemaConverter({required this.schema});
  final ObjectSchema schema;
  Map<String, Object?> toSchema() => {};
}

String prettyJson(Object? data) => '';

class Ack {
  static ObjectSchema object(Map<String, dynamic> properties, {List<String>? required, bool? additionalProperties}) => 
    throw UnimplementedError();
  static dynamic get string => _MockAck();
  static dynamic get int => _MockAck();
  static dynamic get double => _MockAck();
  static dynamic get boolean => _MockAck();
  static dynamic list(dynamic itemSchema) => _MockAck();
}

class _MockAck {
  dynamic isEmail() => this;
  dynamic isNotEmpty() => this;
  dynamic pattern(String pattern) => this;
  dynamic nullable() => this;
}

class SchemaRegistry {
  static void register<M, S extends SchemaModel<M>>(
    S Function(Map<String, dynamic>) factory,
  ) {}
}

// Actual model classes
@AckModel(
  description: 'A product model with validation',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class Product {
  @IsNotEmpty()
  final String id;
  
  @IsNotEmpty()
  final String name;
  
  @IsNotEmpty()
  final String description;
  
  final double price;
  
  @Nullable()
  final String? imageUrl;
  
  @Required()
  final Category category;
  
  final Map<String, dynamic> metadata;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    this.metadata = const {},
  });
}

@AckModel(
  description: 'A category for organizing products',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class Category {
  @IsNotEmpty()
  final String id;
  
  @IsNotEmpty()
  final String name;
  
  @Nullable()
  final String? description;
  
  final Map<String, dynamic> metadata;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.metadata = const {},
  });
  
  // Add toModel method to make analyzer happy
  Category toModel() => this;
}
''';

  // Create a directory for the output
  final outputDir = Directory('test_output');
  if (!outputDir.existsSync()) {
    outputDir.createSync();
  }

  // Write the test model file
  final modelFile = File(p.join(outputDir.path, 'product_model.dart'));
  modelFile.writeAsStringSync(productModelContent);
  print('Test model file created at: ${modelFile.absolute.path}');

  // Create mock data for manual code generation
  print('Manually creating example schema...');

  // Create example Product schema
  String productSchema = '''
// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: unnecessary_this, unnecessary_new, unnecessary_const, prefer_collection_literals
// ignore_for_file: lines_longer_than_80_chars, unnecessary_null_checks, non_constant_identifier_names

import 'package:ack/ack.dart';
import 'package:ack/src/builder_helpers/schema_registry.dart';
import 'package:ack/src/schemas/schema_model.dart';
import 'package:ack/src/validation/ack_exception.dart';
import 'package:ack/src/validation/schema_result.dart';
import 'package:ack/src/converters/open_api_schema.dart';
import 'package:ack/src/helpers.dart';

import 'product_model.dart';

/// Generated schema for Product
/// A product model with validation
class ProductSchema extends SchemaModel<Product> {
  // Self-registration - executed when the class is loaded
  static final bool _init = _initialize();

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

  // Private initialization method for self-registration
  static bool _initialize() {
    SchemaRegistry.register<Product, ProductSchema>(
      ProductSchema.parse,
    );
    return true;
  }

  // Constructors
  ProductSchema([Map<String, dynamic>? data]) : super(data ?? {});

  ProductSchema._validated(Map<String, dynamic> data) : super._validated(data);

  /// Factory methods for parsing data
  static ProductSchema parse(Map<String, dynamic> data) {
    final result = schema.validate(data);

    if (result.isFail) {
      throw AckException(result.getError());
    }

    return ProductSchema._validated(result.getOrThrow());
  }

  static ProductSchema? tryParse(Map<String, dynamic> data) {
    try {
      return parse(data);
    } catch (_) {
      return null;
    }
  }

  /// Static helper to validate a map
  static SchemaResult validateMap(Map<String, dynamic> map) {
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
  Category get category => getValue<Category>('category')!;

  // Get metadata with fallback
  Map<String, dynamic> get metadata {
    final result = <String, dynamic>{};
    final knownFields = ['id', 'name', 'description', 'price', 'imageUrl', 'category'];

    for (final key in _data.keys) {
      if (!knownFields.contains(key)) {
        result[key] = _data[key];
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
    return prettyJson(toOpenApiSpec());
  }

  /// Validate and convert to an instance - maintaining compatibility
  static SchemaResult<Product> createFromMap(Map<String, Object?> map) {
    final result = schema.validate(map);
    if (result.isFail) {
      return SchemaResult.fail(result.getError());
    }

    return SchemaResult.ok(ProductSchema._validated(result.getOrThrow()).toModel());
  }
}

/// Generated schema for Category
/// A category for organizing products
class CategorySchema extends SchemaModel<Category> {
  // Self-registration - executed when the class is loaded
  static final bool _init = _initialize();

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

  // Private initialization method for self-registration
  static bool _initialize() {
    SchemaRegistry.register<Category, CategorySchema>(
      CategorySchema.parse,
    );
    return true;
  }

  // Constructors
  CategorySchema([Map<String, dynamic>? data]) : super(data ?? {});

  CategorySchema._validated(Map<String, dynamic> data) : super._validated(data);

  /// Factory methods for parsing data
  static CategorySchema parse(Map<String, dynamic> data) {
    final result = schema.validate(data);

    if (result.isFail) {
      throw AckException(result.getError());
    }

    return CategorySchema._validated(result.getOrThrow());
  }

  static CategorySchema? tryParse(Map<String, dynamic> data) {
    try {
      return parse(data);
    } catch (_) {
      return null;
    }
  }

  /// Static helper to validate a map
  static SchemaResult validateMap(Map<String, dynamic> map) {
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
  Map<String, dynamic> get metadata {
    final result = <String, dynamic>{};
    final knownFields = ['id', 'name', 'description'];

    for (final key in _data.keys) {
      if (!knownFields.contains(key)) {
        result[key] = _data[key];
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
    return prettyJson(toOpenApiSpec());
  }

  /// Validate and convert to an instance - maintaining compatibility
  static SchemaResult<Category> createFromMap(Map<String, Object?> map) {
    final result = schema.validate(map);
    if (result.isFail) {
      return SchemaResult.fail(result.getError());
    }

    return SchemaResult.ok(CategorySchema._validated(result.getOrThrow()).toModel());
  }
}
''';

  // Write the schema to a file
  final schemaFile = File(p.join(outputDir.path, 'product_model.schema.dart'));
  schemaFile.writeAsStringSync(productSchema);

  print('Schema file saved to: ${schemaFile.absolute.path}');
}
