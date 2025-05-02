import 'package:ack_generator/ack_generator.dart';
import 'package:ack/ack.dart';

// Mock necessary base classes for analyzer
abstract class SchemaModel<T> {
  final Map<String, dynamic> data;
  SchemaModel(this.data);
  SchemaModel.validated(this.data);
  Map<String, dynamic> toMap() => data;
  T? getValue<T>(String key) => data[key] as T?;
  T toModel();
  T create(Map<String, Object?> data);
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
