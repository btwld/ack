import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaEncodeError', () {
    SchemaContext makeCtx({String name = 'root', Object? value}) {
      return SchemaContext(
        name: name,
        schema: Ack.string(),
        value: value,
        operation: SchemaOperation.encode,
      );
    }

    group('.typeMismatch', () {
      test('produces a clear message naming actual and expected types', () {
        final ctx = makeCtx(value: 42);
        final error = SchemaEncodeError.typeMismatch(
          actual: 42,
          expected: String,
          context: ctx,
        );

        expect(error, isA<SchemaError>());
        expect(error.message.toLowerCase(), contains('encode'));
        expect(error.message.toLowerCase(), contains('string'));
        expect(error.message, contains('int'));
      });

      test('preserves path on nested context', () {
        final root = makeCtx();
        final child = root.createChild(
          name: 'name',
          schema: Ack.string(),
          value: 5,
          pathSegment: 'name',
        );

        final error = SchemaEncodeError.typeMismatch(
          actual: 5,
          expected: String,
          context: child,
        );

        expect(error.path, equals('#/name'));
      });

      test('does not throw when constructing for non-JSON runtime types '
          '(DateTime, Uri, user classes)', () {
        // Regression: the previous form went through SchemaType.of() which
        // throws ArgumentError for any value outside the JSON primitives,
        // making safeEncode(...) throw mid-error-construction.
        expect(
          () => SchemaEncodeError.typeMismatch(
            actual: DateTime.utc(2025, 1, 1),
            expected: String,
            context: makeCtx(),
          ),
          returnsNormally,
        );
        expect(
          () => SchemaEncodeError.typeMismatch(
            actual: Uri.parse('https://example.com'),
            expected: String,
            context: makeCtx(),
          ),
          returnsNormally,
        );
      });
    });

    group('.nonNullable', () {
      test('message references encode and non-nullable', () {
        final error = SchemaEncodeError.nonNullable(context: makeCtx());
        expect(error.message.toLowerCase(), contains('null'));
        expect(error.message.toLowerCase(), contains('encode'));
      });
    });

    group('.oneWayTransform', () {
      test('message points users to Ack.codec', () {
        final error = SchemaEncodeError.oneWayTransform(context: makeCtx());
        expect(error.message, contains('Ack.codec'));
        expect(error.message.toLowerCase(), contains('one-way'));
      });
    });

    group('.encoderThrew', () {
      test('exposes the underlying cause and stack trace', () {
        final cause = StateError('boom');
        StackTrace? capturedStack;
        try {
          throw cause;
        } catch (_, st) {
          capturedStack = st;
        }

        final error = SchemaEncodeError.encoderThrew(
          cause: cause,
          stackTrace: capturedStack,
          context: makeCtx(),
        );

        expect(error.cause, same(cause));
        expect(error.stackTrace, same(capturedStack));
        expect(error.message, contains('boom'));
      });
    });

    group('.missingRequiredProperty', () {
      test('mentions the missing key', () {
        final error = SchemaEncodeError.missingRequiredProperty(
          key: 'email',
          context: makeCtx(),
        );
        expect(error.message, contains('email'));
        expect(error.message.toLowerCase(), contains('required'));
      });
    });

    group('.unexpectedProperty', () {
      test('mentions the unexpected key', () {
        final error = SchemaEncodeError.unexpectedProperty(
          key: 'extra',
          context: makeCtx(),
        );
        expect(error.message, contains('extra'));
      });
    });

    test('toMap includes path, name, schemaType, and message', () {
      final error = SchemaEncodeError.nonNullable(context: makeCtx());
      final map = error.toMap();

      expect(map['path'], equals('#'));
      expect(map['name'], equals('root'));
      expect(map['schemaType'], isNotNull);
      expect(map['message'], isA<String>());
    });
  });
}
