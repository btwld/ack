import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Ack', () {
    group('nullable()', () {
      test('makes schema nullable', () {
        final schema = Ack.string.nullable();
        expect(schema.validate(null).isOk, isTrue);
      });
    });

    group('validateOrThrow()', () {
      test('throws AckException on invalid input', () {
        final schema = Ack.string.strict();
        expect(
          () => schema.validateOrThrow(42),
          throwsA(isA<AckException>()),
        );
      });

      test('does not throw on valid input', () {
        final schema = Ack.string;
        expect(() => schema.validateOrThrow("test"), returnsNormally);
      });
    });

    group('list', () {
      test('creates list schema of base type', () {
        final listSchema = Ack.list(Ack.string);
        expect(listSchema.validate(['a', 'b', 'c']).isOk, isTrue);
        expect(listSchema.validate([1, 2, 3]).isOk, isTrue);
      });

      test('handles non-string values based on strict mode', () {
        final listSchema = Ack.list(Ack.string);

        final strictListSchema = Ack.list(Ack.string.strict());

        final result = strictListSchema.validate([1, 2, 3]);

        expect(
          result.isFail,
          isTrue,
          reason: 'strict mode should fail on non-string values',
        );

        expect(
          listSchema.validate([1, 2, 3]).isOk,
          isTrue,
          reason: 'non-strict mode should pass on non-string values',
        );
      });
    });

    group('discriminated()', () {
      test('validates discriminated objects', () {
        final schema = Ack.discriminated(
          discriminatorKey: 'key',
          schemas: {
            'user': Ack.object(
              {
                'key': Ack.string,
                'name': Ack.string,
              },
              required: ['key'],
            ),
            'admin': Ack.object(
              {
                'key': Ack.string,
                'name': Ack.string,
                'level': Ack.int,
              },
              required: ['key'],
            ),
          },
        );

        expect(
          schema.validate({
            'key': 'user',
            'name': 'John',
          }).isOk,
          isTrue,
          reason: 'Should validate a valid user object',
        );

        expect(
          schema.validate({
            'key': 'admin',
            'name': 'Admin',
            'level': 1,
          }).isOk,
          isTrue,
          reason: 'Should validate a valid admin object',
        );

        expect(
          schema.validate({
            'key': 'unknown',
            'name': 'Test',
          }).isFail,
          isTrue,
          reason: 'Should fail for unknown discriminator value',
        );
      });
    });

    group('object()', () {
      test('validates object structure', () {
        final schema = Ack.object(
          {
            'name': Ack.string,
            'age': Ack.int,
          },
          required: ['name'],
        );

        expect(
          schema.validate({
            'name': 'John',
            'age': 30,
          }).isOk,
          isTrue,
        );

        expect(
          schema.validate({
            'age': 30,
          }).isFail,
          isTrue,
        );
      });
    });

    group('enumString()', () {
      test('validates string enum values', () {
        final schema = Ack.enumString(['red', 'green', 'blue']);

        expect(schema.validate('red').isOk, isTrue,
            reason: 'Should validate a valid string enum value');
        expect(schema.validate('yellow').isFail, isTrue,
            reason: 'Should fail for invalid string enum value');
      });
    });

    group('primitive types', () {
      test('validates string type', () {
        expect(Ack.string.validate('test').isOk, isTrue);
        expect(Ack.string.validate(42).isOk, isTrue);

        final strict = Ack.string.strict();
        expect(strict.validate('test').isOk, isTrue);
        expect(strict.validate(42).isFail, isTrue);
      });

      test('validates boolean type', () {
        expect(Ack.boolean.validate(true).isOk, isTrue);
        expect(Ack.boolean.validate('true').isOk, isTrue);

        final strict = Ack.boolean.strict();
        expect(strict.validate(true).isOk, isTrue);
        expect(strict.validate('true').isFail, isTrue);
      });

      test('validates int type', () {
        expect(Ack.int.validate(42).isOk, isTrue);
        expect(Ack.int.validate(42.5).isOk, isTrue);

        final strict = Ack.int.strict();
        expect(strict.validate(42).isOk, isTrue);
        expect(strict.validate(42.5).isFail, isTrue);
        expect(strict.validate('42').isFail, isTrue);
      });

      test('validates double type', () {
        expect(Ack.double.validate(42.5).isOk, isTrue);
        expect(Ack.double.validate('42.5').isOk, isTrue);

        final strict = Ack.double.strict();
        expect(strict.validate(42.5).isOk, isTrue);
        expect(strict.validate('42.5').isFail, isTrue);
      });
    });
  });
}
