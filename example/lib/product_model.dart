import 'package:ack/ack.dart';

// Add part directive for the generated code
part 'product_model.g.dart';

@Schema(
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

@Schema(
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
}
