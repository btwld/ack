import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../../test_helpers.dart';

void main() {
  group('List Validators', () {
    group('UniqueItemsValidator', () {
      test('Unique list passes validation', () {
        final validator = UniqueItemsValidator<int>();
        expect(validator.check([1, 2, 3]), isTrue);
      });

      test('Non-unique list fails validation', () {
        final validator = UniqueItemsValidator<int>();
        expect(validator.check([1, 2, 2, 3]), isFalse);
      });

      test('schema validation works with uniqueItems', () {
        final schema = ListSchema(IntSchema()).uniqueItems();
        expect(schema.validate([1, 2, 3]).isOk, isTrue);

        expect(schema.validate([1, 2, 2, 3]).isFail, isTrue);
      });
    });

    group('MinItemsValidator', () {
      test('List with length >= min passes validation', () {
        final validator = MinItemsValidator(3);
        expect(validator.check([1, 2, 3]), isTrue);
        expect(validator.check([1, 2, 3, 4]), isTrue);
      });

      test('List with length < min fails validation', () {
        final validator = MinItemsValidator(3);
        expect(validator.check([1, 2]), isFalse);
      });

      test('schema validation works with minItems', () {
        final schema = ListSchema(IntSchema()).minItems(3);
        expect(schema.validate([1, 2, 3]).isOk, isTrue);

        final result = schema.validate([1, 2]);
        expect(result.isFail, isTrue);
        expect(result, hasOneConstraintError('list_min_items'));
      });
    });

    group('MaxItemsValidator', () {
      test('List with length <= max passes validation', () {
        final validator = MaxItemsValidator(3);
        expect(validator.check([1, 2]), isTrue);
        expect(validator.check([1, 2, 3]), isTrue);
      });

      test('List with length > max fails validation', () {
        final validator = MaxItemsValidator(3);
        expect(validator.check([1, 2, 3, 4]), isFalse);
      });

      test('schema validation works with maxItems', () {
        final schema = ListSchema(IntSchema()).maxItems(3);
        expect(schema.validate([1, 2, 3]).isOk, isTrue);

        final result = schema.validate([1, 2, 3, 4]);
        expect(result, hasOneConstraintError('list_max_items'));
      });
    });
  });
}
