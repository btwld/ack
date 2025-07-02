import 'package:test/test.dart';

import '../lib/product_model.g.dart';

void main() {
  group('Comprehensive Constraint Annotations Test', () {
    test('should validate all constraint types successfully', () {
      final validData = {
        'id': 'prod123',
        'name': 'Valid Product Name', // 3-100 chars
        'description': 'A valid product description', // max 500 chars
        'price': 99.99, // min 0.01, max 999999.99
        'contactEmail': 'test@example.com', // valid email
        'imageUrl': 'https://example.com/image.jpg',
        'category': {
          'id': 'cat1',
          'name': 'Electronics',
        },
        'releaseDate': '2024-01-15', // valid date format
        'createdAt': '2024-01-15T10:30:00Z', // valid datetime format
        'updatedAt': '2024-01-16T11:45:00Z', // nullable datetime
        'stockQuantity': 50, // positive integer
        'status': 'published', // enum value
        'productCode': 'ABC-1234', // matches pattern
      };

      final schema = productSchema;
      final result = schema.validate(validData);

      // Check validation was successful
      expect(result.isOk, isTrue);

      // Test all field values from validated data
      final parsedData = result.getOrThrow()!;
      expect(parsedData['id'], equals('prod123'));
      expect(parsedData['name'], equals('Valid Product Name'));
      expect(parsedData['description'], equals('A valid product description'));
      expect(parsedData['price'], equals(99.99));
      expect(parsedData['contactEmail'], equals('test@example.com'));
      expect(parsedData['imageUrl'], equals('https://example.com/image.jpg'));
      expect(parsedData['releaseDate'], equals('2024-01-15'));
      expect(parsedData['createdAt'], equals('2024-01-15T10:30:00Z'));
      expect(parsedData['updatedAt'], equals('2024-01-16T11:45:00Z'));
      expect(parsedData['stockQuantity'], equals(50));
      expect(parsedData['status'], equals('published'));
      expect(parsedData['productCode'], equals('ABC-1234'));
    });

    test('should reject data violating @IsMinLength constraint', () {
      final invalidData = {
        'id': 'prod123',
        'name': 'AB', // Too short (min 3 chars)
        'description': 'A valid description',
        'price': 99.99,
        'category': {'id': 'cat1', 'name': 'Electronics'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 50,
        'status': 'published',
        'productCode': 'ABC-1234',
      };

      final schema = productSchema;
      final result = schema.validate(invalidData);
      expect(result.isOk, isFalse);
    });

    test('should reject data violating @IsEmail constraint', () {
      final invalidData = {
        'id': 'prod123',
        'name': 'Valid Product',
        'description': 'A valid description',
        'price': 99.99,
        'contactEmail': 'invalid-email', // Invalid email format
        'category': {'id': 'cat1', 'name': 'Electronics'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 50,
        'status': 'published',
        'productCode': 'ABC-1234',
      };

      final schema = productSchema;
      final result = schema.validate(invalidData);
      expect(result.isOk, isFalse);
    });

    test('should reject data violating @IsMin/@IsMax constraints', () {
      final invalidData = {
        'id': 'prod123',
        'name': 'Valid Product',
        'description': 'A valid description',
        'price': 0.005, // Below minimum (0.01)
        'category': {'id': 'cat1', 'name': 'Electronics'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 50,
        'status': 'published',
        'productCode': 'ABC-1234',
      };

      final schema = productSchema;
      final result = schema.validate(invalidData);
      expect(result.isOk, isFalse);
    });

    test('should reject data violating @IsPositive constraint', () {
      final invalidData = {
        'id': 'prod123',
        'name': 'Valid Product',
        'description': 'A valid description',
        'price': 99.99,
        'category': {'id': 'cat1', 'name': 'Electronics'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': -5, // Negative number (violates @IsPositive)
        'status': 'published',
        'productCode': 'ABC-1234',
      };

      final schema = productSchema;
      final result = schema.validate(invalidData);
      expect(result.isOk, isFalse);
    });

    test('should reject data violating @IsEnumValues constraint', () {
      final invalidData = {
        'id': 'prod123',
        'name': 'Valid Product',
        'description': 'A valid description',
        'price': 99.99,
        'category': {'id': 'cat1', 'name': 'Electronics'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 50,
        'status':
            'invalid-status', // Not in enum ['draft', 'published', 'archived']
        'productCode': 'ABC-1234',
      };

      final schema = productSchema;
      final result = schema.validate(invalidData);
      expect(result.isOk, isFalse);
    });

    test('should reject data violating @IsPattern constraint', () {
      final invalidData = {
        'id': 'prod123',
        'name': 'Valid Product',
        'description': 'A valid description',
        'price': 99.99,
        'category': {'id': 'cat1', 'name': 'Electronics'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 50,
        'status': 'published',
        'productCode':
            'invalid-code', // Doesn't match pattern ^[A-Z]{2,3}-\d{4}$
      };

      final schema = productSchema;
      final result = schema.validate(invalidData);
      expect(result.isOk, isFalse);
    });

    test('should reject data violating @IsDate constraint', () {
      final invalidData = {
        'id': 'prod123',
        'name': 'Valid Product',
        'description': 'A valid description',
        'price': 99.99,
        'category': {'id': 'cat1', 'name': 'Electronics'},
        'releaseDate': 'invalid-date', // Invalid date format
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 50,
        'status': 'published',
        'productCode': 'ABC-1234',
      };

      final schema = productSchema;
      final result = schema.validate(invalidData);
      expect(result.isOk, isFalse);
    });

    test('should reject data violating @IsDateTime constraint', () {
      final invalidData = {
        'id': 'prod123',
        'name': 'Valid Product',
        'description': 'A valid description',
        'price': 99.99,
        'category': {'id': 'cat1', 'name': 'Electronics'},
        'releaseDate': '2024-01-15',
        'createdAt': 'invalid-datetime', // Invalid datetime format
        'stockQuantity': 50,
        'status': 'published',
        'productCode': 'ABC-1234',
      };

      final schema = productSchema;
      final result = schema.validate(invalidData);
      expect(result.isOk, isFalse);
    });

    test('should handle nullable fields correctly', () {
      final dataWithNulls = {
        'id': 'prod123',
        'name': 'Valid Product',
        'description': 'A valid description',
        'price': 99.99,
        'contactEmail': null, // Nullable field
        'imageUrl': null, // Nullable field
        'category': {'id': 'cat1', 'name': 'Electronics'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'updatedAt': null, // Nullable field
        'stockQuantity': 50,
        'status': 'published',
        'productCode': 'ABC-1234',
      };

      final schema = productSchema;
      final result = schema.validate(dataWithNulls);
      expect(result.isOk, isTrue);

      final parsedData = result.getOrThrow()!;
      expect(parsedData['contactEmail'], isNull);
      expect(parsedData['imageUrl'], isNull);
      expect(parsedData['updatedAt'], isNull);
    });
  });
}
