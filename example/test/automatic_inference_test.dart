import 'package:test/test.dart';
import '../lib/product_model.dart';

void main() {
  group('Automatic Inference Tests', () {
    test('should correctly infer required fields from constructor parameters', () {
      // Test data with all required fields
      final validData = {
        'id': 'test123',
        'name': 'Test Product',
        'description': 'Test Description',
        'price': 99.99,
        'category': {'id': 'cat1', 'name': 'Category'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 10,
        'status': 'published',
        'productCode': 'ABC-1234',
      };

      final schema = ProductSchema(validData);
      expect(schema.isValid, isTrue, reason: 'All required fields provided');
    });

    test('should reject data missing required fields (inferred from constructor)', () {
      // Missing 'name' which is required in constructor
      final invalidData = {
        'id': 'test123',
        // 'name': 'Test Product', // Missing required field
        'description': 'Test Description',
        'price': 99.99,
        'category': {'id': 'cat1', 'name': 'Category'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 10,
        'status': 'published',
        'productCode': 'ABC-1234',
      };

      final schema = ProductSchema(invalidData);
      expect(schema.isValid, isFalse, reason: 'Missing required field should fail validation');
    });

    test('should allow optional fields to be null (inferred from constructor)', () {
      // Optional fields (contactEmail, imageUrl, updatedAt) are omitted
      final dataWithOptionalFieldsOmitted = {
        'id': 'test123',
        'name': 'Test Product',
        'description': 'Test Description',
        'price': 99.99,
        'category': {'id': 'cat1', 'name': 'Category'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 10,
        'status': 'published',
        'productCode': 'ABC-1234',
        // contactEmail, imageUrl, updatedAt are optional
      };

      final schema = ProductSchema(dataWithOptionalFieldsOmitted);
      expect(schema.isValid, isTrue, reason: 'Optional fields can be omitted');
      expect(schema.contactEmail, isNull);
      expect(schema.imageUrl, isNull);
      expect(schema.updatedAt, isNull);
    });

    test('should handle nullable fields correctly (inferred from field types)', () {
      final dataWithNulls = {
        'id': 'test123',
        'name': 'Test Product',
        'description': 'Test Description',
        'price': 99.99,
        'contactEmail': null, // String? field
        'imageUrl': null, // String? field
        'category': {'id': 'cat1', 'name': 'Category'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'updatedAt': null, // String? field
        'stockQuantity': 10,
        'status': 'published',
        'productCode': 'ABC-1234',
      };

      final schema = ProductSchema(dataWithNulls);
      expect(schema.isValid, isTrue, reason: 'Nullable fields can be null');
      expect(schema.contactEmail, isNull);
      expect(schema.imageUrl, isNull);
      expect(schema.updatedAt, isNull);
    });

    test('should respect @IsRequired annotation override', () {
      // Category has @IsRequired annotation override (though this is redundant in current example)
      final categoryData = {
        'id': 'cat1',
        'name': 'Test Category',
        // description is optional
      };

      final schema = CategorySchema(categoryData);
      expect(schema.isValid, isTrue);
      expect(schema.description, isNull);
    });

    test('should respect @IsNullable annotation override', () {
      // Category description has @IsNullable annotation
      final categoryData = {
        'id': 'cat1',
        'name': 'Test Category',
        'description': null, // Explicitly null due to @IsNullable
      };

      final schema = CategorySchema(categoryData);
      expect(schema.isValid, isTrue);
      expect(schema.description, isNull);
    });
  });
}
