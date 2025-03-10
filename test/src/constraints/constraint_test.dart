import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('ConstraintValidator', () {
    test('toMap() returns name and description', () {
      final validator = StringNotEmptyValidator();
      final map = validator.toMap();

      expect(map, {
        'constraintKey': 'string_not_empty',
        'description': 'String cannot be empty',
      });
    });

    test('toString() returns JSON representation', () {
      final validator = StringNotEmptyValidator();
      expect(
        validator.toString(),
        contains('not_empty'),
      );
      expect(
        validator.toString(),
        contains('String cannot be empty'),
      );
    });
  });
}
