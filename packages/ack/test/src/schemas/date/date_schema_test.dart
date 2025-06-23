import 'package:ack/ack.dart';
import 'package:ack/src/constraints/core/datetime_constraint.dart';
import 'package:ack/src/constraints/core/pattern_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('DateSchema', () {
    test('copyWith changes nullable property', () {
      final schema = DateSchema(nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result.isOk, isTrue);
    });

    test('copyWith changes validators', () {
      final schema =
          DateSchema(constraints: [DateConstraint.onOrAfter(DateTime(2000))]);
      expect(schema.getConstraints().length, equals(1));
      expect(schema.getConstraints()[0], isA<DateConstraint>());

      final newSchema = schema
          .copyWith(constraints: [DateConstraint.onOrAfter(DateTime(2000))]);
      expect(newSchema.getConstraints().length, equals(1));
      expect(newSchema.getConstraints()[0], isA<DateConstraint>());
    });

    group('DateSchema Basic Validation', () {
      test('Non-nullable schema fails on null', () {
        final schema = DateSchema();
        final result = schema.validate(null);
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintsError>());
        final constraintsError = error as SchemaConstraintsError;
        expect(
          constraintsError.getConstraint<NonNullableConstraint>(),
          isNotNull,
        );
      });

      test('Nullable schema passes on null', () {
        final schema = DateSchema(nullable: true);
        final result = schema.validate(null);
        expect(result.isOk, isTrue);
      });

      test('Invalid type returns invalid type error', () {
        final schema = DateSchema();
        final result = schema.validate(123); // Not a string.
        expect(result.isOk, isTrue);

        final strictSchema = DateSchema(strict: true);
        final strictResult = strictSchema.validate(123);
        expect(strictResult.isFail, isTrue);

        final error = (strictResult as Fail).error;
        expect(error, isA<SchemaConstraintsError>());
        final constraintsError = error as SchemaConstraintsError;
        expect(
          constraintsError.getConstraint<InvalidTypeConstraint>(),
          isNotNull,
        );
      });

      test('Valid string passes with no constraints', () {
        final schema = DateSchema();
        final result = schema.validate("2021-01-01T00:00:00.000Z");
        expect(result.isOk, isTrue);
      });
    });

    group('MinDateValidator', () {
      final validator = DateConstraint.onOrAfter(DateTime(2025, 1, 1));

      test('Valid dates pass validation', () {
        expect(validator.isValid(DateTime(2040)), isTrue);
      });

      test('Invalid dates fail validation', () {
        expect(validator.isValid(DateTime(2000)), isFalse);
        expect(validator.isValid(DateTime(2024, 12, 31)), isFalse);
      });

      test('schema validation works with email validator', () {
        final schema = DateSchema().min(DateTime(2020, 1, 1));
        expect(schema.validate('2021-01-01T00:00:00.000Z').isOk, isTrue);

        final result = schema.validate('not-a-date');
        expect(result.isFail, isTrue);

        final error = (result as Fail).error;
        expect(error, isA<SchemaConstraintsError>());

        final constraintsError = error as SchemaConstraintsError;
        expect(
          constraintsError.getConstraint<PatternConstraint>(),
          isNotNull,
        );
      });
    });
  });
}
