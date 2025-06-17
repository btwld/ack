import 'package:ack/ack.dart';
import 'package:test/test.dart';

// Create a test model class
class TestModel {
  final String name;
  final int age;

  TestModel({required this.name, required this.age});
}

// Test schema for the old constructor pattern tests
class TestSchema extends SchemaModel<TestSchema> {
  const TestSchema() : super();
  const TestSchema._valid(Map<String, Object?> data) : super.valid(data);

  @override
  ObjectSchema get definition => Ack.object({
        'name': Ack.string.minLength(2),
        'age': Ack.int.min(0),
      }, required: [
        'name',
        'age'
      ]);

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
  int get age => getValue<int>('age')!;
}

void main() {
  group('SchemaModel Instance-Based Validation', () {
    group('instance validation with property access', () {
      test('returns valid properties for valid input', () {
        final data = {'name': 'John', 'age': 30};
        final schema = const TestSchema().parse(data);

        expect(schema.isValid, isTrue);
        expect(schema.name, equals('John'));
        expect(schema.age, equals(30));
      });

      test('schema throws for missing required fields', () {
        final data = {'name': 'John'}; // missing required 'age'
        expect(
            () => const TestSchema().parse(data), throwsA(isA<AckException>()));
      });

      test('provides error details for invalid input', () {
        final data = {'name': 'John'}; // missing required 'age'
        expect(
            () => const TestSchema().parse(data), throwsA(isA<AckException>()));
      });
    });

    group('safe validation pattern', () {
      test('creates model when valid', () {
        final data = {'name': 'John', 'age': 30};
        final schema = const TestSchema().parse(data);

        final model = TestModel(name: schema.name, age: schema.age);

        expect(model.name, equals('John'));
        expect(model.age, equals(30));
      });

      test('returns null when invalid', () {
        final data = {'name': 'John'}; // missing required 'age'
        final schema = const TestSchema().tryParse(data);

        expect(schema, isNull);
      });
    });

    group('parse methods', () {
      test('parse returns schema for valid input', () {
        final data = {'name': 'John', 'age': 30};
        final schema = const TestSchema().parse(data);

        expect(schema.name, equals('John'));
        expect(schema.age, equals(30));
      });

      test('parse throws for invalid input', () {
        final data = {'name': 'John'}; // missing required 'age'

        expect(
          () => const TestSchema().parse(data),
          throwsA(isA<AckException>()),
        );
      });

      test('tryParse returns schema for valid input', () {
        final data = {'name': 'John', 'age': 30};
        final schema = const TestSchema().tryParse(data);

        expect(schema, isNotNull);
        expect(schema!.name, equals('John'));
        expect(schema.age, equals(30));
      });

      test('tryParse returns null for invalid input', () {
        final data = {'name': 'John'}; // missing required 'age'
        final schema = const TestSchema().tryParse(data);

        expect(schema, isNull);
      });
    });
  });
}
