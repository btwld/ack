import 'package:ack/ack.dart';
import 'package:test/test.dart';

// Create a test model class
class TestModel {
  final String name;
  final int age;

  TestModel({required this.name, required this.age});
}

// Create a test schema class that extends BaseSchema
class TestSchema extends BaseSchema {
  static final ObjectSchema schema = Ack.object({
    'name': Ack.string,
    'age': Ack.int,
  }, required: [
    'name',
    'age'
  ]);

  TestSchema([Object? value]) : super(value);

  @override
  ObjectSchema getSchema() => schema;

  String get name => getValue<String>('name')!;
  int get age => getValue<int>('age')!;

  // Implement the static parseModel method for backward compatibility
  static TestModel parseModel(Map<String, Object?> data) {
    final schema = TestSchema(data);
    if (!schema.isValid) {
      throw AckException(schema.getErrors()!);
    }
    return TestModel(name: schema.name, age: schema.age);
  }

  // Implement the static tryParseModel method for backward compatibility
  static TestModel? tryParseModel(Map<String, Object?> data) {
    try {
      final schema = TestSchema(data);
      return schema.isValid
          ? TestModel(name: schema.name, age: schema.age)
          : null;
    } catch (_) {
      return null;
    }
  }
}

void main() {
  group('BaseSchema Instance-Based Validation', () {
    group('instance validation with property access', () {
      test('returns valid properties for valid input', () {
        final data = {'name': 'John', 'age': 30};
        final schema = TestSchema(data);

        expect(schema.isValid, isTrue);
        expect(schema.name, equals('John'));
        expect(schema.age, equals(30));
      });

      test('schema is invalid for missing required fields', () {
        final data = {'name': 'John'}; // missing required 'age'
        final schema = TestSchema(data);

        expect(schema.isValid, isFalse);
        expect(schema.getErrors(), isNotNull);
      });

      test('provides error details for invalid input', () {
        final data = {'name': 'John'}; // missing required 'age'
        final schema = TestSchema(data);

        expect(schema.isValid, isFalse);
        final errors = schema.getErrors();
        expect(errors, isNotNull);
        // Just verify we get an error, don't check specific content
        expect(errors.toString(), isNotEmpty);
      });
    });

    group('safe validation pattern', () {
      test('creates model when valid', () {
        final data = {'name': 'John', 'age': 30};
        final schema = TestSchema(data);

        TestModel? model;
        if (schema.isValid) {
          model = TestModel(name: schema.name, age: schema.age);
        }

        expect(model, isNotNull);
        expect(model!.name, equals('John'));
        expect(model.age, equals(30));
      });

      test('returns null when invalid', () {
        final data = {'name': 'John'}; // missing required 'age'
        final schema = TestSchema(data);

        TestModel? model;
        if (schema.isValid) {
          model = TestModel(name: schema.name, age: schema.age);
        }

        expect(model, isNull);
      });
    });

    group('static parse methods', () {
      test('parseModel returns model for valid input', () {
        final data = {'name': 'John', 'age': 30};
        final model = TestSchema.parseModel(data);

        expect(model.name, equals('John'));
        expect(model.age, equals(30));
      });

      test('parseModel throws for invalid input', () {
        final data = {'name': 'John'}; // missing required 'age'

        expect(
          () => TestSchema.parseModel(data),
          throwsA(isA<AckException>()),
        );
      });

      test('tryParseModel returns model for valid input', () {
        final data = {'name': 'John', 'age': 30};
        final model = TestSchema.tryParseModel(data);

        expect(model, isNotNull);
        expect(model!.name, equals('John'));
        expect(model.age, equals(30));
      });

      test('tryParseModel returns null for invalid input', () {
        final data = {'name': 'John'}; // missing required 'age'
        final model = TestSchema.tryParseModel(data);

        expect(model, isNull);
      });
    });
  });
}
