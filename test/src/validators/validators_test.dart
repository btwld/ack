import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('MinItemsListValidator', () {
    test('List with length >= min passes validation', () {
      final validator = ListMinItemsConstraint(3);
      expect(validator.isValid([1, 2, 3]), isTrue);
      expect(validator.isValid([1, 2, 3, 4]), isTrue);
    });

    test('List with length < min fails validation', () {
      final validator = ListMinItemsConstraint(3);
      expect(validator.isValid([1, 2]), isFalse);
    });

    test('schema validation works with minItems', () {
      final schema = ListSchema(IntegerSchema()).minItems(3);
      expect(schema.validate([1, 2, 3]).isOk, isTrue);

      final result = schema.validate([1, 2]);
      expect(result.isFail, isTrue);

      final error = (result as Fail).error;
      expect(error, isA<SchemaConstraintsError>());

      final constraintsError = error as SchemaConstraintsError;
      expect(
        constraintsError.constraints
            .any((e) => e.constraintKey == 'list_min_items'),
        isTrue,
      );
    });

    test('error message is correct', () {
      final validator = ListMinItemsConstraint(3);
      final message = validator.buildMessage([1, 2]);
      expect(
        message,
        'Too few items, min 3. Got 2',
      );
    });
  });
}
