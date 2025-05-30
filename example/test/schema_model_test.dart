import 'package:ack/ack.dart';
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
      final schema = ProductSchema(validData);

      // Check that validation was performed
      expect(schema.isValid, isTrue);
      expect(schema.getErrors(), isNull);

      // Access properties
      expect(schema.id, equals('product-1'));
      expect(schema.name, equals('Test Product'));
      expect(schema.price, equals(19.99));

      // Convert to model
      final product = schema.toModel();
      expect(product.id, equals('product-1'));
      expect(product.name, equals('Test Product'));
    });

    test('stores validation errors for invalid data', () {
      // Invalid data (missing required fields)
      final invalidData = {
        'id': 'product-1',
        // Missing name
        // Missing description
        'price': 'not-a-number', // Wrong type
      };

      // Create schema with invalid data
      final schema = ProductSchema(invalidData);

      // Check that validation was performed
      expect(schema.isValid, isFalse);
      expect(schema.getErrors(), isNotNull);

      // Trying to convert to model should throw
      expect(() => schema.toModel(), throwsA(isA<AckException>()));
    });

    test('handles non-map input', () {
      // Non-map input
      final nonMapInput = 'not-a-map';

      // Create schema with non-map input
      final schema = ProductSchema(nonMapInput);

      // Check that validation was performed
      expect(schema.isValid, isFalse);
      expect(schema.getErrors(), isNotNull);
    });

    test('handles null input', () {
      // Null input
      final schema = ProductSchema(null);

      // Check that validation was performed
      expect(schema.isValid, isFalse);
      expect(schema.getErrors(), isNotNull);
    });
  });
}
