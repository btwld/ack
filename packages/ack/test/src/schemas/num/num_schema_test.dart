import 'package:ack/ack.dart';
import 'package:ack/src/constraints/core/comparison_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('DoubleSchema', () {
    test('copyWith changes nullable property', () {
      final schema = DoubleSchema(nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result.isOk, isTrue);
    });

    test('copyWith changes validators', () {
      final schema = DoubleSchema(constraints: [ComparisonConstraint.numberMax(5.0)]);
      expect(schema.getConstraints().length, equals(1));
      expect(schema.getConstraints()[0], isA<ComparisonConstraint>());

      final newSchema =
          schema.copyWith(constraints: [ComparisonConstraint.numberMin(1.0)]);
      expect(newSchema.getConstraints().length, equals(1));
      expect(newSchema.getConstraints()[0], isA<ComparisonConstraint>());
    });

    group('DoubleSchema Basic Validation', () {
      test('Non-nullable schema fails on null', () {
        final schema = DoubleSchema();
        final result = schema.validate(null);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error as SchemaConstraintsError;
        expect(error.getConstraint<NonNullableConstraint>(), isNotNull);

        final nonNullableError = error.getConstraint<NonNullableConstraint>();
        expect(
          nonNullableError!.constraintKey == 'non_nullable',
          isTrue,
        );
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

        final error = (result as Fail).error as SchemaConstraintsError;
        expect(error.getConstraint<InvalidTypeConstraint>(), isNotNull);
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
        final validator = ComparisonConstraint.numberMin(5.0);
        expect(validator.isValid(6.0), isTrue);
        expect(validator.isValid(5.0), isTrue);
      });

      test('Values below min fail validation', () {
        final validator = ComparisonConstraint.numberMin(5.0);
        expect(validator.isValid(4.0), isFalse);
      });

      test('schema validation works with min value', () {
        final schema = DoubleSchema().min(5.0);
        expect(schema.validate(6.0).isOk, isTrue);

        final result = schema.validate(4.0);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error as SchemaConstraintsError;
        expect(error.getConstraint<ComparisonConstraint>(), isNotNull);
      });
    });

    group('MaxValueValidator', () {
      test('Values below max pass validation', () {
        final validator = ComparisonConstraint.numberMax(5.0);
        expect(validator.isValid(4.0), isTrue);
        expect(validator.isValid(5.0), isTrue);
      });

      test('Values above max fail validation', () {
        final validator = ComparisonConstraint.numberMax(5.0);
        expect(validator.isValid(6.0), isFalse);
      });

      test('schema validation works with max value', () {
        final schema = DoubleSchema().max(5.0);
        expect(schema.validate(4.0).isOk, isTrue);

        final result = schema.validate(6.0);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error as SchemaConstraintsError;
        expect(error.getConstraint<ComparisonConstraint>(), isNotNull);
      });
    });

    group('RangeValidator', () {
      test('Values in range pass validation', () {
        final validator = ComparisonConstraint.numberRange(1.0, 5.0);
        expect(validator.isValid(1.0), isTrue);
        expect(validator.isValid(3.0), isTrue);
        expect(validator.isValid(5.0), isTrue);
      });

      test('Values outside range fail validation', () {
        final validator = ComparisonConstraint.numberRange(1.0, 5.0);
        expect(validator.isValid(0.9), isFalse);
        expect(validator.isValid(5.1), isFalse);
      });

      test('schema validation works with range', () {
        final schema = DoubleSchema().range(1.0, 5.0);
        expect(schema.validate(3.0).isOk, isTrue);

        final result = schema.validate(6.0);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error as SchemaConstraintsError;
        expect(error.getConstraint<ComparisonConstraint>(), isNotNull);
      });
    });

    group('MultipleOfValidator', () {
      test('Values that are multiples pass validation', () {
        final validator = ComparisonConstraint.numberMultipleOf(0.5);
        expect(validator.isValid(1.0), isTrue);
        expect(validator.isValid(1.5), isTrue);
        expect(validator.isValid(2.0), isTrue);
      });

      test('Values that are not multiples fail validation', () {
        final validator = ComparisonConstraint.numberMultipleOf(0.5);
        expect(validator.isValid(1.7), isFalse);
        expect(validator.isValid(2.3), isFalse);
      });

      test('schema validation works with multipleOf', () {
        final schema = DoubleSchema().multipleOf(0.5);
        expect(schema.validate(1.5).isOk, isTrue);

        final result = schema.validate(1.7);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error as SchemaConstraintsError;
        expect(error.getConstraint<ComparisonConstraint>(),
            isNotNull);
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
      final schema = IntegerSchema(constraints: [ComparisonConstraint.numberMax(5)]);
      expect(schema.getConstraints().length, equals(1));
      expect(schema.getConstraints()[0], isA<ComparisonConstraint>());

      final newSchema = schema.copyWith(constraints: [ComparisonConstraint.numberMin(1)]);
      expect(newSchema.getConstraints().length, equals(1));
      expect(newSchema.getConstraints()[0], isA<ComparisonConstraint>());
    });

    group('IntSchema Basic Validation', () {
      test('Non-nullable schema fails on null', () {
        final schema = IntegerSchema();
        final result = schema.validate(null);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error as SchemaConstraintsError;
        expect(error.getConstraint<NonNullableConstraint>(), isNotNull);
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

        final error = (result as Fail).error as SchemaConstraintsError;
        expect(error.getConstraint<InvalidTypeConstraint>(), isNotNull);
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

      test('Double fails validation', () {
        final schema = IntegerSchema();
        final result = schema.validate(42.5);
        expect(result.isFail, isTrue);
      });
    });

    group('MinValueValidator', () {
      test('Values above min pass validation', () {
        final validator = ComparisonConstraint.numberMin(5);
        expect(validator.isValid(6), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('Values below min fail validation', () {
        final validator = ComparisonConstraint.numberMin(5);
        expect(validator.isValid(4), isFalse);
      });

      test('schema validation works with min value', () {
        final schema = IntegerSchema().min(5);
        expect(schema.validate(6).isOk, isTrue);

        final result = schema.validate(4);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error as SchemaConstraintsError;
        expect(error.getConstraint<ComparisonConstraint>(), isNotNull);
      });
    });

    group('MaxValueValidator', () {
      test('Values below max pass validation', () {
        final validator = ComparisonConstraint.numberMax(5);
        expect(validator.isValid(4), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('Values above max fail validation', () {
        final validator = ComparisonConstraint.numberMax(5);
        expect(validator.isValid(6), isFalse);
      });

    });

    group('RangeValidator', () {
      test('Values in range pass validation', () {
        final validator = ComparisonConstraint.numberRange(1, 5);
        expect(validator.isValid(1), isTrue);
        expect(validator.isValid(3), isTrue);
        expect(validator.isValid(5), isTrue);
      });

      test('Values outside range fail validation', () {
        final validator = ComparisonConstraint.numberRange(1, 5);
        expect(validator.isValid(0), isFalse);
        expect(validator.isValid(6), isFalse);
      });

      test('schema validation works with range', () {
        final schema = IntegerSchema().range(1, 5);
        expect(schema.validate(3).isOk, isTrue);

        final result = schema.validate(6);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error as SchemaConstraintsError;
        expect(error.getConstraint<ComparisonConstraint>(), isNotNull);
      });
    });

    group('MultipleOfValidator', () {
      test('Values that are multiples pass validation', () {
        final validator = ComparisonConstraint.numberMultipleOf(3);
        expect(validator.isValid(6), isTrue);
        expect(validator.isValid(9), isTrue);
        expect(validator.isValid(12), isTrue);
      });

      test('Values that are not multiples fail validation', () {
        final validator = ComparisonConstraint.numberMultipleOf(3);
        expect(validator.isValid(7), isFalse);
        expect(validator.isValid(10), isFalse);
      });

      test('schema validation works with multipleOf', () {
        final schema = IntegerSchema().multipleOf(3);
        expect(schema.validate(6).isOk, isTrue);

        final result = schema.validate(7);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error as SchemaConstraintsError;
        expect(
          error.getConstraint<ComparisonConstraint>(),
          isNotNull,
        );
      });
    });
  });
}
