import 'package:ack/src/builder_helpers/schema_registry.dart';
import 'package:ack/src/builder_helpers/type_service.dart';
import 'package:ack/src/schemas/schema_model.dart';
import 'package:ack/src/validation/schema_error.dart';
import 'package:ack/src/validation/schema_result.dart';
import 'package:test/test.dart';

/// Test model class for testing SchemaRegistry
class TestModel {
  final String name;
  final int value;

  TestModel({required this.name, required this.value});
}

/// Test schema class for TestModel
class TestSchema extends SchemaModel<TestModel> {
  TestSchema(Map<String, dynamic> data) : super(data);

  /// Factory method to create schema from map
  static TestSchema parse(Map<String, dynamic> data) {
    return TestSchema(data);
  }

  @override
  TestModel toModel() {
    return TestModel(
      name: this['name'] as String,
      value: this['value'] as int,
    );
  }

  @override
  void initialize() {
    // TODO: implement initialize
  }

  @override
  SchemaResult validate() {
    if (!toMap().containsKey('name') || !toMap().containsKey('value')) {
      return SchemaResult.fail(SchemaMockError());
    }
    return SchemaResult.ok(this);
  }
}

/// Another test model for testing multiple registrations
class AnotherModel {
  final String title;
  final double amount;

  AnotherModel({required this.title, required this.amount});
}

/// Test schema class for AnotherModel
class AnotherSchema extends SchemaModel<AnotherModel> {
  AnotherSchema(Map<String, dynamic> data) : super(data);

  /// Factory method to create schema from map
  static AnotherSchema parse(Map<String, dynamic> data) {
    return AnotherSchema(data);
  }

  @override
  AnotherModel toModel() {
    return AnotherModel(
      title: this['title'] as String,
      amount: this['amount'] as double,
    );
  }

  @override
  void initialize() {
    // TODO: implement initialize
  }

  @override
  SchemaResult validate() {
    if (!toMap().containsKey('title') || !toMap().containsKey('amount')) {
      return SchemaResult.fail(SchemaMockError());
    }
    return SchemaResult.ok(this);
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
        SchemaRegistry.register<TestModel, TestSchema>(TestSchema.parse);

        // Check if it's registered
        expect(SchemaRegistry.isRegistered<TestModel>(), isTrue);
      });

      test('register can handle multiple schema types', () {
        // Register multiple schema factories
        SchemaRegistry.register<TestModel, TestSchema>(TestSchema.parse);
        SchemaRegistry.register<AnotherModel, AnotherSchema>(
            AnotherSchema.parse);

        // Verify both are registered
        expect(SchemaRegistry.isRegistered<TestModel>(), isTrue);
        expect(SchemaRegistry.isRegistered<AnotherModel>(), isTrue);
      });

      test('register updates TypeService mappings', () {
        // Register a schema factory
        SchemaRegistry.register<TestModel, TestSchema>(TestSchema.parse);

        // Check TypeService mappings were updated
        expect(TypeService.getSchemaType(TestModel), equals(TestSchema));
        expect(TypeService.getModelType(TestSchema), equals(TestModel));
      });

      test('isRegistered returns false for unregistered types', () {
        // Check unregistered model is not registered
        expect(SchemaRegistry.isRegistered<UnregisteredModel>(), isFalse);
      });

      test('register overwrites existing factory for same model type', () {
        // Define a custom factory function that creates a modified schema
        TestSchema customFactory(Map<String, dynamic> data) {
          // Add an extra property to the data
          data['extraProperty'] = 'custom';
          return TestSchema(data);
        }

        // Register standard factory first
        SchemaRegistry.register<TestModel, TestSchema>(TestSchema.parse);

        // Then register custom factory for the same model type
        SchemaRegistry.register<TestModel, TestSchema>(customFactory);

        // Create a schema using the factory
        final data = {'name': 'Test', 'value': 42};
        final schema =
            SchemaRegistry.createSchema(TestModel, data) as TestSchema?;

        // Verify it used the custom factory
        expect(schema, isNotNull);
        expect(schema!['extraProperty'], equals('custom'));
      });

      test('registerWithFactory adds factory to registry using named parameter',
          () {
        // Register a schema factory using the new method
        SchemaRegistry.register<TestModel, TestSchema>(TestSchema.parse);

        // Check if it's registered
        expect(SchemaRegistry.isRegistered<TestModel>(), isTrue);

        // Create a schema to verify it works
        final data = {'name': 'Test', 'value': 42};
        final schema = SchemaRegistry.createSchema(TestModel, data);

        // Verify schema creation
        expect(schema, isA<TestSchema>());
        expect(schema!['name'], equals('Test'));
        expect(schema['value'], equals(42));
      });
    });

    group('Schema Creation', () {
      setUp(() {
        // Register test schemas before each test
        SchemaRegistry.register<TestModel, TestSchema>(TestSchema.parse);
        SchemaRegistry.register<AnotherModel, AnotherSchema>(
            AnotherSchema.parse);
      });

      test('createSchema returns correct schema for registered model type', () {
        // Test data
        final data = {'name': 'Test', 'value': 42};

        // Create schema
        final schema = SchemaRegistry.createSchema(TestModel, data);

        // Verify schema creation
        expect(schema, isA<TestSchema>());
        expect(schema!['name'], equals('Test'));
        expect(schema['value'], equals(42));

        // Convert to model to verify full pipeline
        final model = (schema as TestSchema).toModel();
        expect(model.name, equals('Test'));
        expect(model.value, equals(42));
      });

      test('createSchema returns correct schema for different model types', () {
        // Test data for TestModel
        final testData = {'name': 'Test', 'value': 42};

        // Test data for AnotherModel
        final anotherData = {'title': 'Another', 'amount': 99.99};

        // Create schemas
        final testSchema = SchemaRegistry.createSchema(TestModel, testData);
        final anotherSchema =
            SchemaRegistry.createSchema(AnotherModel, anotherData);

        // Verify first schema
        expect(testSchema, isA<TestSchema>());
        expect(testSchema!['name'], equals('Test'));

        // Verify second schema
        expect(anotherSchema, isA<AnotherSchema>());
        expect(anotherSchema!['title'], equals('Another'));
      });

      test('createSchema returns null for unregistered model type', () {
        // Test data
        final data = {'property': 'value'};

        // Try to create schema
        final schema = SchemaRegistry.createSchema(UnregisteredModel, data);

        // Should return null for unregistered type
        expect(schema, isNull);
      });

      test('createSchema handles empty data properly', () {
        // Empty data map
        final emptyData = <String, dynamic>{};

        // Create schema with empty data
        final schema =
            SchemaRegistry.createSchema(TestModel, emptyData) as TestSchema?;

        // Schema should be created but invalid
        expect(schema, isNotNull);
        expect(schema!.validate().isOk, isFalse);
      });

      test('createSchema handles null fields properly', () {
        // Data with null fields
        final dataWithNulls = {'name': null, 'value': null};

        // Create schema
        final schema = SchemaRegistry.createSchema(TestModel, dataWithNulls)
            as TestSchema?;

        // Schema should be created
        expect(schema, isNotNull);

        // Accessing null fields should not throw
        expect(schema!['name'], isNull);
        expect(schema['value'], isNull);

        // But converting to model might throw type errors because of the null values
        expect(() => schema.toModel(), throwsA(isA<TypeError>()));
      });
    });

    group('Integration with TypeService', () {
      setUp(() {
        // Register test schemas before each test
        SchemaRegistry.register<TestModel, TestSchema>(TestSchema.parse);
      });

      test('SchemaRegistry and TypeService work together', () {
        // Check type mappings
        expect(TypeService.isSchemaType(TestSchema), isTrue);
        expect(TypeService.getModelType(TestSchema), equals(TestModel));
        expect(TypeService.getSchemaType(TestModel), equals(TestSchema));

        // Create schema
        final data = {'name': 'Test', 'value': 42};
        final schema = SchemaRegistry.createSchema(TestModel, data);

        // Schema should be created correctly
        expect(schema, isA<TestSchema>());
      });
    });

    group('Error Cases', () {
      test('createSchema handles invalid data gracefully', () {
        // Register schema
        SchemaRegistry.register<TestModel, TestSchema>(TestSchema.parse);

        // Create invalid data (wrong types)
        final invalidData = {'name': 123, 'value': 'not an int'};

        // Create schema with invalid data
        final schema =
            SchemaRegistry.createSchema(TestModel, invalidData) as TestSchema?;

        // Schema should be created
        expect(schema, isNotNull);

        // But converting to model should throw type errors
        expect(() => schema!.toModel(), throwsA(isA<TypeError>()));
      });
    });
  });
}
