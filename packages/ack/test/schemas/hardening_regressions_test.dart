import 'package:ack/ack.dart';
import 'package:ack/src/constraints/validators.dart';
import 'package:test/test.dart';

void main() {
  group('1.0 hardening regressions', () {
    test('object safeParse fails (does not throw) on non-string map keys', () {
      final schema = Ack.object({'name': Ack.string()});

      final result = schema.safeParse({1: 'x'});

      expect(result.isFail, isTrue);
      final error = result.getError();
      expect(error, isA<SchemaValidationError>());
      expect(error.message, contains('Object keys must be strings'));
    });

    test(
      'discriminated safeParse fails (does not throw) on non-string map keys',
      () {
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({
              'type': Ack.literal('cat'),
              'name': Ack.string(),
            }),
          },
        );

        final result = schema.safeParse({1: 'cat'});

        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(error, isA<SchemaValidationError>());
        expect(error.message, contains('Object keys must be strings'));
      },
    );

    test('discriminator errors distinguish missing and null discriminator', () {
      final schema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'cat': Ack.object({'type': Ack.literal('cat'), 'name': Ack.string()}),
        },
      );

      final missing = schema.safeParse({'name': 'Milo'});
      expect(missing.isFail, isTrue);
      final missingError = missing.getError() as SchemaConstraintsError;
      expect(
        missingError.getConstraint<ObjectRequiredPropertiesConstraint>(),
        isNotNull,
      );

      final nullValue = schema.safeParse({'type': null, 'name': 'Milo'});
      expect(nullValue.isFail, isTrue);
      final nullError = nullValue.getError() as SchemaConstraintsError;
      expect(nullError.getConstraint<InvalidTypeConstraint>(), isNotNull);
      expect(nullError.message, contains('Expected String, but got null'));
    });

    test('schema errors redact raw string values in toString and toMap', () {
      const secret = 'secret-value';
      final result = Ack.string().email().safeParse(secret);

      expect(result.isFail, isTrue);
      final error = result.getError();
      final serialized = error.toMap();

      expect(error.toString(), isNot(contains(secret)));
      expect(error.message, isNot(contains(secret)));
      expect(serialized.containsKey('value'), isFalse);
      expect(serialized['valueType'], equals('String'));

      final constraints =
          (serialized['constraintViolations'] as List<Object?>?) ??
          const <Object?>[];
      if (constraints.isNotEmpty) {
        final firstConstraint = constraints.first as Map<String, Object?>;
        final context =
            (firstConstraint['context'] as Map<String, Object?>?) ??
            const <String, Object?>{};
        expect(context.containsKey('inputValue'), isFalse);
        expect(context.containsKey('stringValue'), isFalse);
      }
    });

    test('validation depth guard fails safely beyond 64 levels', () {
      AckSchema<Map<String, Object?>> schema = Ack.object({
        'leaf': Ack.string(),
      });
      Object? payload = {'leaf': 'ok'};

      for (var i = 0; i < 70; i++) {
        schema = Ack.object({'next': schema});
        payload = {'next': payload};
      }

      final result = schema.safeParse(payload);

      expect(result.isFail, isTrue);

      var nested = result.getError();
      while (nested is SchemaNestedError && nested.errors.isNotEmpty) {
        nested = nested.errors.first;
      }

      expect(nested, isA<SchemaValidationError>());
      expect(
        (nested as SchemaValidationError).message,
        contains('Maximum validation depth of 64 exceeded'),
      );
    });
  });
}
