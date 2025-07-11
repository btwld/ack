// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'product_model.dart';

/// Generated schema for Product
/// A product model with validation
final productSchema = Ack.object({
  'id': Ack.string().minLength(1),
  'name': Ack.string().minLength(3),
  'description': Ack.string(),
  'price': Ack.double().min(0.01),
  'contactEmail': Ack.string().email().optional().nullable(),
  'imageUrl': Ack.string().url().optional().nullable(),
  'category': categorySchema,
  'releaseDate': Ack.string(),
  'createdAt': Ack.string(),
  'updatedAt': Ack.string().optional().nullable(),
  'stockQuantity': Ack.integer().positive(),
  'status': Ack.string().enumString(['draft', 'published', 'archived']),
  'productCode': Ack.string().matches(r'^[A-Z]{2,3}-\d{4}$'),
}, additionalProperties: true);

/// Generated schema for Category
/// A category for organizing products
final categorySchema = Ack.object({
  'id': Ack.string(),
  'name': Ack.string(),
  'description': Ack.string().optional().nullable(),
}, additionalProperties: true);

/// Generated SchemaModel for [Product].
/// A product model with validation
class ProductSchemaModel extends SchemaModel<Product> {
  ProductSchemaModel._();

  factory ProductSchemaModel() {
    return _instance;
  }

  static final _instance = ProductSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return productSchema;
  }

  @override
  Product createFromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      price: map['price'] as double,
      contactEmail: map['contactEmail'] as String?,
      imageUrl: map['imageUrl'] as String?,
      category: CategorySchemaModel._instance.createFromMap(
        map['category'] as Map<String, dynamic>,
      ),
      releaseDate: map['releaseDate'] as String,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String?,
      stockQuantity: map['stockQuantity'] as int,
      status: map['status'] as String,
      productCode: map['productCode'] as String,
      metadata: extractAdditionalProperties(map, {
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
        'productCode',
      }),
    );
  }
}

/// Generated SchemaModel for [Category].
/// A category for organizing products
class CategorySchemaModel extends SchemaModel<Category> {
  CategorySchemaModel._();

  factory CategorySchemaModel() {
    return _instance;
  }

  static final _instance = CategorySchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return categorySchema;
  }

  @override
  Category createFromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      metadata: extractAdditionalProperties(map, {'id', 'name', 'description'}),
    );
  }
}
