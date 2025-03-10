import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('List Validators', () {
    group('UniqueItemsValidator', () {
      test('Unique list passes validation', () {
        final validator = ListUniqueItemsConstraint<int>();
        expect(validator.isValid([1, 2, 3]), isTrue);
      });

      test('Empty list passes validation', () {
        final validator = ListUniqueItemsConstraint<int>();
        expect(validator.isValid([]), isTrue);
      });

      test('Singleton list passes validation', () {
        final validator = ListUniqueItemsConstraint<int>();
        expect(validator.isValid([1]), isTrue);
      });

      test('Non-unique list fails validation', () {
        final validator = ListUniqueItemsConstraint<int>();
        expect(validator.isValid([1, 2, 2, 3]), isFalse);
      });

      test('Non-adjacent duplicates fail validation', () {
        final validator = ListUniqueItemsConstraint<int>();
        expect(validator.isValid([1, 2, 1, 3]), isFalse);
      });

      test('Schema validation works with uniqueItems', () {
        final schema = ListSchema(IntegerSchema()).uniqueItems();
        expect(schema.validate([1, 2, 3]).isOk, isTrue);

        final result = schema.validate([1, 2, 2, 3]);
        expect(result.isFail, isTrue);

        final constraintsError =
            (result as Fail).error as SchemaConstraintsError;
        expect(
          constraintsError.getConstraint<ListUniqueItemsConstraint<int>>(),
          isNotNull,
        );
      });
    });

    group('MinItemsValidator', () {
      test('List with length >= min passes validation', () {
        final validator = ListMinItemsConstraint<int>(3);
        expect(validator.isValid([1, 2, 3]), isTrue);
        expect(validator.isValid([1, 2, 3, 4]), isTrue);
      });

      test('List with exactly min items passes validation', () {
        final validator = ListMinItemsConstraint<int>(3);
        expect(validator.isValid([1, 2, 3]), isTrue);
      });

      test('List with length < min fails validation', () {
        final validator = ListMinItemsConstraint<int>(3);
        expect(validator.isValid([1, 2]), isFalse);
      });

      test('Empty list fails validation for minItems', () {
        final validator = ListMinItemsConstraint<int>(1);
        expect(validator.isValid([]), isFalse);
      });

      test('Schema validation works with minItems', () {
        final schema = ListSchema(IntegerSchema()).minItems(3);
        expect(schema.validate([1, 2, 3]).isOk, isTrue);

        final result = schema.validate([1, 2]);
        expect(result.isFail, isTrue);

        final constraintsError =
            (result as Fail).error as SchemaConstraintsError;
        expect(
          constraintsError.getConstraint<ListMinItemsConstraint<int>>(),
          isNotNull,
        );
      });
    });

    group('MaxItemsValidator', () {
      test('List with length <= max passes validation', () {
        final validator = ListMaxItemsConstraint<int>(3);
        expect(validator.isValid([]), isTrue);
        expect(validator.isValid([1, 2]), isTrue);
        expect(validator.isValid([1, 2, 3]), isTrue);
      });

      test('List with exactly max items passes validation', () {
        final validator = ListMaxItemsConstraint<int>(3);
        expect(validator.isValid([1, 2, 3]), isTrue);
      });

      test('List with length > max fails validation', () {
        final validator = ListMaxItemsConstraint<int>(3);
        expect(validator.isValid([1, 2, 3, 4]), isFalse);
      });

      test('Schema validation works with maxItems', () {
        final schema = ListSchema(IntegerSchema()).maxItems(3);
        expect(schema.validate([1, 2, 3]).isOk, isTrue);

        final result = schema.validate([1, 2, 3, 4]);
        expect(result.isFail, isTrue);

        final constraintsError =
            (result as Fail).error as SchemaConstraintsError;
        expect(
          constraintsError.getConstraint<ListMaxItemsConstraint<int>>(),
          isNotNull,
        );
      });
    });
  });
}
