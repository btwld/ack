import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

void main() {
  group('DoubleSchema', () {
    test('copyWith changes nullable property', () {
      final schema = DoubleSchema(nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result.isOk, isTrue);
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
        final validator = MinValueValidator(5);
        expect(validator.check(6), isTrue);
        expect(validator.check(5), isTrue);
      });

      test('Values below min fail validation', () {
        final validator = MinValueValidator(5);
        expect(validator.check(4), isFalse);
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
        final validator = MaxValueValidator(5);
        expect(validator.check(4), isTrue);
        expect(validator.check(5), isTrue);
      });

      test('Values above max fail validation', () {
        final validator = MaxValueValidator(5);
        expect(validator.check(6), isFalse);
      });
    });

    group('RangeValidator', () {
      test('Values in range pass validation', () {
        final validator = RangeValidator(1, 5);
        expect(validator.check(1), isTrue);
        expect(validator.check(3), isTrue);
        expect(validator.check(5), isTrue);
      });

      test('Values outside range fail validation', () {
        final validator = RangeValidator(1, 5);
        expect(validator.check(0), isFalse);
        expect(validator.check(6), isFalse);
        expect(validator.check(1), isTrue);
        expect(validator.check(5), isTrue);
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
      final schema = IntSchema(nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result.isOk, isTrue);
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
        expect(result.isFail, isTrue);
        expect(result, hasOneSchemaError('non_nullable_value'));
      });

      test('Nullable schema passes on null', () {
        final schema = IntSchema(nullable: true);
        final result = schema.validate(null);
        expect(result.isOk, isTrue);
      });

      test('Invalid type returns invalid type error', () {
        final schema = IntSchema();
        final result = schema.validate('not an int');
        expect(result.isFail, isTrue);
        expect(result, hasOneSchemaError('invalid_type'));
      });

      test('Valid int passes with no constraints', () {
        final schema = IntSchema();
        final result = schema.validate(42);
        expect(result.isOk, isTrue);
      });

      test('String parses to int', () {
        final schema = IntSchema();
        final result = schema.validate('42');
        expect(result.isOk, isTrue);
      });
    });

    group('MinValueValidator', () {
      test('Values above min pass validation', () {
        final validator = MinValueValidator(5);
        expect(validator.check(6), isTrue);
        expect(validator.check(5), isTrue);
      });

      test('Values below min fail validation', () {
        final validator = MinValueValidator(5);
        expect(validator.check(4), isFalse);
      });

      test('schema validation works with min value', () {
        final schema = IntSchema().maxValue(5);
        expect(schema.validate(4).isOk, isTrue);

        final result = schema.validate(6);
        expect(result, hasOneConstraintError('num_max_value'));
      });
    });

    group('MaxValueValidator', () {
      test('Values below max pass validation', () {
        final validator = MaxValueValidator(5);
        expect(validator.check(4), isTrue);
        expect(validator.check(5), isTrue);
      });

      test('Values above max fail validation', () {
        final validator = MaxValueValidator(5);
        expect(validator.check(6), isFalse);
      });
    });

    group('RangeValidator', () {
      test('Values in range pass validation', () {
        final validator = RangeValidator(1, 5);
        expect(validator.check(1), isTrue);
        expect(validator.check(3), isTrue);
        expect(validator.check(5), isTrue);
      });

      test('Values outside range fail validation', () {
        final validator = RangeValidator(1, 5);
        expect(validator.check(0), isFalse);
        expect(validator.check(6), isFalse);
        expect(validator.check(1), isTrue);
        expect(validator.check(5), isTrue);
      });

      test('schema validation works with range', () {
        final schema = IntSchema().range(1, 5);
        final result = schema.validate(3);
        expect(result.isOk, isTrue);

        final result2 = schema.validate(6);
        expect(result2, hasOneConstraintError('num_range'));
      });
    });
  });
}
