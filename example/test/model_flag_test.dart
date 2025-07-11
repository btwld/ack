import 'package:ack/ack.dart';
import 'package:ack_example/product_model.dart';
import 'package:test/test.dart';

void main() {
  group('Model Flag Generation Integration', () {
    test('should have generated both schema variable and SchemaModel class', () {
      // Test that productSchema variable exists and is accessible
      expect(productSchema, isNotNull);
      expect(productSchema.toJsonSchema()['type'], equals('object'));
      
      // Test that ProductSchemaModel class exists and is accessible
      final model = ProductSchemaModel();
      expect(model, isNotNull);
      expect(model, isA<SchemaModel<Product>>());
    });

    test('SchemaModel should use the generated schema internally', () {
      final model = ProductSchemaModel();
      
      // The buildSchema method should return the productSchema variable
      // We can't directly test this due to protected access, but we can verify
      // both produce the same JSON schema
      expect(model.toJsonSchema(), equals(productSchema.toJsonSchema()));
    });

    test('should handle data consistently between both approaches', () {
      final testData = {
        'id': 'test-123',
        'name': 'Test Product',
        'description': 'A test product',
        'price': 99.99,
        'category': {
          'id': 'cat-1',
          'name': 'Test Category',
        },
        'releaseDate': '2024-01-01',
        'createdAt': '2024-01-01T00:00:00Z',
        'stockQuantity': 10,
        'status': 'published',
        'productCode': 'ABC-1234',
        'extraField': 'should be in metadata',
      };

      // Test schema variable approach
      final schemaResult = productSchema.parse(testData) as Map<String, dynamic>;
      expect(schemaResult['id'], equals('test-123'));
      expect(schemaResult['name'], equals('Test Product'));
      
      // Test SchemaModel approach
      final model = ProductSchemaModel();
      final modelResult = model.parse(testData);
      expect(modelResult.isOk, isTrue);
      
      final product = model.value!;
      expect(product.id, equals('test-123'));
      expect(product.name, equals('Test Product'));
      expect(product.metadata['extraField'], equals('should be in metadata'));
    });

    test('should validate consistently between approaches', () {
      final invalidData = {
        'id': '', // Too short (minLength: 1)
        'name': 'A', // Too short (minLength: 3)
        'price': -10, // Negative (min: 0.01)
      };

      // Schema variable should throw
      expect(() => productSchema.parse(invalidData), throwsException);
      
      // SchemaModel should return error result
      final model = ProductSchemaModel();
      final result = model.parse(invalidData);
      expect(result.isOk, isFalse);
    });

    test('nested CategorySchemaModel should work correctly', () {
      final categoryModel = CategorySchemaModel();
      
      final categoryData = {
        'id': 'cat-123',
        'name': 'Electronics',
        'description': 'Electronic products',
        'customField': 'extra data',
      };
      
      final result = categoryModel.parse(categoryData);
      expect(result.isOk, isTrue);
      
      final category = categoryModel.value!;
      expect(category.id, equals('cat-123'));
      expect(category.name, equals('Electronics'));
      expect(category.description, equals('Electronic products'));
      expect(category.metadata['customField'], equals('extra data'));
    });

    test('should demonstrate type safety advantage of SchemaModel', () {
      final model = ProductSchemaModel();
      
      model.parse({
        'id': '123',
        'name': 'Type Safe Product',
        'description': 'Demonstrates type safety',
        'price': 49.99,
        'category': {'id': 'cat1', 'name': 'Safety'},
        'releaseDate': '2024-01-01',
        'createdAt': '2024-01-01T00:00:00Z',
        'stockQuantity': 5,
        'status': 'published',
        'productCode': 'TST-0001',
      });
      
      // Direct typed access without casting
      final product = model.value;
      if (product != null) {
        // These all have proper types without any casting
        String id = product.id;
        String name = product.name;
        double price = product.price;
        Category category = product.category;
        int stock = product.stockQuantity;
        
        expect(id, isA<String>());
        expect(name, isA<String>());
        expect(price, isA<double>());
        expect(category, isA<Category>());
        expect(stock, isA<int>());
      }
    });
  });
}