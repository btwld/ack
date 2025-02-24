import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

void main() {
  group('ObjectSchema', () {
    test('copyWith changes additionalProperties and required', () {
      final schema = ObjectSchema(
          {
            'age': IntSchema(),
          },
          additionalProperties: false,
          required: ['age']);
      final newSchema =
          schema.copyWith(additionalProperties: true, required: []);
      // With additionalProperties set to true, extra keys should be allowed.
      final result = newSchema.validate({'age': 30, 'extra': 'value'});
      expect(result, isA<Ok>());
    });

    test('Non-nullable schema fails on null', () {
      final schema = ObjectSchema({
        'age': IntSchema(),
      });
      final result = schema.validate(null);
      expect(result, isA<Fail>());
      expect(
          TestHelpers.isFail(result).error.type, equals('non_nullable_value'));
    });

    test('Nullable schema passes on null', () {
      final schema = ObjectSchema({
        'age': IntSchema(),
      }, nullable: true);
      final result = schema.validate(null);
      expect(result, isA<Ok>());
    });

    test('Invalid type returns invalid type error', () {
      final schema = ObjectSchema({
        'age': IntSchema(),
      });
      final result = schema.validate('not a map');
      expect(result, isA<Fail>());
      expect(TestHelpers.isFail(result).error.type, equals('invalid_type'));
    });

    test('Valid object passes with correct properties', () {
      final schema = ObjectSchema(
          {
            'age': IntSchema(),
          },
          additionalProperties: false,
          required: ['age']);
      final result = schema.validate({'age': 25});
      expect(result, isA<Ok>());
      expect(TestHelpers.isOk(result).value, equals({'age': 25}));
    });

    test('Fails on additional unallowed property', () {
      final schema = ObjectSchema(
          {
            'age': IntSchema(),
          },
          additionalProperties: false,
          required: ['age']);
      final result = schema.validate({'age': 25, 'name': 'John'});
      expect(result, isA<Fail>());
      // Expect an error indicating an unallowed additional property.
      final error = TestHelpers.isConstraintError(result);
      expect(error.getError('unallowed_additional_property'), isNotNull);
    });

    test('Fails on missing required property', () {
      final schema = ObjectSchema(
          {
            'age': IntSchema(),
          },
          additionalProperties: true,
          required: ['age']);
      final result = schema.validate({'name': 'John'});
      expect(result, isA<Fail>());
      // Expect an error indicating a required property is missing.
      final error = TestHelpers.isConstraintError(result);
      expect(error.getError('required_property_missing'), isNotNull);
    });

    test('Fails on property schema error', () {
      // Assuming IntSchema validates that the value must be an integer.
      final schema = ObjectSchema(
          {
            'age': IntSchema(),
          },
          additionalProperties: true,
          required: ['age']);
      final result = schema.validate({'age': 'not an int'});
      expect(result, isA<Fail>());
      final error = TestHelpers.isConstraintError(result);
      // key matches

      expect(error.getError('property_schema_error'), isNotNull);
    });

    test('extend merges properties correctly', () {
      final baseSchema = ObjectSchema({
        'age': IntSchema(),
      }, additionalProperties: false);
      // Extend the schema by adding a new property 'score'
      final extendedSchema = baseSchema.extend(
          {
            'score': IntSchema(),
          },
          additionalProperties: false,
          required: ['score']);
      final result = extendedSchema.validate({'age': 30, 'score': 100});
      expect(result, isA<Ok>());
    });
  });
}
