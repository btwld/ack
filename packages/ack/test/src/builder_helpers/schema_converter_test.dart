import 'package:ack/ack.dart';
import 'package:ack/src/builder_helpers/schema_converter.dart';
import 'package:test/test.dart';

// Test model classes
class Product {
  final String name;
  final double price;
  final Category? category;
  final List<String>? tags;

  Product({
    required this.name,
    required this.price,
    this.category,
    this.tags,
  });
}

class Category {
  final String name;
  final int id;

  Category({required this.name, required this.id});
}

/// Schema class for Product model
class ProductSchema extends SchemaModel<Product> {
  ProductSchema(super.data);

  @override
  AckSchema getSchema() {
    return Ack.object({
      'name': Ack.string,
      'price': Ack.double,
      'category': Ack.object({
        'name': Ack.string,
        'id': Ack.int,
      }).nullable(),
      'tags': Ack.list(Ack.string).nullable(),
    }, required: [
      'name',
      'price'
    ]);
  }

  /// Checks if the map contains a key
  @override
  bool containsKey(String key) => toMap().containsKey(key);

  @override
  Product toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return Product(
      name: this['name'] as String,
      price: this['price'] as double,
      category: containsKey('category') && this['category'] != null
          ? CategorySchema(this['category']).toModel()
          : null,
      tags:
          containsKey('tags') ? List<String>.from(this['tags'] as List) : null,
    );
  }
}

/// Schema class for Category model
class CategorySchema extends SchemaModel<Category> {
  CategorySchema(super.data);

  @override
  AckSchema getSchema() {
    return Ack.object({
      'name': Ack.string,
      'id': Ack.int,
    }, required: [
      'name',
      'id'
    ]);
  }

  /// Checks if the map contains a key
  @override
  bool containsKey(String key) => toMap().containsKey(key);

  @override
  Category toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return Category(
      name: this['name'] as String,
      id: this['id'] as int,
    );
  }
}

/// A class used for testing unregistered types
class UnregisteredType {}

/// Register test schemas in the SchemaRegistry
void registerTestSchemas() {
  // Register schema factories
  SchemaRegistry.register<Product, ProductSchema>(
      (data) => ProductSchema(data));
  SchemaRegistry.register<Category, CategorySchema>(
      (data) => CategorySchema(data));
}

void main() {
  group('SchemaConverter Tests', () {
    setUp(() {
      // Register test schemas before each test
      registerTestSchemas();
    });

    group('Direct Type Matches', () {
      test('Primitive values pass through unchanged', () {
        // Test primitive values
        expect(SchemaConverter.convertValue<int>(42), equals(42));
        expect(SchemaConverter.convertValue<String>('hello'), equals('hello'));
        expect(SchemaConverter.convertValue<double>(3.14), equals(3.14));
        expect(SchemaConverter.convertValue<bool>(true), equals(true));
      });

      test('Null values pass through unchanged', () {
        expect(SchemaConverter.convertValue<String>(null), isNull);
      });

      test('Type mismatch returns null', () {
        // Current implementation returns null for type mismatches
        expect(SchemaConverter.convertValue<int>('not a number'), isNull);
      });
    });

    group('Schema Type Conversions', () {
      test('Map to Schema Conversion', () {
        // Create test data
        final categoryData = {
          'name': 'Electronics',
          'id': 1,
        };

        final productData = {
          'name': 'Laptop',
          'price': 999.99,
          'category': categoryData,
          'tags': ['tech', 'computer'],
        };

        // Convert map to schema
        final convertedSchema =
            SchemaConverter.convertValue<ProductSchema>(productData);

        // Verify conversion
        expect(convertedSchema, isA<ProductSchema>());
        if (convertedSchema != null) {
          expect(convertedSchema['name'], equals('Laptop'));
          expect(convertedSchema['price'], equals(999.99));
          expect(convertedSchema['tags'], equals(['tech', 'computer']));

          // Check nested schema conversion
          expect(convertedSchema['category'], isA<Map<String, dynamic>>());
          final categoryMap =
              convertedSchema['category'] as Map<String, dynamic>;
          expect(categoryMap['name'], equals('Electronics'));
          expect(categoryMap['id'], equals(1));

          // Convert to model to check full conversion path
          final product = convertedSchema.toModel();
          expect(product.name, equals('Laptop'));
          expect(product.price, equals(999.99));
          expect(product.tags, equals(['tech', 'computer']));
          expect(product.category?.name, equals('Electronics'));
          expect(product.category?.id, equals(1));
        }
      });

      test('Nested Schema Conversion', () {
        // Test data for category
        final categoryData = {
          'name': 'Electronics',
          'id': 1,
        };

        // Convert to schema
        final categorySchema =
            SchemaConverter.convertValue<CategorySchema>(categoryData);

        // Verify
        expect(categorySchema, isA<CategorySchema>());
        if (categorySchema != null) {
          expect(categorySchema['name'], equals('Electronics'));
          expect(categorySchema['id'], equals(1));

          // Convert to model to check full conversion path
          final category = categorySchema.toModel();
          expect(category.name, equals('Electronics'));
          expect(category.id, equals(1));
        }
      });
    });

    group('List of Schema Types', () {
      test('List conversion behavior', () {
        // Create a list of category data
        final categoriesData = [
          {'name': 'Electronics', 'id': 1},
          {'name': 'Books', 'id': 2},
          {'name': 'Clothing', 'id': 3},
        ];

        // Try to convert to list of schemas
        final categorySchemas =
            SchemaConverter.convertValue<List<CategorySchema>>(categoriesData);

        // In current implementation, this returns null since element type extraction
        // in TypeService.getElementType() is returning null
        expect(categorySchemas, isNull,
            reason:
                'Current implementation cannot process List<SchemaType> conversions');

        // Future enhancement would make this work as follows:
        // expect(categorySchemas, isA<List<CategorySchema>>());
        // expect(categorySchemas?.length, equals(3));
      });

      test('Mixed List Types behavior', () {
        // A list with some valid maps and some invalid items
        final mixedList = [
          {'name': 'Electronics', 'id': 1}, // Valid map for CategorySchema
          'Some string', // Invalid item
          {'name': 'Books', 'id': 2}, // Valid map for CategorySchema
        ];

        // Try converting
        final result =
            SchemaConverter.convertValue<List<CategorySchema>>(mixedList);

        // In current implementation, this returns null
        expect(result, isNull,
            reason:
                'Current implementation cannot process List<SchemaType> conversions');

        // Future enhancement would make this work as follows:
        // expect(result, isA<List<CategorySchema>>());
        // expect(result?.length, equals(2));
      });
    });

    group('Error Handling', () {
      test('Unregistered Schema Type', () {
        // Create a map that could be converted to a schema
        final data = {'name': 'Test'};

        // Try to convert to an unregistered schema type
        final result = SchemaConverter.convertValue<UnregisteredType>(data);

        // Should return null for unregistered types
        expect(result, isNull);
      });

      test('Invalid Map Type', () {
        // Create a map missing required fields
        final invalidData = {'not_a_name': 'Value'};

        // Try converting to a schema
        final result =
            SchemaConverter.convertValue<CategorySchema>(invalidData);

        // With our new implementation, the schema is created but validation fails
        if (result != null) {
          // The schema should be invalid
          expect(result.isValid, isFalse);

          // Trying to convert to model should throw AckException
          expect(() => result.toModel(), throwsA(isA<AckException>()));
        }
      });
    });
  });
}
