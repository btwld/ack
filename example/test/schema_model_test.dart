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

      // Create schema and validate data
      final schema = productSchema;
      final result = schema.validate(validData);

      // Check that validation was successful
      expect(result.isOk, isTrue);

      // Access properties from validated data
      final parsedData = result.getOrThrow()!;
      expect(parsedData['id'], equals('product-1'));
      expect(parsedData['name'], equals('Test Product'));
      expect(parsedData['price'], equals(19.99));
    });

    test('throws exception for invalid data', () {
      // Invalid data (missing required fields)
      final invalidData = {
        'id': 'product-1',
        // Missing name
        // Missing description
        'price': 'not-a-number', // Wrong type
      };

      // Create schema and validate invalid data
      final schema = productSchema;
      final result = schema.validate(invalidData);
      expect(result.isOk, isFalse);
    });

    test('throws exception for non-map input', () {
      // Non-map input
      final nonMapInput = 'not-a-map';

      // Create schema and validate non-map input
      final schema = productSchema;
      final result = schema.validate(nonMapInput);
      expect(result.isOk, isFalse);
    });

    test('throws exception for null input', () {
      // Create schema and validate null input
      final schema = productSchema;
      final result = schema.validate(null);
      expect(result.isOk, isFalse);
    });
  });
}
