import 'package:ack_annotations/ack_annotations.dart';

// Import generated schemas
import 'simple_examples.g.dart';

/// Example 1: User with Additional Properties
/// Shows how to store flexible user preferences
@AckModel(
  description: 'User with flexible preferences',
  additionalProperties: true,
  additionalPropertiesField: 'preferences',
)
class User {
  final String id;
  final String name;
  final String email;

  /// This field stores all extra properties like theme, language, etc.
  final Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.preferences = const {},
  });
}

/// Example 2: Product with Metadata
/// Shows how to store product variants and SEO data
@AckModel(
  description: 'Product with flexible metadata',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class Product {
  final String id;
  final String name;
  final double price;

  /// This field stores extra data like brand, color, warranty, etc.
  final Map<String, dynamic> metadata;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.metadata = const {},
  });
}

/// Example 3: Simple Model (No Additional Properties)
/// Shows traditional fixed schema for comparison
@AckModel(
  description: 'Simple model without additional properties',
)
class SimpleItem {
  final String id;
  final String name;
  final bool active;

  SimpleItem({
    required this.id,
    required this.name,
    this.active = true,
  });
}

/// Demo function to test the examples
void main() {
  print('🚀 ACK Additional Properties Examples\n');

  // Example 1: User with preferences
  final userData = {
    'id': 'user_123',
    'name': 'John Doe',
    'email': 'john@example.com',
    // Additional properties stored in 'preferences'
    'theme': 'dark',
    'language': 'en',
    'notifications': true,
  };

  try {
    final user = UserSchema().parse(userData);
    print('✅ User: ${user.name} (${user.email})');
    print('   Theme: ${user.preferences['theme']}');
    print('   Language: ${user.preferences['language']}');
    print('   Notifications: ${user.preferences['notifications']}\n');
  } catch (e) {
    print('❌ User error: $e\n');
  }

  // Example 2: Product with metadata
  final productData = {
    'id': 'prod_456',
    'name': 'Wireless Headphones',
    'price': 199.99,
    // Additional properties stored in 'metadata'
    'brand': 'TechCorp',
    'color': 'Black',
    'warranty': '2 years',
    'rating': 4.8,
  };

  try {
    final product = ProductSchema().parse(productData);
    print('✅ Product: ${product.name} (\$${product.price})');
    print('   Brand: ${product.metadata['brand']}');
    print('   Color: ${product.metadata['color']}');
    print('   Rating: ${product.metadata['rating']}\n');
  } catch (e) {
    print('❌ Product error: $e\n');
  }

  // Example 3: Simple model (extra fields ignored)
  final simpleData = {
    'id': 'item_789',
    'name': 'Basic Widget',
    'active': true,
    // These extra fields will be ignored
    'extra_field': 'ignored',
    'custom_data': {'some': 'data'},
  };

  try {
    final item = SimpleItemSchema().parse(simpleData);
    print('✅ Simple Item: ${item.name} (active: ${item.active})');
    print('   Note: Extra fields are ignored in simple models\n');
  } catch (e) {
    print('❌ Simple item error: $e\n');
  }

  print('🎉 All examples completed!');
  print('💡 Key takeaway: Additional properties provide flexibility');
  print('   while maintaining type safety for core fields.');
}
