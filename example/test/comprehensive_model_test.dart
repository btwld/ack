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
        // In schema-only mode (model: false), additional properties stay at top level
        expect(user['theme'], equals('dark'));
        expect(user['language'], equals('en'));
      });

      test('status model with enum validation', () {
        // Valid enum value
        final validData = {'simpleStatus': 'active'};

        final result =
            statusModelSchema.parse(validData) as Map<String, dynamic>;
        expect(result['simpleStatus'], equals('active'));

        // Invalid enum value should throw
        final invalidData = {'simpleStatus': 'invalid_status'};

        expect(() => statusModelSchema.parse(invalidData), throwsException);
      });
    });

    group('Schema validation with nested models', () {
      test('Product schema with nested category', () {
        final data = {
          'id': 'prod_123',
          'name': 'Laptop Pro',
          'description': 'High-performance laptop',
          'price': 1299.99,
          'category': {'id': 'cat_electronics', 'name': 'Electronics'},
          'releaseDate': '2024-01-01',
          'createdAt': '2024-01-01T00:00:00Z',
          'stockQuantity': 25,
          'status': 'published',
          'productCode': 'LAP-2024',
          'warranty': '2 years',
          'manufacturer': 'TechCorp',
        };

        final result = productSchema.parse(data) as Map<String, dynamic>;
        expect(result['id'], equals('prod_123'));
        expect(result['price'], equals(1299.99));
        expect(result['category']['name'], equals('Electronics'));
        expect(result['warranty'], equals('2 years'));
        expect(result['manufacturer'], equals('TechCorp'));
      });

      test('Category schema with additional properties', () {
        final data = {
          'id': 'cat_books',
          'name': 'Books',
          'description': 'All kinds of books',
          'parentCategory': 'media',
          'sortOrder': 1,
        };

        final result = categorySchema.parse(data) as Map<String, dynamic>;
        expect(result['id'], equals('cat_books'));
        expect(result['parentCategory'], equals('media'));
        expect(result['sortOrder'], equals(1));
      });
    });

    group('Schema usage patterns', () {
      test('schema validation with valid data', () {
        final schemaResult = productSchema.parse({
          'id': 'test_1',
          'name': 'Test Product',
          'description': 'Testing schema approach',
          'price': 99.99,
          'category': {'id': 'cat_1', 'name': 'Test'},
          'releaseDate': '2024-01-01',
          'createdAt': '2024-01-01T00:00:00Z',
          'stockQuantity': 10,
          'status': 'draft',
          'productCode': 'TST-0001',
        });

        expect(schemaResult, isA<Map<String, dynamic>>());
        final result = schemaResult as Map<String, dynamic>;
        expect(result['id'], equals('test_1'));
        expect(result['price'], equals(99.99));
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
        final dataWithExtras = _createProductData()
          ..addAll({
            'customField1': 'value1',
            'customField2': 123,
            'customField3': {'nested': 'data'},
          });

        final result =
            productSchema.parse(dataWithExtras) as Map<String, dynamic>;
        expect(result['customField1'], equals('value1'));
        expect(result['customField2'], equals(123));
        expect(result['customField3'], equals({'nested': 'data'}));
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
          'productCode': 'MIN-0001',
        };

        final schemaResult =
            productSchema.parse(minimalData) as Map<String, dynamic>;
        expect(schemaResult['contactEmail'], isNull);
        expect(schemaResult['imageUrl'], isNull);
        expect(schemaResult['updatedAt'], isNull);
      });
    });

    group('AnyOf/Union type examples', () {
      test('manual AnyOf implementation with schema', () {
        // Since we don't have built-in AnyOf support in annotations,
        // demonstrate how it can be done manually
        final flexibleSchema = Ack.object({
          'id': Ack.string(),
          'value': Ack.anyOf([Ack.string(), Ack.double(), Ack.boolean()]),
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
          () => flexibleSchema.parse({
            'id': '4',
            'value': ['array'],
          }),
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
    'category': {'id': 'test_cat', 'name': 'Test Category'},
    'releaseDate': '2024-01-01',
    'createdAt': '2024-01-01T00:00:00Z',
    'stockQuantity': 10,
    'status': status,
    'productCode': 'TST-0001',
  };
}
