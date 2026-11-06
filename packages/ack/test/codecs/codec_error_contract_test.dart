import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('codec decoder error contract', () {
    test('parse and safeParse propagate the original programmer error', () {
      final error = StateError('decoder defect');
      final schema = Ack.string().codec<int>(
        decode: (_) => throw error,
        encode: (value) => value.toString(),
      );

      expect(() => schema.safeParse('7'), throwsA(same(error)));
      expect(() => schema.parse('7'), throwsA(same(error)));
    });

    test('nested objects, lists, and maps preserve decoder errors', () {
      final error = StateError('nested decoder defect');
      final schema = Ack.string().codec<int>(
        decode: (_) => throw error,
        encode: (value) => value.toString(),
      );

      expect(
        () => Ack.object({'value': schema}).safeParse({'value': '7'}),
        throwsA(same(error)),
      );
      expect(() => Ack.list(schema).safeParse(['7']), throwsA(same(error)));
      expect(
        () => Ack.map(schema).safeParse({'value': '7'}),
        throwsA(same(error)),
      );
    });

    test('one-way transforms preserve programmer errors too', () {
      final error = StateError('transform defect');
      final schema = Ack.string().transform<int>((_) => throw error);

      expect(() => schema.safeParse('7'), throwsA(same(error)));
    });

    test('anyOf does not hide a decoder error with a later branch', () {
      final error = StateError('first branch defect');
      var fallbackCalled = false;
      final broken = Ack.string().codec<int>(
        decode: (_) => throw error,
        encode: (value) => value.toString(),
      );
      final fallback = Ack.string().refine((_) {
        fallbackCalled = true;
        return true;
      });

      expect(
        () => Ack.anyOf([broken, fallback]).safeParse('7'),
        throwsA(same(error)),
      );
      expect(fallbackCalled, isFalse);
    });

    test('recoverable decoder exceptions remain transform failures', () {
      const exception = FormatException('not an integer');
      final schema = Ack.string().codec<int>(
        decode: (_) => throw exception,
        encode: (value) => value.toString(),
      );

      final result = schema.safeParse('bad');

      expect(result.isFail, isTrue);
      expect(
        result.getError(),
        isA<SchemaTransformError>().having(
          (error) => error.cause,
          'cause',
          same(exception),
        ),
      );
    });

    test('anyOf can still recover from a decoder exception', () {
      final schema = Ack.string().codec<int>(
        decode: (_) => throw const FormatException('not an integer'),
        encode: (value) => value.toString(),
      );

      expect(Ack.anyOf([schema, Ack.string()]).parse('text'), 'text');
    });

    test('decoder errors retain their original stack trace', () {
      final error = StateError('decoder defect');
      final originalStack = StackTrace.fromString('original decoder stack');
      final schema = Ack.string().codec<int>(
        decode: (_) => Error.throwWithStackTrace(error, originalStack),
        encode: (value) => value.toString(),
      );
      Object? caughtError;
      StackTrace? caughtStack;

      try {
        schema.safeParse('7');
      } catch (error, stackTrace) {
        caughtError = error;
        caughtStack = stackTrace;
      }

      expect(caughtError, same(error));
      expect(caughtStack.toString(), originalStack.toString());
    });
  });
}
