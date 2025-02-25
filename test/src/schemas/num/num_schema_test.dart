import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../../test_helpers.dart';

void main() {
  group('DoubleSchema', () {
    test('copyWith changes nullable property', () {
      final schema = DoubleSchema(nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result.isOk, isTrue);
    });

    test('copyWith changes constraints', () {
      final schema = DoubleSchema(constraints: [MaxNumValidator(5.0)]);
      expect(schema.getConstraints().length, equals(1));
      expect(schema.getConstraints()[0], isA<MaxNumValidator>());

      final newSchema = schema.copyWith(constraints: [MinNumValidator(1.0)]);
      expect(newSchema.getConstraints().length, equals(1));
      expect(newSchema.getConstraints()[0], isA<MinNumValidator>());
    });

    group('DoubleSchema Basic Validation', () {
      test('Non-nullable schema fails on null', () {
        final schema = DoubleSchema();
        final result = schema.validate(null);
        expect(result.isFail, isTrue);
        expect(result, hasOneSchemaError('non_nullable_value'));
      });

      test('Nullable schema passes on null', () {
        final schema = DoubleSchema(nullable: true);
        final result = schema.validate(null);
        expect(result.isOk, isTrue);
      });

      test('Invalid type returns invalid type error', () {
        final schema = DoubleSchema();
        final result = schema.validate('not a double');
        expect(result.isFail, isTrue);
        expect(result, hasOneSchemaError('invalid_type'));
      });

      test('Valid double passes with no constraints', () {
        final schema = DoubleSchema();
        final result = schema.validate(3.14);
        expect(result.isOk, isTrue);
      });

      test('String parses to double', () {
        final schema = DoubleSchema();
        final result = schema.validate('3.14');
        expect(result.isOk, isTrue);
      });
    });

    group('MinValueValidator', () {
      test('Values above min pass validation', () {
        final validator = MinNumValidator(5);
        expect(validator.isValid(6), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('Values below min fail validation', () {
        final validator = MinNumValidator(5);
        expect(validator.isValid(4), isFalse);
      });

      test('schema validation works with min value', () {
        final schema = DoubleSchema().maxValue(5);
        expect(schema.validate(4).isOk, isTrue);

        final result = schema.validate(6);
        expect(result.isFail, isTrue);
        expect(result, hasOneConstraintError('num_max_value'));
      });
    });

    group('MaxValueValidator', () {
      test('Values below max pass validation', () {
        final validator = MaxNumValidator(5);
        expect(validator.isValid(4), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('Values above max fail validation', () {
        final validator = MaxNumValidator(5);
        expect(validator.isValid(6), isFalse);
      });
    });

    group('RangeValidator', () {
      test('Values in range pass validation', () {
        final validator = RangeNumValidator(1, 5);
        expect(validator.isValid(1), isTrue);
        expect(validator.isValid(3), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('Values outside range fail validation', () {
        final validator = RangeNumValidator(1, 5);
        expect(validator.isValid(0), isFalse);
        expect(validator.isValid(6), isFalse);
        expect(validator.isValid(1), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('schema validation works with range', () {
        final schema = DoubleSchema().range(1, 5);
        final result = schema.validate(3);
        expect(result.isOk, isTrue);

        final result2 = schema.validate(6);
        expect(result2, hasOneConstraintError('num_range'));
      });
    });
  });

  group('IntSchema', () {
    test('copyWith changes nullable property', () {
      final schema = IntegerSchema(nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result.isOk, isTrue);
    });

    test('copyWith changes constraints', () {
      final schema = IntegerSchema(constraints: [MaxNumValidator(5)]);
      expect(schema.getConstraints().length, equals(1));
      expect(schema.getConstraints()[0], isA<MaxNumValidator>());

      final newSchema = schema.copyWith(constraints: [MinNumValidator(1)]);
      expect(newSchema.getConstraints().length, equals(1));
      expect(newSchema.getConstraints()[0], isA<MinNumValidator>());
    });

    group('IntSchema Basic Validation', () {
      test('Non-nullable schema fails on null', () {
        final schema = IntegerSchema();
        final result = schema.validate(null);
        expect(result.isFail, isTrue);
        expect(result, hasOneSchemaError('non_nullable_value'));
      });

      test('Nullable schema passes on null', () {
        final schema = IntegerSchema(nullable: true);
        final result = schema.validate(null);
        expect(result.isOk, isTrue);
      });

      test('Invalid type returns invalid type error', () {
        final schema = IntegerSchema();
        final result = schema.validate('not an int');
        expect(result.isFail, isTrue);
        expect(result, hasOneSchemaError('invalid_type'));
      });

      test('Valid int passes with no constraints', () {
        final schema = IntegerSchema();
        final result = schema.validate(42);
        expect(result.isOk, isTrue);
      });

      test('String parses to int', () {
        final schema = IntegerSchema();
        final result = schema.validate('42');
        expect(result.isOk, isTrue);
      });
    });

    group('MinValueValidator', () {
      test('Values above min pass validation', () {
        final validator = MinNumValidator(5);
        expect(validator.isValid(6), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('Values below min fail validation', () {
        final validator = MinNumValidator(5);
        expect(validator.isValid(4), isFalse);
      });

      test('schema validation works with min value', () {
        final schema = IntegerSchema().maxValue(5);
        expect(schema.validate(4).isOk, isTrue);

        final result = schema.validate(6);
        expect(result, hasOneConstraintError('num_max_value'));
      });
    });

    group('MaxValueValidator', () {
      test('Values below max pass validation', () {
        final validator = MaxNumValidator(5);
        expect(validator.isValid(4), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('Values above max fail validation', () {
        final validator = MaxNumValidator(5);
        expect(validator.isValid(6), isFalse);
      });
    });

    group('RangeValidator', () {
      test('Values in range pass validation', () {
        final validator = RangeNumValidator(1, 5);
        expect(validator.isValid(1), isTrue);
        expect(validator.isValid(3), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('Values outside range fail validation', () {
        final validator = RangeNumValidator(1, 5);
        expect(validator.isValid(0), isFalse);
        expect(validator.isValid(6), isFalse);
        expect(validator.isValid(1), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('schema validation works with range', () {
        final schema = IntegerSchema().range(1, 5);
        final result = schema.validate(3);
        expect(result.isOk, isTrue);

        final result2 = schema.validate(6);
        expect(result2, hasOneConstraintError('num_range'));
      });
    });
  });
}
