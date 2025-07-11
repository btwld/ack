import 'package:ack/ack.dart';
import 'package:ack_example/product_model.dart';
import 'package:ack_example/simple_examples.dart' as simple;
import 'package:ack_example/status_model.dart';
import 'package:test/test.dart';

void main() {
  group('Comprehensive Model Examples', () {
    group('Schema-only approach (model: false)', () {
      test('simple examples without SchemaModel', () {
        // User schema (model: false)
        final userData = {
          'id': 'user_1',
          'name': 'John Doe',
          'email': 'john@example.com',
          'theme': 'dark',
          'language': 'en',
        };
        
        final user = simple.userSchema.parse(userData) as Map<String, dynamic>;
        expect(user['id'], equals('user_1'));
        expect(user['preferences']['theme'], equals('dark'));
      });

      test('status model with enum validation', () {
        // Valid enum value
        final validData = {
          'simpleStatus': 'active',
        };
        
        final result = statusModelSchema.parse(validData) as Map<String, dynamic>;
        expect(result['simpleStatus'], equals('active'));
        
        // Invalid enum value should throw
        final invalidData = {
          'simpleStatus': 'invalid_status',
        };
        
        expect(() => statusModelSchema.parse(invalidData), throwsException);
      });
    });

    group('SchemaModel approach (model: true)', () {
      test('Product with SchemaModel - type safety', () {
        final model = ProductSchemaModel();
        
        final data = {
          'id': 'prod_123',
          'name': 'Laptop Pro',
          'description': 'High-performance laptop',
          'price': 1299.99,
          'category': {
            'id': 'cat_electronics',
            'name': 'Electronics',
          },
          'releaseDate': '2024-01-01',
          'createdAt': '2024-01-01T00:00:00Z',
          'stockQuantity': 25,
          'status': 'published',
          'productCode': 'LAP-2024',
          'warranty': '2 years',
          'manufacturer': 'TechCorp',
        };
        
        final result = model.parse(data);
        expect(result.isOk, isTrue);
        
        final product = model.value!;
        // Type-safe access
        expect(product.id, equals('prod_123'));
        expect(product.price, equals(1299.99));
        expect(product.category.name, equals('Electronics'));
        expect(product.metadata['warranty'], equals('2 years'));
        expect(product.metadata['manufacturer'], equals('TechCorp'));
      });

      test('Category with SchemaModel - nested usage', () {
        final model = CategorySchemaModel();
        
        final data = {
          'id': 'cat_books',
          'name': 'Books',
          'description': 'All kinds of books',
          'parentCategory': 'media',
          'sortOrder': 1,
        };
        
        final result = model.parse(data);
        expect(result.isOk, isTrue);
        
        final category = model.value!;
        expect(category.id, equals('cat_books'));
        expect(category.metadata['parentCategory'], equals('media'));
        expect(category.metadata['sortOrder'], equals(1));
      });
    });

    group('Mixed usage patterns', () {
      test('can use both approaches in same codebase', () {
        // Schema variable approach for simple validation
        final schemaResult = productSchema.parse({
          'id': 'test_1',
          'name': 'Test Product',
          'description': 'Testing mixed approach',
          'price': 99.99,
          'category': {'id': 'cat_1', 'name': 'Test'},
          'releaseDate': '2024-01-01',
          'createdAt': '2024-01-01T00:00:00Z',
          'stockQuantity': 10,
          'status': 'draft',
          'productCode': 'TST-001',
        });
        
        expect(schemaResult, isA<Map<String, dynamic>>());
        
        // SchemaModel approach for type-safe object creation
        final model = ProductSchemaModel();
        final modelResult = model.parseJson('{"id":"test_2","name":"Another Test","description":"Type safe test","price":149.99,"category":{"id":"cat_2","name":"Test2"},"releaseDate":"2024-01-01","createdAt":"2024-01-01T00:00:00Z","stockQuantity":5,"status":"published","productCode":"TST-002"}');
        
        expect(modelResult.isOk, isTrue);
        expect(model.value, isA<Product>());
      });
    });

    group('Validation edge cases', () {
      test('enum validation with ProductStatus', () {
        final validStatuses = ['draft', 'published', 'archived'];
        
        for (final status in validStatuses) {
          final data = _createProductData(status: status);
          final result = productSchema.parse(data);
          expect(result, isA<Map<String, dynamic>>());
        }
        
        // Invalid status should fail
        expect(
          () => productSchema.parse(_createProductData(status: 'invalid')),
          throwsException,
        );
      });

      test('additional properties handling', () {
        final model = ProductSchemaModel();
        
        final dataWithExtras = _createProductData()
          ..addAll({
            'customField1': 'value1',
            'customField2': 123,
            'customField3': {'nested': 'data'},
          });
        
        final result = model.parse(dataWithExtras);
        expect(result.isOk, isTrue);
        
        final product = model.value!;
        expect(product.metadata['customField1'], equals('value1'));
        expect(product.metadata['customField2'], equals(123));
        expect(product.metadata['customField3'], equals({'nested': 'data'}));
      });

      test('nullable fields handling', () {
        final minimalData = {
          'id': 'min_1',
          'name': 'Minimal Product',
          'description': 'Just required fields',
          'price': 9.99,
          'category': {'id': 'cat_min', 'name': 'Minimal'},
          'releaseDate': '2024-01-01',
          'createdAt': '2024-01-01T00:00:00Z',
          'stockQuantity': 1,
          'status': 'draft',
          'productCode': 'MIN-001',
        };
        
        // Both approaches should handle nullable fields
        final schemaResult = productSchema.parse(minimalData);
        expect(schemaResult!['contactEmail'], isNull);
        expect(schemaResult['imageUrl'], isNull);
        expect(schemaResult['updatedAt'], isNull);
        
        final model = ProductSchemaModel();
        final modelResult = model.parse(minimalData);
        expect(modelResult.isOk, isTrue);
        expect(model.value!.contactEmail, isNull);
        expect(model.value!.imageUrl, isNull);
        expect(model.value!.updatedAt, isNull);
      });
    });

    group('AnyOf/Union type examples', () {
      test('manual AnyOf implementation with schema', () {
        // Since we don't have built-in AnyOf support in annotations,
        // demonstrate how it can be done manually
        final flexibleSchema = Ack.object({
          'id': Ack.string(),
          'value': Ack.anyOf([
            Ack.string(),
            Ack.double(),
            Ack.boolean(),
          ]),
        });
        
        // Test with string value
        final stringResult = flexibleSchema.parse({'id': '1', 'value': 'text'});
        expect(stringResult, isA<Map<String, dynamic>>());
        
        // Test with number value
        final numberResult = flexibleSchema.parse({'id': '2', 'value': 42});
        expect(numberResult, isA<Map<String, dynamic>>());
        
        // Test with boolean value
        final boolResult = flexibleSchema.parse({'id': '3', 'value': true});
        expect(boolResult, isA<Map<String, dynamic>>());
        
        // Test with invalid value
        expect(
          () => flexibleSchema.parse({'id': '4', 'value': ['array']}),
          throwsException,
        );
      });
    });
  });
}

Map<String, dynamic> _createProductData({String status = 'published'}) {
  return {
    'id': 'test_product',
    'name': 'Test Product',
    'description': 'A test product description',
    'price': 99.99,
    'category': {
      'id': 'test_cat',
      'name': 'Test Category',
    },
    'releaseDate': '2024-01-01',
    'createdAt': '2024-01-01T00:00:00Z',
    'stockQuantity': 10,
    'status': status,
    'productCode': 'TEST-001',
  };
}