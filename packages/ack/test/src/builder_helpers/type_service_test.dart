import 'package:ack/src/builder_helpers/type_service.dart';
import 'package:test/test.dart';

/// Schema class for testing
class TestModelSchema {}

/// Another schema for testing
class AnotherModelSchema {}

/// A class that ends with Schema but isn't registered
class UnregisteredSchema {}

/// A class used for testing non-schema types
class RegularClass {}

/// Custom class for testing list element types
class CustomElement {}

void main() {
  group('TypeService Tests', () {
    group('Schema Type Registration', () {
      test('registerSchemaType adds schema to registry', () {
        // Register a schema type
        TypeService.registerSchemaType<TestModelSchema>();

        // Verify it's recognized as a schema type
        expect(TypeService.isSchemaType(TestModelSchema), isTrue);
      });

      test('registerSchemaType can register multiple schemas', () {
        // Register multiple schemas
        TypeService.registerSchemaType<TestModelSchema>();
        TypeService.registerSchemaType<AnotherModelSchema>();

        // Verify both are recognized
        expect(TypeService.isSchemaType(TestModelSchema), isTrue);
        expect(TypeService.isSchemaType(AnotherModelSchema), isTrue);
      });
    });

    group('Schema Type Detection', () {
      setUp(() {
        // Register test schemas
        TypeService.registerSchemaType<TestModelSchema>();
      });

      test('isSchemaType returns true for registered schema type', () {
        expect(TypeService.isSchemaType(TestModelSchema), isTrue);
      });

      test('isSchemaType returns true for types ending with Schema', () {
        // Even without registration, types ending with "Schema" are considered schemas
        expect(TypeService.isSchemaType(UnregisteredSchema), isTrue);
      });

      test('isSchemaType returns false for non-schema types', () {
        expect(TypeService.isSchemaType(String), isFalse);
        expect(TypeService.isSchemaType(int), isFalse);
        expect(TypeService.isSchemaType(double), isFalse);
        expect(TypeService.isSchemaType(bool), isFalse);
        expect(TypeService.isSchemaType(List), isFalse);
        expect(TypeService.isSchemaType(Map), isFalse);
        expect(TypeService.isSchemaType(RegularClass), isFalse);
      });
    });

    group('Integration Tests', () {
      test('Schema registration and detection flow', () {
        // Register a schema type
        TypeService.registerSchemaType<TestModelSchema>();

        // Verify it's detected as a schema
        expect(TypeService.isSchemaType(TestModelSchema), isTrue);

        // Non-schema types should not be detected
        expect(TypeService.isSchemaType(String), isFalse);
        expect(TypeService.isSchemaType(RegularClass), isFalse);
      });

      test('Combined type checking scenarios', () {
        // Register multiple schemas
        TypeService.registerSchemaType<TestModelSchema>();
        TypeService.registerSchemaType<AnotherModelSchema>();

        // Test schema detection
        expect(TypeService.isSchemaType(TestModelSchema), isTrue);
        expect(TypeService.isSchemaType(AnotherModelSchema), isTrue);
        expect(TypeService.isSchemaType(UnregisteredSchema),
            isTrue); // Ends with Schema
        expect(TypeService.isSchemaType(RegularClass), isFalse);

        // Test primitive types are not schemas
        expect(TypeService.isSchemaType(String), isFalse);
        expect(TypeService.isSchemaType(int), isFalse);
        expect(TypeService.isSchemaType(List), isFalse);
        expect(TypeService.isSchemaType(Map), isFalse);
      });
    });
  });
}
