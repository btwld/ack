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

  group('SchemaResult', () {
    test('Ok result provides correct value access', () {
      final result = SchemaResult.ok('test');
      expect(result.isOk, isTrue);
      expect(result.isFail, isFalse);

      result.match(
        onOk: (value) => expect(value, 'test'),
        onFail: (_) => fail('Should not fail'),
      );
    });

    test('Fail result provides error access', () {
      final errors = [NonNullableValueSchemaError()];
      final result = SchemaResult.fail(errors);

      expect(result.isOk, isFalse);
      expect(result.isFail, isTrue);

      result.match(
        onOk: (_) => fail('Should not succeed'),
        onFail: (resultErrors) => expect(resultErrors, errors),
      );
    });
  });

  group('ConstraintValidator', () {
    test('toMap() returns name and description', () {
      final validator = NotEmptyValidator();
      final map = validator.toMap();

      expect(map, {
        'name': 'string_not_empty',
        'description': 'String cannot be empty',
      });
    });

    test('toString() returns JSON representation', () {
      final validator = NotEmptyValidator();
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
