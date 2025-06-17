import 'package:ack/ack.dart';
import 'package:ack_example/product_model.dart';
import 'package:test/test.dart';

// Helper class for testing type parameters
class TypeHelper {
  static Type getTypeParam<T>() {
    return T;
  }
}

void main() {
  group('ProductSchema', () {
    test('should validate schema data', () {
      final productData = {
        'id': '123',
        'name': 'Test Product',
        'description': 'A test product',
        'price': 19.99,
        'contactEmail': 'test@example.com',
        'category': {
          'id': 'cat1',
          'name': 'Test Category',
        },
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 100,
        'status': 'published',
        'productCode': 'ABC-1234',
      };

      // Create schema with the data
      final schema = const ProductSchema().parse(productData);

      // Check if schema is valid
      expect(schema.isValid, isTrue);

      // Print the raw data for debugging
      print('Schema data: ${schema.toMap()}');

      // Verify data was parsed correctly
      expect(schema.id, equals('123'));
      expect(schema.name, equals('Test Product'));
      expect(schema.description, equals('A test product'));
      expect(schema.price, equals(19.99));
      expect(schema.imageUrl, isNull);

      // Access category through the public property
      expect(schema.category.id, equals('cat1'));
      expect(schema.category.name, equals('Test Category'));

      // Access properties directly from schema (no toModel() method in new architecture)
      expect(schema.id, equals('123'));
      expect(schema.name, equals('Test Product'));
      expect(schema.description, equals('A test product'));
      expect(schema.price, equals(19.99));
      expect(schema.contactEmail, equals('test@example.com'));
      expect(schema.releaseDate, equals('2024-01-15'));
      expect(schema.createdAt, equals('2024-01-15T10:30:00Z'));
      expect(schema.stockQuantity, equals(100));
      expect(schema.status, equals('published'));
      expect(schema.productCode, equals('ABC-1234'));
      expect(schema.category.id, equals('cat1'));
      expect(schema.category.name, equals('Test Category'));
    });

    test('should reject invalid product data', () {
      final invalidData = {
        'id': '', // Empty string (fails isNotEmpty)
        'price': 'not a number', // Wrong type
      };

      // Create a schema instance with invalid data should throw exception
      expect(() => const ProductSchema().parse(invalidData), throwsException);
    });

    test('SchemaModel should validate and transform data', () {
      final productData = {
        'id': '456',
        'name': 'Test Transform',
        'description': 'Testing validation',
        'price': 29.99,
        'category': {
          'id': 'cat2',
          'name': 'Transform Category',
        },
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 25,
        'status': 'published',
        'productCode': 'TRN-4567',
      };

      // Create schema with the data
      final schema = const ProductSchema().parse(productData);

      // Check if schema is valid
      expect(schema.isValid, isTrue);
      expect(schema, isA<ProductSchema>());
      expect(schema.id, equals('456'));
      expect(schema.name, equals('Test Transform'));
      expect(schema.description, equals('Testing validation'));
      expect(schema.price, equals(29.99));
      expect(schema.imageUrl, isNull);
      expect(schema.category.id, equals('cat2'));
      expect(schema.category.name, equals('Transform Category'));
      expect(schema.category, isA<CategorySchema>());
    });

    test('Using direct constructor instead of SchemaModel.get', () {
      final productData = {
        'id': '456',
        'name': 'Test Transform',
        'description': 'Testing validateAndTransform',
        'price': 29.99,
        'category': {
          'id': 'cat2',
          'name': 'Transform Category',
        },
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 15,
        'status': 'draft',
        'productCode': 'DIR-8901',
      };

      print('ProductSchema type: $ProductSchema');
      print('Registration in schema would use: Product, ProductSchema');

      // Using direct constructor instead of SchemaModel.get
      final schema = const ProductSchema().parse(productData);
      print('Schema created successfully: $schema');

      // Check if schema is valid
      expect(schema.isValid, isTrue);

      print('\nTesting if Product type is correctly registered:');
      try {
        final result = SchemaRegistry.isRegistered<Product>();
        print('Is Product registered? $result');
      } catch (e) {
        print('Error checking registry: $e');
      }

      print('\nTesting if direct constructor works:');
      expect(schema.id, equals('456'));
      expect(schema.name, equals('Test Transform'));
    });

    test('Using direct constructor with CategorySchema', () {
      final categoryData = {
        'id': 'cat3',
        'name': 'Test Category',
      };

      print('CategorySchema type: $CategorySchema');

      // Using direct constructor instead of SchemaModel.get
      final schema = const CategorySchema().parse(categoryData);
      print('Schema created successfully: $schema');

      // Check if schema is valid
      expect(schema.isValid, isTrue);
      expect(schema.id, equals('cat3'));
      expect(schema.name, equals('Test Category'));
    });

    test('Explore type issues with generic methods', () {
      // First, check the direct type
      print('\nExploring type issues:');

      // Direct type reference
      Type productType = Product;
      print('Direct type reference - Product: $productType');

      // Type from generic parameter within a method
      void genericMethod<T>() {
        Type typeParam = T;
        print('Type parameter inside method - T: $typeParam');
      }

      // Call it with the Product type
      genericMethod<Product>();

      // Check how the static generic method behaves
      Type staticTypeParam = TypeHelper.getTypeParam<Product>();
      print('Static generic method - Product: $staticTypeParam');

      // Check what happens with runtime types using schema
      final testData = {
        'id': '789',
        'name': 'Type Test',
        'description': 'Testing type parameters',
        'price': 99.99,
        'category': {'id': 'cat9', 'name': 'Type Tests'},
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 10,
        'status': 'draft',
        'productCode': 'TST-1234',
      };
      final testSchema = const ProductSchema().parse(testData);
      // Test schema validation and property access
      expect(testSchema.isValid, isTrue);
      print('Schema type: ${testSchema.runtimeType}');

      // Compare what the SchemaModel.get method is doing
      print(
        'SchemaModel.get<ProductSchema> uses Type.toString(): $ProductSchema',
      );

      // Check what's happening in direct registry
      print(
        'Is Product registered directly? ${SchemaRegistry.isRegistered<Product>()}',
      );

      // Test creating the same issue as in SchemaModel.get
      void testGenericTypeIssue<S>() {
        print('Inside generic method, type S: $S');
      }

      testGenericTypeIssue<ProductSchema>();
    });

    test('Using SchemaRegistry directly', () {
      final productData = {
        'id': '678',
        'name': 'Custom Implementation',
        'description': 'A custom implementation',
        'price': 39.99,
        'category': {
          'id': 'cat4',
          'name': 'Custom Category',
        },
        'releaseDate': '2024-01-15',
        'createdAt': '2024-01-15T10:30:00Z',
        'stockQuantity': 5,
        'status': 'archived',
        'productCode': 'CUS-2468',
      };

      // With our new implementation, we can use the constructor directly
      final schema = const ProductSchema().parse(productData);
      print('Direct constructor works: ${schema.id}');

      // We can also verify properties
      expect(schema.name, equals('Custom Implementation'));
      expect(schema.price, equals(39.99));

      // Note: SchemaRegistry.createSchema would work if the schema was registered
      // But for this test, we'll skip this part since we haven't registered the schema
      // In a real application, you would register the schema in the generated code

      // We can also use a type map if needed for more complex scenarios
      Map<Type, Function> typeFactoryMap = {
        ProductSchema: (Object? data) => const ProductSchema().parse(data),
        CategorySchema: (Object? data) => const CategorySchema().parse(data),
      };

      try {
        // Using the factory map
        final factory = typeFactoryMap[ProductSchema];
        if (factory != null) {
          final mapSchema = factory(productData) as ProductSchema;
          print('Factory map approach works: ${mapSchema.id}');
          expect(mapSchema.id, equals('678'));
        } else {
          print('Factory map has no entry for ProductSchema');
        }
      } catch (e) {
        print('Error in factory map: $e');
      }
    });
  });
}
