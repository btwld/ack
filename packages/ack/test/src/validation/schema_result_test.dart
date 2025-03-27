import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaResult', () {
    test('Ok result provides correct value access', () {
      final result = SchemaResult.ok('test');
      expect(result.isOk, isTrue);
      expect(result.isFail, isFalse);

      result.match(
        onOk: (value) => expect(value, 'test'),
        onFail: (_) => fail('Should not fail'),
      );

      expect(result.getOrNull(), 'test');
      expect(result.getOrElse(() => 'default'), 'test');
      expect(result.getOrThrow(), 'test');

      var okCalled = false;
      result.onOk((_) => okCalled = true);
      expect(okCalled, isTrue);

      result.onFail((_) => fail('Should not call onFail'));
    });

    test('Ok result with null value', () {
      final result = SchemaResult.unit<String>();
      expect(result.getOrNull(), isNull);
      expect(result.getOrElse(() => 'default'), 'default');
      expect(() => result.getOrThrow(), throwsA(isA<Exception>()));
    });

    test('Fail result provides error access', () {
      final schemaError = SchemaMockError();

      final result = SchemaResult.fail(schemaError);

      expect(result.isOk, isFalse);
      expect(result.isFail, isTrue);

      result.match(
        onOk: (_) => fail('Should not succeed'),
        onFail: (error) => expect(error, schemaError),
      );

      expect(result.getError(), schemaError);
      expect(result.getOrNull(), isNull);
      expect(result.getOrElse(() => 'default'), 'default');
      expect(() => result.getOrThrow(), throwsA(isA<AckException>()));

      var failCalled = false;
      result.onFail((_) => failCalled = true);
      expect(failCalled, isTrue);

      result.onOk((_) => fail('Should not call onOk'));
    });

    test('getErrors throws on Ok result', () {
      final result = SchemaResult.ok('test');
      expect(
        () => result.getError(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
