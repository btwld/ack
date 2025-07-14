// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AckSchemaGenerator
// **************************************************************************

part of 'mixed_examples.dart';

/// Generated schema for BasicUser
/// Basic user model - generates only schema variable
final basicUserSchema = Ack.object({
  'id': Ack.string(),
  'username': Ack.string(),
  'email': Ack.string().optional().nullable(),
});

/// Generated schema for EnhancedUser
/// Enhanced user with SchemaModel for type safety
final enhancedUserSchema = Ack.object({
  'id': Ack.string(),
  'username': Ack.string(),
  'email': Ack.string(),
  'createdAt': Ack.string(),
});

/// Generated schema for Order
/// Order with status enum - schema only
final orderSchema = Ack.object({
  'id': Ack.string(),
  'status': Ack.string().enumString([
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ]),
  'total': Ack.double(),
});

/// Generated schema for BlogPost
/// Blog post with author - demonstrates nested models
final blogPostSchema = Ack.object({
  'id': Ack.string(),
  'title': Ack.string(),
  'content': Ack.string(),
  'author': enhancedUserSchema,
  'publishedAt': Ack.string(),
  'tags': Ack.list(Ack.string()),
}, additionalProperties: true);

/// Generated schema for ProductInventory
/// Product inventory with comprehensive constraints
final productInventorySchema = Ack.object({
  'sku': Ack.string().minLength(3).maxLength(50),
  'quantity': Ack.integer(),
  'unitPrice': Ack.double().min(0.01),
  'lastRestocked': Ack.string().matches(r'^\d{4}-\d{2}-\d{2}$'),
  'isAvailable': Ack.boolean(),
});

/// Generated SchemaModel for [EnhancedUser].
/// Enhanced user with SchemaModel for type safety
class EnhancedUserSchemaModel extends SchemaModel<EnhancedUser> {
  EnhancedUserSchemaModel._internal(ObjectSchema this.schema);

  factory EnhancedUserSchemaModel() {
    return EnhancedUserSchemaModel._internal(enhancedUserSchema);
  }

  EnhancedUserSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  EnhancedUser createFromMap(Map<String, dynamic> map) {
    return EnhancedUser(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      createdAt: map['createdAt'] as String,
    );
  }

  /// Returns a new schema with the specified description.
  EnhancedUserSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return EnhancedUserSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  EnhancedUserSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return EnhancedUserSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  EnhancedUserSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return EnhancedUserSchemaModel._withSchema(newSchema);
  }
}

/// Generated SchemaModel for [BlogPost].
/// Blog post with author - demonstrates nested models
class BlogPostSchemaModel extends SchemaModel<BlogPost> {
  BlogPostSchemaModel._internal(ObjectSchema this.schema);

  factory BlogPostSchemaModel() {
    return BlogPostSchemaModel._internal(blogPostSchema);
  }

  BlogPostSchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  BlogPost createFromMap(Map<String, dynamic> map) {
    return BlogPost(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      author: EnhancedUserSchemaModel().createFromMap(
        map['author'] as Map<String, dynamic>,
      ),
      publishedAt: map['publishedAt'] as String,
      tags: (map['tags'] as List).cast<String>(),
      metadata: extractAdditionalProperties(map, {
        'id',
        'title',
        'content',
        'author',
        'publishedAt',
        'tags',
      }),
    );
  }

  /// Returns a new schema with the specified description.
  BlogPostSchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return BlogPostSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  BlogPostSchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return BlogPostSchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  BlogPostSchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return BlogPostSchemaModel._withSchema(newSchema);
  }
}

/// Generated SchemaModel for [ProductInventory].
/// Product inventory with comprehensive constraints
class ProductInventorySchemaModel extends SchemaModel<ProductInventory> {
  ProductInventorySchemaModel._internal(ObjectSchema this.schema);

  factory ProductInventorySchemaModel() {
    return ProductInventorySchemaModel._internal(productInventorySchema);
  }

  ProductInventorySchemaModel._withSchema(ObjectSchema customSchema)
      : schema = customSchema;

  @override
  final ObjectSchema schema;

  @override
  ProductInventory createFromMap(Map<String, dynamic> map) {
    return ProductInventory(
      sku: map['sku'] as String,
      quantity: map['quantity'] as int,
      unitPrice: map['unitPrice'] as double,
      lastRestocked: map['lastRestocked'] as String,
      isAvailable: map['isAvailable'] as bool,
    );
  }

  /// Returns a new schema with the specified description.
  ProductInventorySchemaModel describe(String description) {
    final newSchema = schema.copyWith(description: description);
    return ProductInventorySchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with the specified default value.
  ProductInventorySchemaModel withDefault(Map<String, dynamic> defaultValue) {
    final newSchema = schema.copyWith(defaultValue: defaultValue);
    return ProductInventorySchemaModel._withSchema(newSchema);
  }

  /// Returns a new schema with nullable flag set to the specified value.
  ProductInventorySchemaModel nullable([bool value = true]) {
    final newSchema = schema.copyWith(isNullable: value);
    return ProductInventorySchemaModel._withSchema(newSchema);
  }
}
