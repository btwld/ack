import 'package:ack/ack.dart';
import 'package:ack/src/builder_helpers/type_service.dart';
import 'package:test/test.dart';

/// Test model class for testing SchemaRegistry
class TestModel {
  final String name;
  final int value;

  TestModel({required this.name, required this.value});
}

/// Test schema class for TestModel
class TestSchema extends SchemaModel<TestSchema> {
  const TestSchema() : super();
  const TestSchema._valid(Map<String, Object?> data) : super.valid(data);
  TestSchema._invalid(SchemaError error) : super.invalid(error);

  @override
  ObjectSchema get definition {
    return Ack.object({
      'name': Ack.string,
      'value': Ack.int,
    }, required: [
      'name',
      'value'
    ]);
  }

  @override
  TestSchema parse(Object? data) {
    final result = definition.validate(data);
    if (result.isOk) {
      final validatedData = Map<String, Object?>.from(
        result.getOrThrow(),
      );
      return TestSchema._valid(validatedData);
    }
    throw AckException(result.getError());
  }

  String get name => getValue<String>('name')!;
  int get value => getValue<int>('value')!;
}

/// Another test model for testing multiple registrations
class AnotherModel {
  final String title;
  final double amount;

  AnotherModel({required this.title, required this.amount});
}

/// Test schema class for AnotherModel
class AnotherSchema extends SchemaModel<AnotherSchema> {
  const AnotherSchema() : super();
  const AnotherSchema._valid(Map<String, Object?> data) : super.valid(data);

  @override
  ObjectSchema get definition {
    return Ack.object({
      'title': Ack.string,
      'amount': Ack.double,
    }, required: [
      'title',
      'amount'
    ]);
  }

  @override
  AnotherSchema parse(Object? data) {
    final result = definition.validate(data);
    if (result.isOk) {
      final validatedData = Map<String, Object?>.from(
        result.getOrThrow(),
      );
      return AnotherSchema._valid(validatedData);
    }
    throw AckException(result.getError());
  }

  String get title => getValue<String>('title')!;
  double get amount => getValue<double>('amount')!;
}

/// Unregistered schema class for testing
class UnregisteredSchema extends SchemaModel<UnregisteredSchema> {
  const UnregisteredSchema() : super();
  const UnregisteredSchema._valid(Map<String, Object?> data)
      : super.valid(data);

  @override
  ObjectSchema get definition => Ack.object({});

  @override
  UnregisteredSchema parse(Object? data) {
    final result = definition.validate(data);
    if (result.isOk) {
      final validatedData = Map<String, Object?>.from(
        result.getOrThrow(),
      );
      return UnregisteredSchema._valid(validatedData);
    }
    throw AckException(result.getError());
  }
}

/// Unregistered model class for testing
class UnregisteredModel {}

/// Helper function to reset all registrations between tests
void resetRegistrations() {
  // We can't directly clear the static maps, so we'll need to create a test-specific
  // workaround if we need to reset the registry between tests.
  // For now, we'll design tests to be independent of each other.
}

void main() {
  group('SchemaRegistry Tests', () {
    group('Registration', () {
      test('register adds factory to registry', () {
        // Register a schema factory
        SchemaRegistry.register<TestSchema>(
            (data) => const TestSchema().parse(data));

        // Check if it's registered
        expect(SchemaRegistry.isRegistered<TestSchema>(), isTrue);
      });

      test('register can handle multiple schema types', () {
        // Register multiple schema factories
        SchemaRegistry.register<TestSchema>(
            (data) => const TestSchema().parse(data));
        SchemaRegistry.register<AnotherSchema>(
            (data) => const AnotherSchema().parse(data));

        // Verify both are registered
        expect(SchemaRegistry.isRegistered<TestSchema>(), isTrue);
        expect(SchemaRegistry.isRegistered<AnotherSchema>(), isTrue);
      });

      test('register updates TypeService for schema types', () {
        // Register a schema factory
        SchemaRegistry.register<TestSchema>(
            (data) => const TestSchema().parse(data));

        // Check TypeService knows about the schema type
        expect(TypeService.isSchemaType(TestSchema), isTrue);
      });

      test('isRegistered returns false for unregistered types', () {
        // Check unregistered schema is not registered
        expect(SchemaRegistry.isRegistered<UnregisteredSchema>(), isFalse);
      });

      test('register overwrites existing factory for same schema type', () {
        // First factory - creates a regular TestSchema
        SchemaRegistry.register<TestSchema>(
            (data) => const TestSchema().parse(data));

        // Create initial schema to verify first factory works
        var data = {'name': 'Test1', 'value': 1};
        var schema = SchemaRegistry.createSchema<TestSchema>(data);
        expect(schema?.name, equals('Test1'));

        // Second factory - creates schema but modifies data first
        SchemaRegistry.register<TestSchema>((data) {
          // Modify the data before creating schema
          if (data is Map<String, dynamic>) {
            data = Map<String, dynamic>.from(data);
            data['name'] = 'Modified';
          }
          return const TestSchema().parse(data);
        });

        // Create schema with second factory
        data = {'name': 'Test2', 'value': 2};
        schema = SchemaRegistry.createSchema<TestSchema>(data);

        // Should use the second factory which modifies the name
        expect(schema?.name, equals('Modified'));
      });
    });

    group('Schema Creation', () {
      setUp(() {
        // Register test schemas before each test
        SchemaRegistry.register<TestSchema>(
            (data) => const TestSchema().parse(data));
        SchemaRegistry.register<AnotherSchema>(
            (data) => const AnotherSchema().parse(data));
      });

      test('createSchema returns correct schema for registered schema type',
          () {
        // Test data
        final data = {'name': 'Test', 'value': 42};

        // Create schema
        final schema = SchemaRegistry.createSchema<TestSchema>(data);

        // Verify schema creation
        expect(schema, isA<TestSchema>());
        expect(schema!.testData['name'], equals('Test'));
        expect(schema.testData['value'], equals(42));

        // Verify property access
        expect(schema.name, equals('Test'));
        expect(schema.value, equals(42));
      });

      test('createSchema returns correct schema for different schema types',
          () {
        // Test data for TestSchema
        final testData = {'name': 'Test', 'value': 42};

        // Test data for AnotherSchema
        final anotherData = {'title': 'Another', 'amount': 99.99};

        // Create schemas
        final testSchema = SchemaRegistry.createSchema<TestSchema>(testData);
        final anotherSchema =
            SchemaRegistry.createSchema<AnotherSchema>(anotherData);

        // Verify first schema
        expect(testSchema, isA<TestSchema>());
        expect(testSchema!.name, equals('Test'));

        // Verify second schema
        expect(anotherSchema, isA<AnotherSchema>());
        expect(anotherSchema!.title, equals('Another'));
      });

      test('createSchema returns null for unregistered schema type', () {
        // Test data
        final data = {'property': 'value'};

        // Try to create schema
        final schema = SchemaRegistry.createSchema<UnregisteredSchema>(data);

        // Should return null for unregistered type
        expect(schema, isNull);
      });

      test('createSchema handles empty data properly', () {
        // Register schema with error handling for this test
        SchemaRegistry.register<TestSchema>((data) {
          try {
            return const TestSchema().parse(data);
          } catch (e) {
            // Return an invalid schema instance for testing
            if (e is AckException) {
              return TestSchema._invalid(e.error);
            } else {
              // Create a mock error for non-AckException cases
              return TestSchema._invalid(SchemaMockError());
            }
          }
        });

        // Empty data map
        final emptyData = <String, dynamic>{};

        // Create schema with empty data
        final schema = SchemaRegistry.createSchema<TestSchema>(emptyData);

        // Schema should be created but invalid
        expect(schema, isNotNull);
        expect(schema!.isValid, isFalse);
      });

      test('createSchema handles null fields properly', () {
        // Register schema with error handling for this test
        SchemaRegistry.register<TestSchema>((data) {
          try {
            return const TestSchema().parse(data);
          } catch (e) {
            if (e is AckException) {
              return TestSchema._invalid(e.error);
            } else {
              return TestSchema._invalid(SchemaMockError());
            }
          }
        });

        // Data with null fields
        final dataWithNulls = {'name': null, 'value': null};

        // Create schema
        final schema = SchemaRegistry.createSchema<TestSchema>(dataWithNulls);

        // Schema should be created
        expect(schema, isNotNull);

        // Schema should be invalid
        expect(schema!.isValid, isFalse);

        // Accessing null fields through testData should not throw
        expect(schema.testData['name'], isNull);
        expect(schema.testData['value'], isNull);

        // Validation errors should be available
        expect(schema.getErrors(), isNotNull);
      });
    });

    group('Integration with TypeService', () {
      setUp(() {
        // Register test schemas before each test
        SchemaRegistry.register<TestSchema>(
            (data) => const TestSchema().parse(data));
      });

      test('SchemaRegistry and TypeService work together', () {
        // Check type mappings
        expect(TypeService.isSchemaType(TestSchema), isTrue);

        // Create schema
        final data = {'name': 'Test', 'value': 42};
        final schema = SchemaRegistry.createSchema<TestSchema>(data);

        // Schema should be created correctly
        expect(schema, isA<TestSchema>());
      });
    });

    group('Error Cases', () {
      test('createSchema handles invalid data gracefully', () {
        // Register schema with error handling
        SchemaRegistry.register<TestSchema>((data) {
          try {
            return const TestSchema().parse(data);
          } catch (e) {
            if (e is AckException) {
              return TestSchema._invalid(e.error);
            } else {
              return TestSchema._invalid(SchemaMockError());
            }
          }
        });

        // Create invalid data (wrong types)
        final invalidData = {'name': 123, 'value': 'not an int'};

        // Create schema with invalid data
        final schema = SchemaRegistry.createSchema<TestSchema>(invalidData);

        // Schema should be created
        expect(schema, isNotNull);

        // But should be invalid due to type errors
        expect(schema!.isValid, isFalse);
      });
    });
  });
}
