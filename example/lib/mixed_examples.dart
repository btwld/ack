import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

// This file demonstrates different model configurations
part 'mixed_examples.g.dart';

/// Example 1: Schema-only (default behavior)
@AckModel(description: 'Basic user model - generates only schema variable')
class BasicUser {
  final String id;
  final String username;
  final String? email;

  BasicUser({required this.id, required this.username, this.email});
}

/// Example 2: Enhanced user with validation
@AckModel(description: 'Enhanced user with comprehensive validation')
class EnhancedUser {
  final String id;
  final String username;
  final String email;
  final String createdAt; // ISO 8601 date string

  EnhancedUser({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
  });
}

/// Example 3: Enum example with schema-only
@AckModel(description: 'Order with status enum - schema only')
class Order {
  final String id;

  @EnumString(['pending', 'processing', 'shipped', 'delivered', 'cancelled'])
  final String status;

  final double total;

  Order({required this.id, required this.status, required this.total});
}

/// Example 4: Complex nested model
@AckModel(
  description: 'Blog post with author - demonstrates nested models',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class BlogPost {
  final String id;
  final String title;
  final String content;
  final EnhancedUser author;
  final String publishedAt; // ISO 8601 date string
  final List<String> tags;
  final Map<String, dynamic> metadata;

  BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.publishedAt,
    required this.tags,
    this.metadata = const {},
  });
}

/// Example 5: Model with various constraints
@AckModel(description: 'Product inventory with comprehensive constraints')
class ProductInventory {
  @MinLength(3)
  @MaxLength(50)
  final String sku;

  @Min(0)
  @Max(10000)
  final int quantity;

  @Min(0.01)
  final double unitPrice;

  @Pattern(r'^\d{4}-\d{2}-\d{2}$')
  final String lastRestocked;

  final bool isAvailable;

  ProductInventory({
    required this.sku,
    required this.quantity,
    required this.unitPrice,
    required this.lastRestocked,
    required this.isAvailable,
  });
}

// Example usage demonstrating different approaches
void main() {
  print('🎯 Mixed Model Examples\n');

  // Example 1: Schema-only validation
  print('1️⃣ Basic User (schema-only):');
  final basicUserData = {
    'id': 'user_123',
    'username': 'johndoe',
    'email': 'john@example.com',
  };

  try {
    final result = basicUserSchema.parse(basicUserData) as Map<String, dynamic>;
    print('   ✅ Valid: ${result['username']}');
  } catch (e) {
    print('   ❌ Error: $e');
  }

  // Example 2: Enhanced User validation
  print('\n2️⃣ Enhanced User (schema validation):');
  final enhancedUserData = {
    'id': 'user_456',
    'username': 'janedoe',
    'email': 'jane@example.com',
    'createdAt': '2024-01-15T10:30:00Z',
  };

  try {
    final result =
        enhancedUserSchema.parse(enhancedUserData) as Map<String, dynamic>;
    print('   ✅ Valid user:');
    print('      Username: ${result['username']}');
    print('      Email: ${result['email']}');
    print('      Created: ${result['createdAt']}');
  } catch (e) {
    print('   ❌ Error: $e');
  }

  // Example 3: Enum validation
  print('\n3️⃣ Order Status (enum validation):');
  final orderData = {'id': 'order_789', 'status': 'shipped', 'total': 149.99};

  try {
    final result = orderSchema.parse(orderData) as Map<String, dynamic>;
    print('   ✅ Valid status: ${result['status']}');
  } catch (e) {
    print('   ❌ Error: $e');
  }

  // Example 4: Nested models validation
  print('\n4️⃣ Blog Post (nested models):');
  final blogData = {
    'id': 'post_001',
    'title': 'Getting Started with Ack',
    'content': 'Learn how to use schema validation...',
    'author': enhancedUserData,
    'publishedAt': '2024-01-20T14:00:00Z',
    'tags': ['dart', 'validation', 'tutorial'],
    'viewCount': 1500,
    'featured': true,
  };

  try {
    final result = blogPostSchema.parse(blogData) as Map<String, dynamic>;
    print('   ✅ Blog post: ${result['title']}');
    print(
      '      Author: ${(result['author'] as Map<String, dynamic>)['username']}',
    );
    print('      Tags: ${(result['tags'] as List).join(', ')}');
    print('      Metadata: ${result['metadata']}');
  } catch (e) {
    print('   ❌ Error: $e');
  }

  // Example 5: Constraints validation
  print('\n5️⃣ Product Inventory (constraints):');

  // Valid data
  final validInventory = {
    'sku': 'PROD-123',
    'quantity': 50,
    'unitPrice': 29.99,
    'lastRestocked': '2024-01-15',
    'isAvailable': true,
  };

  try {
    final result =
        productInventorySchema.parse(validInventory) as Map<String, dynamic>;
    print('   ✅ Valid inventory: SKU ${result['sku']}');
  } catch (e) {
    print('   ❌ Error: $e');
  }

  // Invalid data
  final invalidInventory = {
    'sku': 'PR', // Too short
    'quantity': -5, // Negative
    'unitPrice': 0, // Below minimum
    'lastRestocked': '2024/01/15', // Wrong format
    'isAvailable': true,
  };

  try {
    productInventorySchema.parse(invalidInventory);
  } catch (e) {
    print('   ❌ Validation errors detected');
  }

  print('\n✨ Examples demonstrate:');
  print('   - Schema validation');
  print('   - Enum validation');
  print('   - Nested model support');
  print('   - Constraint validation');
  print('   - Additional properties handling');
}
