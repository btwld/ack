import 'package:ack/ack.dart';
import 'package:ack_example/product_model.dart';
import 'package:test/test.dart';

// No type helper needed for function-based approach

void main() {
  group('ProductSchema', () {
    test('should validate schema data', () {
      final productData = {
        'id': '123',
        'name': 'Test Product',
        'description': 'A test product',
        'price': 19.99,
        'contactEmail': 'test@example.com',
        'category': {'id': 'cat1', 'name': 'Test Category'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 100,
        'status': 'published',
        'productCode': 'ABC-1234',
      };

      // Parse with the schema variable
      final result = productSchema.parse(productData) as Map<String, dynamic>;

      // Verify data was parsed correctly
      expect(result['id'], equals('123'));
      expect(result['name'], equals('Test Product'));
      expect(result['description'], equals('A test product'));
      expect(result['price'], equals(19.99));
      expect(result['imageUrl'], isNull);

      // Access nested category data
      expect(
        (result['category'] as Map<String, dynamic>)['id'],
        equals('cat1'),
      );
      expect(
        (result['category'] as Map<String, dynamic>)['name'],
        equals('Test Category'),
      );

      // Verify other fields
      expect(result['id'], equals('123'));
      expect(result['name'], equals('Test Product'));
      expect(result['description'], equals('A test product'));
      expect(result['price'], equals(19.99));
      expect(result['contactEmail'], equals('test@example.com'));
      expect(result['releaseDate'], equals('2024-01-15'));
      expect(result['createdAt'], equals('2024-01-15T10:30:00Z'));
      expect(result['stockQuantity'], equals(100));
      expect(result['status'], equals('published'));
      expect(result['productCode'], equals('ABC-1234'));
      expect(
        (result['category'] as Map<String, dynamic>)['id'],
        equals('cat1'),
      );
      expect(
        (result['category'] as Map<String, dynamic>)['name'],
        equals('Test Category'),
      );
    });

    test('should reject invalid product data', () {
      final invalidData = {
        'id': '', // Empty string (fails isNotEmpty)
        'price': 'not a number', // Wrong type
      };

      // Parse with invalid data should throw exception
      expect(() => productSchema.parse(invalidData), throwsException);
    });

    test('Schema should validate and transform data', () {
      final productData = {
        'id': '456',
        'name': 'Test Transform',
        'description': 'Testing validation',
        'price': 29.99,
        'category': {'id': 'cat2', 'name': 'Transform Category'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 25,
        'status': 'published',
        'productCode': 'TRN-4567',
      };

      // Parse with the schema variable
      final result = productSchema.parse(productData) as Map<String, dynamic>;

      // Check if result is valid map
      expect(result, isA<Map<String, dynamic>>());
      expect(result['id'], equals('456'));
      expect(result['name'], equals('Test Transform'));
      expect(result['description'], equals('Testing validation'));
      expect(result['price'], equals(29.99));
      expect(result['imageUrl'], isNull);
      expect(result['category']['id'], equals('cat2'));
      expect(result['category']['name'], equals('Transform Category'));
      expect(result['category'], isA<Map<String, dynamic>>());
    });

    test('Using schema variable directly', () {
      final productData = {
        'id': '456',
        'name': 'Test Transform',
        'description': 'Testing validateAndTransform',
        'price': 29.99,
        'category': {'id': 'cat2', 'name': 'Transform Category'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 15,
        'status': 'draft',
        'productCode': 'DIR-8901',
      };

      print('productSchema function available');
      print('Using variable-based schema approach');

      // Using schema variable
      final result = productSchema.parse(productData) as Map<String, dynamic>;
      print('Schema parsed successfully: ${result['id']}');

      // No registry concept in variable-based approach
      print('\nFunction-based schemas don\'t use registry');
      print('Simply call productSchema to get the schema');

      print('\nTesting if result was parsed correctly:');
      expect(result['id'], equals('456'));
      expect(result['name'], equals('Test Transform'));
    });

    test('Using direct constructor with CategorySchema', () {
      final categoryData = {'id': 'cat3', 'name': 'Test Category'};

      print('categorySchema function available');

      // Using schema variable
      final result = categorySchema.parse(categoryData) as Map<String, dynamic>;
      print('Schema parsed successfully: ${result['id']}');

      // Check if result is valid
      expect(result['id'], equals('cat3'));
      expect(result['name'], equals('Test Category'));
    });

    test('Explore type issues with generic methods', () {
      // First, check the direct type
      print('\nExploring type issues:');

      // Direct type reference
      Type productType = Product;
      print('Direct type reference - Product: $productType');

      // Type from generic parameter within a method
      void genericMethod<T>() {
        Type typeParam = T;
        print('Type parameter inside method - T: $typeParam');
      }

      // Call it with the Product type
      genericMethod<Product>();

      // No type helper needed in function-based approach
      print('Function-based approach doesn\'t use generic type parameters');

      // Check what happens with runtime types using schema
      final testData = {
        'id': '789',
        'name': 'Type Test',
        'description': 'Testing type parameters',
        'price': 99.99,
        'category': {'id': 'cat9', 'name': 'Type Tests'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 10,
        'status': 'draft',
        'productCode': 'TST-1234',
      };
      final testResult = productSchema.parse(testData) as Map<String, dynamic>;
      // Test schema validation and property access (no exception means valid)
      print('Result type: ${testResult.runtimeType}');

      // Variable-based approach doesn't use registry
      print('Variable-based schemas don\'t use Type.toString() or registries');

      // No registry in function-based approach
      print('Variable-based approach: simply use productSchema');

      // Variable-based approach doesn't need generic type handling

      // Variable-based approach doesn't need type parameters
      print('Simply use productSchema function directly');
    });

    test('Using function-based schemas directly', () {
      final productData = {
        'id': '678',
        'name': 'Custom Implementation',
        'description': 'A custom implementation',
        'price': 39.99,
        'category': {'id': 'cat4', 'name': 'Custom Category'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 5,
        'status': 'archived',
        'productCode': 'CUS-2468',
      };

      // With function-based approach, we use the function directly
      final result = productSchema.parse(productData) as Map<String, dynamic>;
      print('Variable-based schema works: ${result['id']}');

      // We can also verify properties
      expect(result['name'], equals('Custom Implementation'));
      expect(result['price'], equals(39.99));

      // No registry needed in variable-based approach
      // Simply use the generated variables

      // We can create a map of schema variables if needed
      Map<String, ObjectSchema> schemaMap = {
        'product': productSchema,
        'category': categorySchema,
      };

      try {
        // Using the schema map
        final schema = schemaMap['product'];
        if (schema != null) {
          final mapResult = schema.parse(productData) as Map<String, dynamic>;
          print('Schema map approach works: ${mapResult['id']}');
          expect(mapResult['id'], equals('678'));
        } else {
          print('Schema map has no entry for product');
        }
      } catch (e) {
        print('Error in schema map: $e');
      }
    });
  });
}
