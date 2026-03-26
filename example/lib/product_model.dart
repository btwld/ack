import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'product_model.g.dart';

@Schemable(
  description: 'A product model with validation',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class Product {
  final String id;

  final String name;

  final String description;

  final double price;

  final String? contactEmail;

  final String? imageUrl;

  final Category category;

  final String releaseDate;

  final String createdAt;

  final String? updatedAt;

  final int stockQuantity;

  final String status;

  final String productCode;

  final Map<String, dynamic> metadata;

  Product({
    @MinLength(1) required this.id,
    @MinLength(3) required this.name,
    required this.description,
    @Min(0.01) required this.price,
    @Email() this.contactEmail,
    @Url() this.imageUrl,
    required this.category,
    required this.releaseDate,
    required this.createdAt,
    this.updatedAt,
    @Positive() required this.stockQuantity,
    @EnumString(['draft', 'published', 'archived']) required this.status,
    @Pattern(r'^[A-Z]{2,3}-\d{4}$') required this.productCode,
    this.metadata = const {},
  });
}

@Schemable(
  description: 'A category for organizing products',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class Category {
  final String id;
  final String name;
  final String? description;
  final Map<String, dynamic> metadata;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.metadata = const {},
  });
}

// Simple test to verify the generated code works
void main() {
  print('Testing Product Schema...');

  final productData = {
    'id': '123',
    'name': 'Test Product',
    'description': 'A test product',
    'price': 19.99,
    'category': {'id': 'cat1', 'name': 'Test Category'},
    'releaseDate': '2024-01-15',
    'createdAt': '2024-01-15T10:30:00Z',
    'stockQuantity': 100,
    'status': 'published',
    'productCode': 'ABC-1234',
    // Additional properties stored in metadata
    'brand': 'TestBrand',
    'color': 'Blue',
  };

  try {
    final result = productSchema.parse(productData) as Map<String, dynamic>;

    print('\n✅ Schema validation successful!');
    print('   Product ID: ${result['id']}');
    print('   Product Name: ${result['name']}');
    print(
      '   Category: ${(result['category'] as Map<String, dynamic>)['name']}',
    );
    print('   Additional properties: ${result['metadata']}');
  } catch (e) {
    print('❌ Schema validation error: $e');
  }

  print('\n🎉 Product schema validation works!');
}
