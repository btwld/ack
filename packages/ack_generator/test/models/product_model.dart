import 'package:ack_generator/ack_generator.dart';

/// A product with validation
@Schema(
  description: 'A product model with validation',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class Product {
  /// Unique identifier for the product
  @IsNotEmpty()
  final String id;

  /// Name of the product (cannot be empty)
  @IsNotEmpty()
  final String name;

  /// Product description
  @IsNotEmpty()
  final String description;

  /// Product price (should be positive)
  final double price;

  /// Optional URL to product image
  @Nullable()
  final String? imageUrl;

  /// Product category
  @Required()
  final Category category;

  /// Additional metadata for the product
  final Map<String, dynamic> metadata;

  /// Constructor for creating a product
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

/// Category for organizing products
@Schema(
  description: 'A category for organizing products',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class Category {
  /// Unique identifier for the category
  @IsNotEmpty()
  final String id;

  /// Name of the category (cannot be empty)
  @IsNotEmpty()
  final String name;

  /// Optional description of the category
  @Nullable()
  final String? description;

  /// Additional metadata for the category
  final Map<String, dynamic> metadata;

  /// Constructor for creating a category
  Category({
    required this.id,
    required this.name,
    this.description,
    this.metadata = const {},
  });
}
