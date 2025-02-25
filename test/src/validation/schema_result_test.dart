import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaResult', () {
    test('Ok result provides correct value access', () {
      final result = SchemaResult.ok('test');
      expect(result.isOk, isTrue);
      expect(result.isFail, isFalse);

      result.match(
        onOk: (value) => expect(value.getOrNull(), 'test'),
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
}
