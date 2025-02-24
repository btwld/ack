import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

void main() {
  group('DoubleSchema', () {
    test('copyWith changes nullable property', () {
      final schema = DoubleSchema(nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result, isA<Ok>());
    });

    test('copyWith changes constraints', () {
      final schema = DoubleSchema(constraints: [MaxValueValidator(5.0)]);
      expect(schema.getConstraints().length, equals(1));
      expect(schema.getConstraints()[0], isA<MaxValueValidator>());

      final newSchema = schema.copyWith(constraints: [MinValueValidator(1.0)]);
      expect(newSchema.getConstraints().length, equals(1));
      expect(newSchema.getConstraints()[0], isA<MinValueValidator>());
    });

    group('DoubleSchema Basic Validation', () {
      test('Non-nullable schema fails on null', () {
        final schema = DoubleSchema();
        final result = schema.validate(null);
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type,
            equals('non_nullable_value'));
      });

      test('Nullable schema passes on null', () {
        final schema = DoubleSchema(nullable: true);
        final result = schema.validate(null);
        expect(result, isA<Ok>());
      });

      test('Invalid type returns invalid type error', () {
        final schema = DoubleSchema();
        final result = schema.validate('not a double');
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type, equals('invalid_type'));
      });

      test('Valid double passes with no constraints', () {
        final schema = DoubleSchema();
        final result = schema.validate(3.14);
        expect(result, isA<Ok>());
        expect(TestHelpers.isOk(result).value, equals(3.14));
      });

      test('String parses to double', () {
        final schema = DoubleSchema();
        final result = schema.validate('3.14');
        expect(result, isA<Ok>());
        expect(TestHelpers.isOk(result).value, equals(3.14));
      });
    });

    group('MinValueValidator', () {
      test('Values above min pass validation', () {
        final validator = MinValueValidator(5);
        expect(validator.validate(6), isNull);
        expect(validator.validate(5), isNull);
      });

      test('Values below min fail validation', () {
        final validator = MinValueValidator(5);
        expect(validator.validate(4), isA<ConstraintsValidationError>());
      });

      test('schema validation works with min value', () {
        final schema = DoubleSchema().maxValue(5);
        expect(schema.validate(4), isA<Ok>());

        final result = schema.validate(6);
        TestHelpers.expectConstraintErrorOfType(result, 'num_max_value');
      });
    });

    group('MaxValueValidator', () {
      test('Values below max pass validation', () {
        final validator = MaxValueValidator(5);
        expect(validator.validate(4), isNull);
        expect(validator.validate(5), isNull);
      });

      test('Values above max fail validation', () {
        final validator = MaxValueValidator(5);
        expect(validator.validate(6), isA<ConstraintsValidationError>());
      });
    });

    group('RangeValidator', () {
      test('Values in range pass validation', () {
        final validator = RangeValidator(1, 5);
        expect(validator.validate(1), isNull);
        expect(validator.validate(3), isNull);
        expect(validator.validate(5), isNull);
      });

      test('Values outside range fail validation', () {
        final validator = RangeValidator(1, 5);
        expect(validator.validate(0), isA<ConstraintsValidationError>());
        expect(validator.validate(6), isA<ConstraintsValidationError>());
        expect(validator.validate(1), isNull);
        expect(validator.validate(5), isNull);
      });

      test('schema validation works with range', () {
        final schema = DoubleSchema().range(1, 5);
        final result = schema.validate(3);
        expect(result, isA<Ok>());

        final result2 = schema.validate(6);
        TestHelpers.expectConstraintErrorOfType(result2, 'num_range');
      });
    });
  });

  group('IntSchema', () {
    test('copyWith changes nullable property', () {
      final schema = IntSchema(nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result, isA<Ok>());
    });

    test('copyWith changes constraints', () {
      final schema = IntSchema(constraints: [MaxValueValidator(5)]);
      expect(schema.getConstraints().length, equals(1));
      expect(schema.getConstraints()[0], isA<MaxValueValidator>());

      final newSchema = schema.copyWith(constraints: [MinValueValidator(1)]);
      expect(newSchema.getConstraints().length, equals(1));
      expect(newSchema.getConstraints()[0], isA<MinValueValidator>());
    });

    group('IntSchema Basic Validation', () {
      test('Non-nullable schema fails on null', () {
        final schema = IntSchema();
        final result = schema.validate(null);
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type,
            equals('non_nullable_value'));
      });

      test('Nullable schema passes on null', () {
        final schema = IntSchema(nullable: true);
        final result = schema.validate(null);
        expect(result, isA<Ok>());
      });

      test('Invalid type returns invalid type error', () {
        final schema = IntSchema();
        final result = schema.validate('not an int');
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type, equals('invalid_type'));
      });

      test('Valid int passes with no constraints', () {
        final schema = IntSchema();
        final result = schema.validate(42);
        expect(result, isA<Ok>());
        expect(TestHelpers.isOk(result).value, equals(42));
      });

      test('String parses to int', () {
        final schema = IntSchema();
        final result = schema.validate('42');
        expect(result, isA<Ok>());
        expect(TestHelpers.isOk(result).value, equals(42));
      });
    });

    group('MinValueValidator', () {
      test('Values above min pass validation', () {
        final validator = MinValueValidator(5);
        expect(validator.validate(6), isNull);
        expect(validator.validate(5), isNull);
      });

      test('Values below min fail validation', () {
        final validator = MinValueValidator(5);
        expect(validator.validate(4), isA<ConstraintsValidationError>());
      });

      test('schema validation works with min value', () {
        final schema = IntSchema().maxValue(5);
        expect(schema.validate(4), isA<Ok>());

        final result = schema.validate(6);
        TestHelpers.expectConstraintErrorOfType(result, 'num_max_value');
      });
    });

    group('MaxValueValidator', () {
      test('Values below max pass validation', () {
        final validator = MaxValueValidator(5);
        expect(validator.validate(4), isNull);
        expect(validator.validate(5), isNull);
      });

      test('Values above max fail validation', () {
        final validator = MaxValueValidator(5);
        expect(validator.validate(6), isA<ConstraintsValidationError>());
      });
    });

    group('RangeValidator', () {
      test('Values in range pass validation', () {
        final validator = RangeValidator(1, 5);
        expect(validator.validate(1), isNull);
        expect(validator.validate(3), isNull);
        expect(validator.validate(5), isNull);
      });

      test('Values outside range fail validation', () {
        final validator = RangeValidator(1, 5);
        expect(validator.validate(0), isA<ConstraintsValidationError>());
        expect(validator.validate(6), isA<ConstraintsValidationError>());
        expect(validator.validate(1), isNull);
        expect(validator.validate(5), isNull);
      });

      test('schema validation works with range', () {
        final schema = IntSchema().range(1, 5);
        final result = schema.validate(3);
        expect(result, isA<Ok>());

        final result2 = schema.validate(6);
        TestHelpers.expectConstraintErrorOfType(result2, 'num_range');
      });
    });
  });
}
