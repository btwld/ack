import 'package:ack/ack.dart';
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

      final schema = ProductSchema().parse(validData);

      // No exception means schema is valid with correct data

      // Test all field values
      expect(schema.id, equals('prod123'));
      expect(schema.name, equals('Valid Product Name'));
      expect(schema.description, equals('A valid product description'));
      expect(schema.price, equals(99.99));
      expect(schema.contactEmail, equals('test@example.com'));
      expect(schema.imageUrl, equals('https://example.com/image.jpg'));
      expect(schema.releaseDate, equals('2024-01-15'));
      expect(schema.createdAt, equals('2024-01-15T10:30:00Z'));
      expect(schema.updatedAt, equals('2024-01-16T11:45:00Z'));
      expect(schema.stockQuantity, equals(50));
      expect(schema.status, equals('published'));
      expect(schema.productCode, equals('ABC-1234'));

      // Test direct property access (new architecture)
      expect(schema.id, equals('prod123'));
      expect(schema.name, equals('Valid Product Name'));
      expect(schema.contactEmail, equals('test@example.com'));
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

      expect(() => ProductSchema().parse(invalidData),
          throwsA(isA<AckException>()));
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

      expect(() => ProductSchema().parse(invalidData),
          throwsA(isA<AckException>()));
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

      expect(() => ProductSchema().parse(invalidData),
          throwsA(isA<AckException>()));
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

      expect(() => ProductSchema().parse(invalidData),
          throwsA(isA<AckException>()));
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

      expect(() => ProductSchema().parse(invalidData),
          throwsA(isA<AckException>()));
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

      expect(() => ProductSchema().parse(invalidData),
          throwsA(isA<AckException>()));
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

      expect(() => ProductSchema().parse(invalidData),
          throwsA(isA<AckException>()));
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

      expect(() => ProductSchema().parse(invalidData),
          throwsA(isA<AckException>()));
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

      final schema = ProductSchema().parse(dataWithNulls);
      // No exception means schema is valid
      expect(schema.contactEmail, isNull);
      expect(schema.imageUrl, isNull);
      expect(schema.updatedAt, isNull);
    });
  });
}
