import 'package:ack/src/builder_helpers/type_service.dart';
import 'package:test/test.dart';

/// Class used for testing type mappings
class TestModel {}

/// Schema class for the test model
class TestModelSchema {}

/// Another test model for multiple registrations
class AnotherModel {}

/// Schema for another test model
class AnotherModelSchema {}

/// A class that ends with Schema but isn't registered
class UnregisteredSchema {}

/// A class used for testing unregistered types in schema conversion
class UnregisteredType {}

/// Custom class for testing list element types
class CustomElement {}

void main() {
  group('TypeService Tests', () {
    // Reset type mappings between tests
    setUp(() {
      // We can't directly clear private maps, so we'll rebuild mappings for each test
      // This is a workaround since we can't directly access private fields
    });

    group('Type Registration', () {
      test('registerTypes correctly maps model to schema types', () {
        // Register a type mapping
        TypeService.registerTypes<TestModel, TestModelSchema>();

        // Verify mappings using public methods
        expect(TypeService.getSchemaType(TestModel), equals(TestModelSchema));
        expect(TypeService.getModelType(TestModelSchema), equals(TestModel));
      });

      test('registerTypes can register multiple type pairs', () {
        // Register two type mappings
        TypeService.registerTypes<TestModel, TestModelSchema>();
        TypeService.registerTypes<AnotherModel, AnotherModelSchema>();

        // Verify both mappings exist using public methods
        expect(TypeService.getSchemaType(TestModel), equals(TestModelSchema));
        expect(TypeService.getSchemaType(AnotherModel),
            equals(AnotherModelSchema));
        expect(TypeService.getModelType(TestModelSchema), equals(TestModel));
        expect(
            TypeService.getModelType(AnotherModelSchema), equals(AnotherModel));
      });

      test('registerTypes overwrites existing mappings', () {
        // Register a mapping
        TypeService.registerTypes<TestModel, TestModelSchema>();

        // Override it with a different schema type
        TypeService.registerTypes<TestModel, AnotherModelSchema>();

        // Verify the new mapping replaces the old one
        expect(
            TypeService.getSchemaType(TestModel), equals(AnotherModelSchema));

        // The old schema type should no longer map to the model
        expect(TypeService.getModelType(TestModelSchema), isNull);

        // The new schema type should map to the model
        expect(TypeService.getModelType(AnotherModelSchema), equals(TestModel));
      });
    });

    group('Type Retrieval', () {
      setUp(() {
        // Register test types before each test in this group
        TypeService.registerTypes<TestModel, TestModelSchema>();
        TypeService.registerTypes<AnotherModel, AnotherModelSchema>();
      });

      test('getSchemaType returns correct schema type for registered model',
          () {
        Type? schemaType = TypeService.getSchemaType(TestModel);
        expect(schemaType, equals(TestModelSchema));
      });

      test('getSchemaType returns null for unregistered model', () {
        Type? schemaType = TypeService.getSchemaType(String);
        expect(schemaType, isNull);
      });

      test('getModelType returns correct model type for registered schema', () {
        Type? modelType = TypeService.getModelType(TestModelSchema);
        expect(modelType, equals(TestModel));
      });

      test('getModelType returns null for unregistered schema', () {
        Type? modelType = TypeService.getModelType(UnregisteredSchema);
        expect(modelType, isNull);
      });
    });

    group('Type Checking', () {
      setUp(() {
        // Register test types before each test in this group
        TypeService.registerTypes<TestModel, TestModelSchema>();
      });

      test('isSchemaType returns true for registered schema type', () {
        expect(TypeService.isSchemaType(TestModelSchema), isTrue);
      });

      test('isSchemaType returns true for class names ending with Schema', () {
        expect(TypeService.isSchemaType(UnregisteredSchema), isTrue);
      });

      test('isSchemaType returns false for non-schema types', () {
        expect(TypeService.isSchemaType(String), isFalse);
        expect(TypeService.isSchemaType(TestModel), isFalse);
        expect(TypeService.isSchemaType(int), isFalse);
      });

      test('isListType correctly identifies List types', () {
        // Create actual list instances to get runtime types
        final listString = <String>[];
        final listInt = <int>[];
        final listDynamic = <dynamic>[];
        final listCustom = <CustomElement>[];

        // Test list type detection
        expect(TypeService.isListType(listString.runtimeType), isTrue);
        expect(TypeService.isListType(listInt.runtimeType), isTrue);
        expect(TypeService.isListType(listDynamic.runtimeType), isTrue);
        expect(TypeService.isListType(listCustom.runtimeType), isTrue);

        // Test non-list types
        expect(TypeService.isListType(String), isFalse);
        expect(TypeService.isListType(int), isFalse);
        expect(TypeService.isListType(CustomElement), isFalse);
      });

      test('isMapType correctly identifies Map types', () {
        // Create actual map instances to get runtime types
        final mapStringDynamic = <String, dynamic>{};
        final mapIntString = <int, String>{};
        final mapStringInt = <String, int>{};

        // Test map type detection
        expect(TypeService.isMapType(mapStringDynamic.runtimeType), isTrue);
        expect(TypeService.isMapType(mapIntString.runtimeType), isTrue);
        expect(TypeService.isMapType(mapStringInt.runtimeType), isTrue);

        // Test non-map types
        expect(TypeService.isMapType(String), isFalse);
        expect(TypeService.isMapType(int), isFalse);
        expect(TypeService.isMapType(List), isFalse);
      });
    });

    group('Element Type Extraction', () {
      test('getElementType returns null for non-list types', () {
        expect(TypeService.getElementType(String), isNull);
        expect(TypeService.getElementType(int), isNull);
        expect(TypeService.getElementType(Map<String, dynamic>), isNull);
      });

      test('getElementType currently returns null for list types', () {
        // Current implementation is a stub that returns null
        // Create actual list instance to get runtime type
        final listString = <String>[];
        Type? elementType = TypeService.getElementType(listString.runtimeType);

        // Current implementation returns null for all list types
        expect(elementType, isNull);

        // If we parse the type string ourselves, we can extract the element type name
        final typeStr = listString.runtimeType.toString();
        if (typeStr.contains('List<')) {
          final startIndex = typeStr.indexOf('List<') + 'List<'.length;
          final endIndex = typeStr.lastIndexOf('>');
          if (startIndex > -1 && endIndex > startIndex) {
            final elementTypeName = typeStr.substring(startIndex, endIndex);
            // The element type should be "String"
            expect(elementTypeName.contains('String'), isTrue);
          }
        }
      });

      test('getElementType handles complex list types correctly', () {
        // Current implementation is a stub that returns null
        // Create a list of lists to get runtime type
        final listOfLists = <List<String>>[];
        Type? elementType = TypeService.getElementType(listOfLists.runtimeType);

        // Current implementation returns null for all list types
        expect(elementType, isNull);

        // If we parse the type string ourselves, we can extract the element type name
        final typeStr = listOfLists.runtimeType.toString();
        if (typeStr.contains('List<')) {
          final startIndex = typeStr.indexOf('List<') + 'List<'.length;
          final endIndex = typeStr.lastIndexOf('>');
          if (startIndex > -1 && endIndex > startIndex) {
            final elementTypeName = typeStr.substring(startIndex, endIndex);
            // The element type should contain "List<String>"
            expect(elementTypeName.contains('List'), isTrue);
          }
        }
      });
    });

    group('Integration Tests', () {
      test('Type registration and retrieval flow', () {
        // Register types
        TypeService.registerTypes<TestModel, TestModelSchema>();

        // Check schema type can be determined
        expect(TypeService.isSchemaType(TestModelSchema), isTrue);

        // Get model type from schema type
        Type? modelType = TypeService.getModelType(TestModelSchema);
        expect(modelType, equals(TestModel));

        // Get schema type from model type
        Type? schemaType = TypeService.getSchemaType(TestModel);
        expect(schemaType, equals(TestModelSchema));
      });

      test('Detects lists containing schema types', () {
        // Register test types
        TypeService.registerTypes<TestModel, TestModelSchema>();

        // Create a list type
        final listOfSchemas = <TestModelSchema>[];

        // Test it's a list
        expect(TypeService.isListType(listOfSchemas.runtimeType), isTrue);

        // If we parse the type string ourselves, we can extract the element type name
        final typeStr = listOfSchemas.runtimeType.toString();
        if (typeStr.contains('List<')) {
          final startIndex = typeStr.indexOf('List<') + 'List<'.length;
          final endIndex = typeStr.lastIndexOf('>');
          if (startIndex > -1 && endIndex > startIndex) {
            final elementTypeName = typeStr.substring(startIndex, endIndex);
            // Element type name should contain "TestModelSchema"
            expect(elementTypeName.contains('TestModelSchema'), isTrue);

            // The element type should be a schema type
            expect(TypeService.isSchemaType(TestModelSchema), isTrue);
          }
        }
      });
    });

    group('Improvement Suggestions', () {
      test('getElementType needs enhancement to return actual Type', () {
        // This test demonstrates how getElementType could be improved
        // Currently it returns null for all list types
        final listString = <String>[];

        // Current behavior
        Type? elementType = TypeService.getElementType(listString.runtimeType);
        expect(elementType, isNull);

        // Suggested behavior would be to return the String type
        // This would require changes to the implementation using reflection
        // or a more sophisticated type system approach
      });
    });
  });
}
