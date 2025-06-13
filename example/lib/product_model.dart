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
  @IsMinLength(3)
  @IsMaxLength(100)
  final String name;

  @IsNotEmpty()
  @IsMaxLength(500)
  final String description;

  @IsMin(0.01)
  @IsMax(999999.99)
  final double price;

  @IsNullable()
  @IsEmail()
  final String? contactEmail;

  @IsNullable()
  final String? imageUrl;

  @IsRequired()
  final Category category;

  @IsDate()
  final String releaseDate;

  @IsDateTime()
  final String createdAt;

  @IsNullable()
  @IsDateTime()
  final String? updatedAt;

  @IsPositive()
  final int stockQuantity;

  @IsEnumValues(['draft', 'published', 'archived'])
  final String status;

  @IsPattern('^[A-Z]{2,3}-\\d{4}\$')
  final String productCode;

  final Map<String, dynamic> metadata;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.contactEmail,
    this.imageUrl,
    required this.category,
    required this.releaseDate,
    required this.createdAt,
    this.updatedAt,
    required this.stockQuantity,
    required this.status,
    required this.productCode,
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

  @IsNullable()
  final String? description;

  final Map<String, dynamic> metadata;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.metadata = const {},
  });
}
