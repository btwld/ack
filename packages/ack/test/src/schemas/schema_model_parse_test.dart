import 'package:ack/ack.dart';
import 'package:test/test.dart';

// Create a test model class
class TestModel {
  final String name;
  final int age;

  TestModel({required this.name, required this.age});
}

// Create a test schema class that extends SchemaModel
class TestSchema extends SchemaModel<TestModel> {
  static final ObjectSchema schema = Ack.object({
    'name': Ack.string,
    'age': Ack.int,
  }, required: [
    'name',
    'age'
  ]);

  TestSchema([Object? value]) : super(value);

  TestSchema.validated(Map<String, Object?> validatedData)
      : super.validated(validatedData);

  @override
  ObjectSchema getSchema() => schema;

  // Implement the static parseModel method
  static TestModel parseModel(Map<String, Object?> data) {
    final schema = TestSchema(data);
    if (!schema.isValid) {
      throw AckException(schema.getErrors()!);
    }
    return schema.toModel();
  }

  // Implement the static tryParseModel method
  static TestModel? tryParseModel(Map<String, Object?> data) {
    try {
      final schema = TestSchema(data);
      return schema.isValid ? schema.toModel() : null;
    } catch (_) {
      return null;
    }
  }

  @override
  TestModel toModel() {
    if (!isValid) {
      throw AckException(getErrors()!);
    }

    return TestModel(
      name: getValue<String>('name')!,
      age: getValue<int>('age')!,
    );
  }
}

void main() {
  group('SchemaModel Parse Methods', () {
    group('parse()', () {
      test('returns a valid schema model for valid input', () {
        final data = {'name': 'John', 'age': 30};
        final model = TestSchema(data).parse(data);

        expect(model.name, equals('John'));
        expect(model.age, equals(30));
      });

      test('throws AckException for invalid input', () {
        final data = {'name': 'John'}; // missing required 'age'

        expect(
          () => TestSchema(data).parse(data),
          throwsA(isA<AckException>()),
        );
      });

      test('converts validated data to model', () {
        final data = {'name': 'John', 'age': 30};
        final model = TestSchema(data).parse(data);

        expect(model.name, equals('John'));
        expect(model.age, equals(30));
      });
    });

    group('tryParse()', () {
      test('returns a valid model for valid input', () {
        final data = {'name': 'John', 'age': 30};
        final model = TestSchema(data).tryParse(data);

        expect(model, isNotNull);
        expect(model!.name, equals('John'));
        expect(model.age, equals(30));
      });

      test('returns null for invalid input', () {
        final data = {'name': 'John'}; // missing required 'age'
        final model = TestSchema(data).tryParse(data);

        expect(model, isNull);
      });
    });

    group('parseModel() static method', () {
      test('returns a valid model for valid input', () {
        final data = {'name': 'John', 'age': 30};
        final model = TestSchema.parseModel(data);

        expect(model.name, equals('John'));
        expect(model.age, equals(30));
      });

      test('throws AckException for invalid input', () {
        final data = {'name': 'John'}; // missing required 'age'

        expect(
          () => TestSchema.parseModel(data),
          throwsA(isA<AckException>()),
        );
      });
    });

    group('tryParseModel() static method', () {
      test('returns a valid model for valid input', () {
        final data = {'name': 'John', 'age': 30};
        final model = TestSchema.tryParseModel(data);

        expect(model, isNotNull);
        expect(model!.name, equals('John'));
        expect(model.age, equals(30));
      });

      test('returns null for invalid input', () {
        final data = {'name': 'John'}; // missing required 'age'
        final model = TestSchema.tryParseModel(data);

        expect(model, isNull);
      });
    });
  });
}
