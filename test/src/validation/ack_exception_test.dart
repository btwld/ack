import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('AckException', () {
    test('toMap() returns list of error maps', () {
      final errors = [
        NonNullableValueSchemaError(),
        InvalidTypeSchemaError(
          valueType: String,
          expectedType: int,
        ),
      ];

      final exception = AckException(errors);
      final map = exception.toMap();

      expect(map['errors'], isList);
      expect(map['errors'].length, 2);
      expect(map['errors'][0]['type'], 'non_nullable_value');
      expect(map['errors'][1]['type'], 'invalid_type');
    });

    test('toString() includes error details', () {
      final exception = AckException([NonNullableValueSchemaError()]);
      expect(
        exception.toString(),
        contains('AckException:'),
      );
      expect(
        exception.toString(),
        contains('non_nullable_value'),
      );
    });
  });
}
