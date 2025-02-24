import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaError', () {
    test('toMap() returns correct structure', () {
      final error = InvalidTypeSchemaError(
        valueType: String,
        expectedType: int,
      );

      final map = error.toMap();

      expect(map, {
        'type': 'invalid_type',
        'message': 'Invalid type of String, expected int',
        'context': {
          'valueType': 'String',
          'expectedType': 'int',
        },
      });
    });

    test('toString() returns formatted string', () {
      final error = NonNullableValueSchemaError();
      expect(
        error.toString(),
        contains('SchemaError:'),
      );
      expect(
        error.toString(),
        contains('non_nullable_value'),
      );
    });
  });
}
