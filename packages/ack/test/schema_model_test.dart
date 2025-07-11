import 'package:ack/ack.dart';
import 'package:test/test.dart';

// Test model class
class TestUser {
  final String id;
  final String name;
  final int? age;

  TestUser({required this.id, required this.name, this.age});
}

// Test SchemaModel implementation
class TestUserSchemaModel extends SchemaModel<TestUser> {
  TestUserSchemaModel._();

  factory TestUserSchemaModel() => _instance;

  static final _instance = TestUserSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return Ack.object({
      'id': Ack.string().minLength(1),
      'name': Ack.string().minLength(2),
      'age': Ack.integer().positive().optional().nullable(),
    });
  }

  @override
  TestUser createFromMap(Map<String, dynamic> map) {
    return TestUser(
      id: map['id'] as String,
      name: map['name'] as String,
      age: map['age'] as int?,
    );
  }
}

// Test model with additional properties
class FlexibleData {
  final String id;
  final Map<String, dynamic> metadata;

  FlexibleData({required this.id, required this.metadata});
}

class FlexibleDataSchemaModel extends SchemaModel<FlexibleData> {
  FlexibleDataSchemaModel._();

  factory FlexibleDataSchemaModel() => _instance;

  static final _instance = FlexibleDataSchemaModel._();

  @override
  ObjectSchema buildSchema() {
    return Ack.object({
      'id': Ack.string(),
    }, additionalProperties: true);
  }

  @override
  FlexibleData createFromMap(Map<String, dynamic> map) {
    return FlexibleData(
      id: map['id'] as String,
      metadata: extractAdditionalProperties(map, {'id'}),
    );
  }
}

void main() {
  group('SchemaModel', () {
    late TestUserSchemaModel userModel;

    setUp(() {
      userModel = TestUserSchemaModel();
      userModel.clear(); // Ensure clean state
    });

    group('Value Access', () {
      test('should throw StateError when accessing value before validation', () {
        expect(
          () => userModel.value,
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Cannot access SchemaModel.value before validation'),
          )),
        );
      });

      test('should allow value access after successful validation', () {
        final data = {'id': '123', 'name': 'John Doe'};
        userModel.parse(data);

        expect(() => userModel.value, returnsNormally);
        expect(userModel.value?.id, equals('123'));
        expect(userModel.value?.name, equals('John Doe'));
      });

      test('should return null value after failed validation', () {
        final invalidData = {'id': ''};
        userModel.parse(invalidData);

        expect(userModel.value, isNull);
      });

      test('should reset value access after clear()', () {
        final data = {'id': '123', 'name': 'John'};
        userModel.parse(data);
        
        expect(userModel.value, isNotNull);
        
        userModel.clear();
        
        expect(
          () => userModel.value,
          throwsA(isA<StateError>()),
        );
      });
    });

    group('Parsing Methods', () {
      test('parse() should return success result for valid data', () {
        final data = {'id': '123', 'name': 'John Doe', 'age': 25};
        final result = userModel.parse(data);

        expect(result.isOk, isTrue);
        expect(userModel.value?.id, equals('123'));
        expect(userModel.value?.age, equals(25));
      });

      test('parse() should return error result for invalid data', () {
        final data = {'id': '', 'name': 'J'}; // Both fail validation
        final result = userModel.parse(data);

        expect(result.isOk, isFalse);
        expect(result.getError(), isA<SchemaError>());
        expect(userModel.value, isNull);
      });

      test('parseJson() should parse valid JSON string', () {
        const json = '{"id": "456", "name": "Jane Smith"}';
        final result = userModel.parseJson(json);

        expect(result.isOk, isTrue);
        expect(userModel.value?.id, equals('456'));
        expect(userModel.value?.name, equals('Jane Smith'));
      });

      test('parseJson() should handle invalid JSON', () {
        const invalidJson = '{invalid json}';
        final result = userModel.parseJson(invalidJson);

        expect(result.isOk, isFalse);
        expect(result.getError().message, contains('Invalid JSON'));
      });

      test('parseOrThrow() should return value for valid data', () {
        final data = {'id': '789', 'name': 'Alice'};
        final user = userModel.parseOrThrow(data);

        expect(user.id, equals('789'));
        expect(user.name, equals('Alice'));
      });

      test('parseOrThrow() should throw AckException for invalid data', () {
        final data = {'id': ''};

        expect(
          () => userModel.parseOrThrow(data),
          throwsA(isA<AckException>()),
        );
      });

      test('tryParse() should return value for valid data', () {
        final data = {'id': '999', 'name': 'Bob'};
        final user = userModel.tryParse(data);

        expect(user, isNotNull);
        expect(user!.id, equals('999'));
      });

      test('tryParse() should return null for invalid data', () {
        final data = {'invalid': 'data'};
        final user = userModel.tryParse(data);

        expect(user, isNull);
      });
    });

    group('Schema Access', () {
      test('should build schema correctly', () {
        // Access schema through toJsonSchema which is public
        final jsonSchema = userModel.toJsonSchema();

        expect(jsonSchema['type'], equals('object'));
        expect(jsonSchema['properties'], isA<Map>());
        
        final properties = jsonSchema['properties'] as Map;
        expect(properties.containsKey('id'), isTrue);
        expect(properties.containsKey('name'), isTrue);
        expect(properties.containsKey('age'), isTrue);
      });

      test('toJsonSchema() should export JSON Schema', () {
        final jsonSchema = userModel.toJsonSchema();

        expect(jsonSchema['type'], equals('object'));
        expect(jsonSchema['required'], contains('id'));
        expect(jsonSchema['required'], contains('name'));
        expect(jsonSchema['properties']['age']['type'], equals('integer'));
      });
    });

    group('Additional Properties', () {
      test('extractAdditionalProperties should filter known fields', () {
        final model = FlexibleDataSchemaModel();
        final data = {
          'id': 'test-123',
          'extra1': 'value1',
          'extra2': 42,
          'extra3': true,
        };

        final result = model.parse(data);
        
        expect(result.isOk, isTrue);
        expect(model.value?.id, equals('test-123'));
        expect(model.value?.metadata, equals({
          'extra1': 'value1',
          'extra2': 42,
          'extra3': true,
        }));
      });

      test('extractAdditionalProperties should handle empty map', () {
        final model = FlexibleDataSchemaModel();
        final data = {'id': 'minimal'};

        final result = model.parse(data);
        
        expect(result.isOk, isTrue);
        expect(model.value?.metadata, isEmpty);
      });
    });

    group('Singleton Pattern', () {
      test('should return same instance from factory', () {
        final instance1 = TestUserSchemaModel();
        final instance2 = TestUserSchemaModel();

        expect(identical(instance1, instance2), isTrue);
      });

      test('singleton should maintain state across calls', () {
        final instance1 = TestUserSchemaModel();
        instance1.parse({'id': '123', 'name': 'Test'});

        final instance2 = TestUserSchemaModel();
        expect(instance2.value?.id, equals('123'));
      });
    });

    group('Edge Cases', () {
      test('should handle null optional fields', () {
        final data = {'id': '123', 'name': 'No Age', 'age': null};
        final result = userModel.parse(data);

        expect(result.isOk, isTrue);
        expect(userModel.value?.age, isNull);
      });

      test('should handle missing optional fields', () {
        final data = {'id': '123', 'name': 'No Age'};
        final result = userModel.parse(data);

        expect(result.isOk, isTrue);
        expect(userModel.value?.age, isNull);
      });

      test('should validate nested data correctly', () {
        // This would require a more complex test model with nested schemas
        // Skipping for basic test coverage
      });
    });

    group('Type Safety', () {
      test('should enforce type constraint T extends Object', () {
        // The fact that this compiles proves the constraint works
        expect(TestUser, isA<Type>());
        expect(FlexibleData, isA<Type>());
      });

      test('should provide typed access to parsed values', () {
        userModel.parse({'id': '123', 'name': 'Type Safe'});
        
        // These should compile without casting
        final TestUser? user = userModel.value;
        expect(user?.id, isA<String>());
        expect(user?.name, isA<String>());
        expect(user?.age, isA<int?>());
      });
    });
  });
}