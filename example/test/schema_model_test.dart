import 'package:ack_example/product_model.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaModel', () {
    test('validates data on construction', () {
      // Valid data
      final validData = {
        'id': 'product-1',
        'name': 'Test Product',
        'description': 'A test product',
        'price': 19.99,
        'category': {
          'id': 'category-1',
          'name': 'Test Category',
        },
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 50,
        'status': 'published',
        'productCode': 'PRD-1111',
      };

      // Create schema with valid data
      final schema = const ProductSchema().parse(validData);

      // Check that validation was performed (no exception thrown)
      expect(schema.isValid, isTrue);

      // Access properties
      expect(schema.id, equals('product-1'));
      expect(schema.name, equals('Test Product'));
      expect(schema.price, equals(19.99));

      // Access properties directly from schema
      expect(schema.id, equals('product-1'));
      expect(schema.name, equals('Test Product'));
    });

    test('throws exception for invalid data', () {
      // Invalid data (missing required fields)
      final invalidData = {
        'id': 'product-1',
        // Missing name
        // Missing description
        'price': 'not-a-number', // Wrong type
      };

      // Create schema with invalid data should throw exception
      expect(() => const ProductSchema().parse(invalidData), throwsException);
    });

    test('throws exception for non-map input', () {
      // Non-map input
      final nonMapInput = 'not-a-map';

      // Create schema with non-map input should throw exception
      expect(() => const ProductSchema().parse(nonMapInput), throwsException);
    });

    test('throws exception for null input', () {
      // Null input should throw exception
      expect(() => const ProductSchema().parse(null), throwsException);
    });
  });
}
