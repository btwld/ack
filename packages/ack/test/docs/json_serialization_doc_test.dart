import 'dart:convert';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

// Custom constraint for positive numbers
class PositiveConstraint<T extends num> extends Constraint<T>
    with Validator<T> {
  const PositiveConstraint()
      : super(
          constraintKey: 'positive',
          description: 'Must be positive',
        );

  @override
  bool isValid(T value) => value > 0;

  @override
  String buildMessage(T value) => 'Value must be positive';
}

// Mock model class for testing
class User {
  final String name;
  final int age;
  final String? email;

  User({required this.name, required this.age, this.email});
}

// Mock schema model for testing
class UserSchema extends SchemaModel<User> {
  UserSchema(super.data) {
    if (isValid) {
      _initialize();
    }
  }

  late final String name;
  late final int age;
  late final String? email;

  void _initialize() {
    name = getValue<String>('name')!;
    age = getValue<int>('age')!;
    email = getValue<String>('email');
  }

  @override
  AckSchema getSchema() {
    return Ack.object({
      'name': Ack.string.minLength(2),
      'age': Ack.int.min(0).max(120),
      'email': Ack.string.email().nullable(),
    }, required: [
      'name',
      'age'
    ]);
  }

  @override
  User toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return User(
      name: name,
      age: age,
      email: email,
    );
  }

  static UserSchema fromModel(User user) {
    return UserSchema({
      'name': user.name,
      'age': user.age,
      'email': user.email,
    });
  }
}

void main() {
  group('JSON Serialization Documentation Examples', () {
    group('Basic JSON Parsing', () {
      test('Validates and parses JSON data', () {
        // 1. Define a schema
        final userSchema = Ack.object({
          'name': Ack.string.minLength(2),
          'age': Ack.int.min(0).max(120),
          'email': Ack.string.email().nullable(),
        }, required: [
          'name',
          'age'
        ]);

        // 2. Parse and validate JSON
        final jsonString =
            '{"name": "John", "age": 30, "email": "john@example.com"}';
        final jsonMap = jsonDecode(jsonString);
        final result = userSchema.validate(jsonMap);

        // 3. Verify the result
        expect(result.isOk, isTrue);
        final validData = result.getOrThrow();
        expect(validData['name'], equals('John'));
        expect(validData['age'], equals(30));
        expect(validData['email'], equals('john@example.com'));
      });

      test('Handles invalid JSON data', () {
        final userSchema = Ack.object({
          'name': Ack.string.minLength(2),
          'age': Ack.int.min(0).max(120),
          'email': Ack.string.email().nullable(),
        }, required: [
          'name',
          'age'
        ]);

        // Missing required 'age' field
        final jsonString = '{"name": "John", "email": "john@example.com"}';
        final jsonMap = jsonDecode(jsonString);
        final result = userSchema.validate(jsonMap);

        expect(result.isOk, isFalse);
        final error = result.getError();
        expect(error, isNotNull);
      });
    });

    group('Using Generated Schema Models', () {
      test('Converts between JSON and typed models', () {
        // Create test data
        final jsonMap = {
          'name': 'John',
          'age': 30,
          'email': 'john@example.com',
        };

        // Create a schema object from the data
        final userSchema = UserSchema(jsonMap);
        expect(userSchema.isValid, isTrue);

        // Convert to a typed model
        final user = userSchema.toModel();
        expect(user.name, equals('John'));
        expect(user.age, equals(30));
        expect(user.email, equals('john@example.com'));

        // Convert back to a schema
        final recreatedSchema = UserSchema.fromModel(user);
        expect(recreatedSchema.name, equals('John'));
        expect(recreatedSchema.age, equals(30));
        expect(recreatedSchema.email, equals('john@example.com'));
      });
    });

    group('Handling Nested Objects', () {
      test('Validates nested objects and arrays', () {
        final orderSchema = Ack.object({
          'id': Ack.string,
          'customer':
              Ack.object({'name': Ack.string, 'email': Ack.string.email()}),
          'items': Ack.list(Ack.object({
            'productId': Ack.string,
            'quantity': Ack.int.min(1),
            'price': Ack.double.constrain(PositiveConstraint())
          }))
        });

        final orderData = {
          'id': 'order-123',
          'customer': {'name': 'John Doe', 'email': 'john@example.com'},
          'items': [
            {'productId': 'prod-1', 'quantity': 2, 'price': 29.99},
            {'productId': 'prod-2', 'quantity': 1, 'price': 49.99}
          ]
        };

        final result = orderSchema.validate(orderData);
        expect(result.isOk, isTrue);

        final order = result.getOrThrow();
        expect(order['id'], equals('order-123'));

        final customer = order['customer'] as Map<String, dynamic>;
        expect(customer['name'], equals('John Doe'));

        final items = order['items'] as List<dynamic>;
        final item0 = items[0] as Map<String, dynamic>;
        final item1 = items[1] as Map<String, dynamic>;
        expect(item0['productId'], equals('prod-1'));
        expect(item1['price'], equals(49.99));
      });

      test('Detects errors in nested objects', () {
        final orderSchema = Ack.object({
          'id': Ack.string,
          'customer':
              Ack.object({'name': Ack.string, 'email': Ack.string.email()}),
          'items': Ack.list(Ack.object({
            'productId': Ack.string,
            'quantity': Ack.int.min(1),
            'price': Ack.double.constrain(PositiveConstraint())
          }))
        });

        final invalidOrderData = {
          'id': 'order-123',
          'customer': {
            'name': 'John Doe',
            'email': 'not-an-email' // Invalid email
          },
          'items': [
            {
              'productId': 'prod-1',
              'quantity': 0, // Invalid quantity (less than 1)
              'price': 29.99
            }
          ]
        };

        final result = orderSchema.validate(invalidOrderData);
        expect(result.isOk, isFalse);

        final error = result.getError();
        expect(error, isNotNull); // Should have validation errors
      });
    });

    group('OpenAPI Schema Generation', () {
      test('Generates OpenAPI schema', () {
        final schema = Ack.object({
          'name': Ack.string.minLength(2).maxLength(50),
          'age': Ack.int.min(0).max(120),
        }, required: [
          'name',
          'age'
        ]);

        final converter = JsonSchemaConverter(schema: schema);
        final openApiSchema = converter.toSchema();

        expect(openApiSchema['type'], equals('object'));

        final required = openApiSchema['required'] as List<dynamic>;
        expect(required, contains('name'));
        expect(required, contains('age'));

        final properties = openApiSchema['properties'] as Map<String, dynamic>;

        final nameProperty = properties['name'] as Map<String, dynamic>;
        expect(nameProperty['type'], equals('string'));
        expect(nameProperty['minLength'], equals(2));
        expect(nameProperty['maxLength'], equals(50));

        final ageProperty = properties['age'] as Map<String, dynamic>;
        expect(ageProperty['type'], equals('integer'));
        expect(ageProperty['minimum'], equals(0));
        expect(ageProperty['maximum'], equals(120));
      });
    });

    group('Working with LLM Responses', () {
      test('Parses and validates LLM responses', () {
        final schema = Ack.object({
          'name': Ack.string.minLength(2).maxLength(50),
          'age': Ack.int.min(0).max(120),
        }, required: [
          'name',
          'age'
        ]);

        final converter = JsonSchemaConverter(schema: schema);

        // Simulated LLM response
        final llmResponse = '''
        Here is the person's information:
        <response>
        {
          "name": "John Smith",
          "age": 35
        }
        </response>
        ''';

        // Parse and validate the response
        final jsonPayload = converter.parseResponse(llmResponse);

        expect(jsonPayload['name'], equals('John Smith'));
        expect(jsonPayload['age'], equals(35));
      });

      test('Throws error for invalid LLM responses', () {
        final schema = Ack.object({
          'name': Ack.string.minLength(2).maxLength(50),
          'age': Ack.int.min(0).max(120),
        }, required: [
          'name',
          'age'
        ]);

        final converter = JsonSchemaConverter(schema: schema);

        // Simulated LLM response with missing required field
        final llmResponse = '''
        Here is the person's information:
        <response>
        {
          "name": "John Smith"
        }
        </response>
        ''';

        // Parse and validate the response
        expect(
          () => converter.parseResponse(llmResponse),
          throwsA(isA<JsonSchemaConverterException>()),
        );
      });
    });

    group('Error Handling with SchemaResult', () {
      test('Handles success case', () {
        final userSchema = Ack.object({
          'name': Ack.string.minLength(2),
          'age': Ack.int.min(0),
        }, required: [
          'name',
          'age'
        ]);

        final data = {'name': 'John', 'age': 30};
        final result = userSchema.validate(data);

        expect(result.isOk, isTrue);
        final validData = result.getOrThrow();
        expect(validData['name'], equals('John'));
        expect(validData['age'], equals(30));

        // Test getOrElse
        final validDataOrDefault =
            result.getOrElse(() => {'name': 'Default', 'age': 0});
        expect(validDataOrDefault['name'], equals('John'));
      });

      test('Handles error case', () {
        final userSchema = Ack.object({
          'name': Ack.string.minLength(2),
          'age': Ack.int.min(0),
        }, required: [
          'name',
          'age'
        ]);

        final data = {'name': 'J', 'age': -5}; // Both fields invalid
        final result = userSchema.validate(data);

        expect(result.isOk, isFalse);
        final error = result.getError();
        expect(error, isNotNull); // Should have validation errors

        // Test getOrElse with default
        final defaultData = {'name': 'Default', 'age': 0};
        final dataOrDefault = result.getOrElse(() => defaultData);
        expect(dataOrDefault, equals(defaultData));
      });
    });

    group('Schema Serialization', () {
      test('Serializes schema to JSON', () {
        final schema = Ack.object({
          'name': Ack.string.minLength(2),
          'age': Ack.int.min(0),
        });

        // Convert schema to JSON
        final schemaJson = schema.toJson();

        // Verify it's valid JSON
        final decoded = jsonDecode(schemaJson);
        expect(decoded, isA<Map<String, dynamic>>());
        expect(decoded['type'], equals('object'));
      });
    });
  });
}
