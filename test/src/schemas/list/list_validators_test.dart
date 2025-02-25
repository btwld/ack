import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../../test_helpers.dart';

void main() {
  group('List Validators', () {
    group('UniqueItemsValidator', () {
      test('Unique list passes validation', () {
        final validator = UniqueItemsListValidator<int>();
        expect(validator.isValid([1, 2, 3]), isTrue);
      });

      test('Empty list passes validation', () {
        final validator = UniqueItemsListValidator<int>();
        expect(validator.isValid([]), isTrue);
      });

      test('Singleton list passes validation', () {
        final validator = UniqueItemsListValidator<int>();
        expect(validator.isValid([1]), isTrue);
      });

      test('Non-unique list fails validation', () {
        final validator = UniqueItemsListValidator<int>();
        expect(validator.isValid([1, 2, 2, 3]), isFalse);
      });

      test('Non-adjacent duplicates fail validation', () {
        final validator = UniqueItemsListValidator<int>();
        expect(validator.isValid([1, 2, 1, 3]), isFalse);
      });

      test('UniqueItemsValidator returns correct error details', () {
        final validator = UniqueItemsListValidator<int>();
        final nonUniqueList = [1, 2, 2, 3];
        final error = validator.onError(nonUniqueList);
        expect(error.name, equals('list_unique_items'));
        expect(error.message, contains('List items are not unique'));
        expect(error.context, containsPair('value', nonUniqueList));
        expect(error.context, contains('notUnique'));
        // Depending on the intended behavior of _notUnique,
        // we expect the duplicate items to be identified.
        final duplicates = error.context['notUnique'] as List<int>;
        expect(duplicates, isNotEmpty,
            reason: 'Expected non-empty list of duplicate items');
      });

      test('Schema validation works with uniqueItems', () {
        final schema = ListSchema(IntegerSchema()).uniqueItems();
        expect(schema.validate([1, 2, 3]).isOk, isTrue);

        final result = schema.validate([1, 2, 2, 3]);
        expect(result.isFail, isTrue);
        expect(result, hasOneConstraintError('list_unique_items'));
      });
    });

    group('MinItemsValidator', () {
      test('List with length >= min passes validation', () {
        final validator = MinItemsListValidator<int>(3);
        expect(validator.isValid([1, 2, 3]), isTrue);
        expect(validator.isValid([1, 2, 3, 4]), isTrue);
      });

      test('List with exactly min items passes validation', () {
        final validator = MinItemsListValidator<int>(3);
        expect(validator.isValid([1, 2, 3]), isTrue);
      });

      test('List with length < min fails validation', () {
        final validator = MinItemsListValidator<int>(3);
        expect(validator.isValid([1, 2]), isFalse);
      });

      test('Empty list fails validation for minItems', () {
        final validator = MinItemsListValidator<int>(1);
        expect(validator.isValid([]), isFalse);
      });

      test('MinItemsValidator returns correct error details', () {
        final validator = MinItemsListValidator<int>(3);
        final list = [1, 2];
        final error = validator.onError(list);
        expect(error.name, equals('list_min_items'));
        expect(error.message,
            contains('less than the minimum required length: 3'));
        expect(error.context, containsPair('value', list));
        expect(error.context, containsPair('min', 3));
      });

      test('Schema validation works with minItems', () {
        final schema = ListSchema(IntegerSchema()).minItems(3);
        expect(schema.validate([1, 2, 3]).isOk, isTrue);

        final result = schema.validate([1, 2]);
        expect(result.isFail, isTrue);
        expect(result, hasOneConstraintError('list_min_items'));
      });
    });

    group('MaxItemsValidator', () {
      test('List with length <= max passes validation', () {
        final validator = MaxItemsListValidator<int>(3);
        expect(validator.isValid([]), isTrue);
        expect(validator.isValid([1, 2]), isTrue);
        expect(validator.isValid([1, 2, 3]), isTrue);
      });

      test('List with exactly max items passes validation', () {
        final validator = MaxItemsListValidator<int>(3);
        expect(validator.isValid([1, 2, 3]), isTrue);
      });

      test('List with length > max fails validation', () {
        final validator = MaxItemsListValidator<int>(3);
        expect(validator.isValid([1, 2, 3, 4]), isFalse);
      });

      test('MaxItemsValidator returns correct error details', () {
        final validator = MaxItemsListValidator<int>(3);
        final list = [1, 2, 3, 4];
        final error = validator.onError(list);
        expect(error.name, equals('list_max_items'));
        expect(error.message,
            contains('greater than the maximum required length: 3'));
        expect(error.context, containsPair('value', list));
        expect(error.context, containsPair('max', 3));
      });

      test('Schema validation works with maxItems', () {
        final schema = ListSchema(IntegerSchema()).maxItems(3);
        expect(schema.validate([1, 2, 3]).isOk, isTrue);

        final result = schema.validate([1, 2, 3, 4]);
        expect(result, hasOneConstraintError('list_max_items'));
      });
    });
  });
}
