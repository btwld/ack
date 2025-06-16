import 'package:ack/src/constraints/core/comparison_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('ConstraintValidator', () {
    test('toMap() returns name and description', () {
      final validator = ComparisonConstraint.stringMinLength(1); // equivalent to notEmpty
      final map = validator.toMap();

      expect(map, {
        'constraintKey': 'string_min_length',
        'description': 'String must be at least 1 characters',
      });
    });

    test('toString() returns JSON representation', () {
      final validator = ComparisonConstraint.stringMinLength(1);
      expect(
        validator.toString(),
        contains('min_length'),
      );
      expect(
        validator.toString(),
        contains('String must be at least 1 characters'),
      );
    });
  });
}
