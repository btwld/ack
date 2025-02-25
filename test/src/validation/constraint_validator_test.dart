import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('ConstraintValidator', () {
    test('toMap() returns name and description', () {
      final validator = NotEmptyStringValidator();
      final map = validator.toMap();

      expect(map, {
        'name': 'string_not_empty',
        'description': 'String cannot be empty',
      });
    });

    test('toString() returns JSON representation', () {
      final validator = NotEmptyStringValidator();
      expect(
        validator.toString(),
        contains('string_not_empty'),
      );
      expect(
        validator.toString(),
        contains('String cannot be empty'),
      );
    });
  });
}
