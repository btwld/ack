import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

void main() {
  group('ListSchema', () {
    test('copyWith changes nullable property', () {
      final schema = ListSchema(IntSchema(), nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result, isA<Ok>());
    });

    test('copyWith changes constraints', () {
      final schema =
          ListSchema<int>(IntSchema(), constraints: [MaxItemsValidator(5)]);
      expect(schema.getConstraints().length, equals(1));
      expect(schema.getConstraints()[0], isA<MaxItemsValidator>());

      final newSchema = schema.copyWith(constraints: [MinItemsValidator(1)]);
      expect(newSchema.getConstraints().length, equals(1));
      expect(newSchema.getConstraints()[0], isA<MinItemsValidator>());
    });

    group('ListSchema Basic Validation', () {
      test('Non-nullable schema fails on null', () {
        final schema = ListSchema<int>(IntSchema());
        final result = schema.validate(null);
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type,
            equals('non_nullable_value'));
      });

      test('Nullable schema passes on null', () {
        final schema = ListSchema(IntSchema(), nullable: true);
        final result = schema.validate(null);
        expect(result, isA<Ok>());
      });

      test('Invalid type returns invalid type error', () {
        final schema = ListSchema(IntSchema());
        final result = schema.validate('not a list');
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type, equals('invalid_type'));
      });

      test('Valid list passes with no constraints', () {
        final schema = ListSchema(IntSchema());
        final result = schema.validate([1, 2, 3]);
        expect(result, isA<Ok>());
        expect(TestHelpers.isOk(result).value, equals([1, 2, 3]));
      });
    });

    group('UniqueItemsValidator', () {
      test('Unique list passes validation', () {
        final validator = UniqueItemsValidator<int>();
        expect(validator.validate([1, 2, 3]), isNull);
      });

      test('Non-unique list fails validation', () {
        final validator = UniqueItemsValidator<int>();
        expect(validator.validate([1, 2, 2, 3]),
            isA<ConstraintsValidationError>());
      });

      test('schema validation works with uniqueItems', () {
        final schema = ListSchema(IntSchema()).uniqueItems();
        expect(schema.validate([1, 2, 3]), isA<Ok>());

        expect(schema.validate([1, 2, 2, 3]), isA<Fail>());
      });
    });

    group('MinItemsValidator', () {
      test('List with length >= min passes validation', () {
        final validator = MinItemsValidator(3);
        expect(validator.validate([1, 2, 3]), isNull);
        expect(validator.validate([1, 2, 3, 4]), isNull);
      });

      test('List with length < min fails validation', () {
        final validator = MinItemsValidator(3);
        expect(validator.validate([1, 2]), isA<ConstraintsValidationError>());
      });

      test('schema validation works with minItems', () {
        final schema = ListSchema(IntSchema()).minItems(3);
        expect(schema.validate([1, 2, 3]), isA<Ok>());

        final result = schema.validate([1, 2]);
        TestHelpers.expectConstraintErrorOfType(result, 'list_min_items');
      });
    });

    group('MaxItemsValidator', () {
      test('List with length <= max passes validation', () {
        final validator = MaxItemsValidator(3);
        expect(validator.validate([1, 2]), isNull);
        expect(validator.validate([1, 2, 3]), isNull);
      });

      test('List with length > max fails validation', () {
        final validator = MaxItemsValidator(3);
        expect(validator.validate([1, 2, 3, 4]),
            isA<ConstraintsValidationError>());
      });

      test('schema validation works with maxItems', () {
        final schema = ListSchema(IntSchema()).maxItems(3);
        expect(schema.validate([1, 2, 3]), isA<Ok>());

        final result = schema.validate([1, 2, 3, 4]);
        TestHelpers.expectConstraintErrorOfType(result, 'list_max_items');
      });
    });
  });
}
