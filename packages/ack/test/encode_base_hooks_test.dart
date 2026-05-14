import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('AckSchema.safeEncode (M3 base hooks)', () {
    test('returns the value unchanged for matching primitive type', () {
      final schema = Ack.string();
      final result = schema.safeEncode('hello');

      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals('hello'));
    });

    test('returns the int unchanged for an integer schema', () {
      final schema = Ack.integer();
      final result = schema.safeEncode(42);

      expect(result.isOk, isTrue);
      expect(result.getOrNull(), equals(42));
    });

    test(
      'returns SchemaEncodeError.typeMismatch when runtime type is wrong',
      () {
        final schema = Ack.string();
        final result = schema.safeEncode(42);

        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(error, isA<SchemaEncodeError>());
        expect(error.message.toLowerCase(), contains('string'));
        expect(error.message, contains('int'));
      },
    );

    test('safeEncode does not throw when actual value is a non-JSON runtime '
        'type like DateTime', () {
      // Regression: previously the typeMismatch error constructor went
      // through SchemaType.of(value), which throws ArgumentError for
      // DateTime, Uri, and user classes. safeEncode promised "never throws".
      final schema = Ack.string();

      late SchemaResult<Object> result;
      expect(
        () => result = schema.safeEncode(DateTime.utc(2025, 1, 1)),
        returnsNormally,
      );

      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('error context is in encode direction', () {
      final schema = Ack.string();
      final result = schema.safeEncode(42);

      expect(result.isFail, isTrue);
      expect(
        result.getError().context.operation,
        equals(SchemaOperation.encode),
      );
    });

    test('returns Ok(null) when input is null on a nullable schema', () {
      final schema = Ack.string().nullable();
      final result = schema.safeEncode(null);

      expect(result.isOk, isTrue);
      expect(result.getOrNull(), isNull);
    });

    test('returns SchemaEncodeError.nonNullable for null on non-nullable', () {
      final schema = Ack.string();
      final result = schema.safeEncode(null);

      expect(result.isFail, isTrue);
      final error = result.getError();
      expect(error, isA<SchemaEncodeError>());
      expect(error.message.toLowerCase(), contains('null'));
    });

    test('does NOT synthesize defaultValue on encode', () {
      // Per requirements §5.5: defaults are only applied during parse,
      // never during encode. Encoding null on a non-nullable schema with a
      // default should fail with SchemaEncodeError.nonNullable, not silently
      // substitute the default.
      final schema = Ack.string().withDefault('fallback');
      final result = schema.safeEncode(null);

      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('applies constraints on encode', () {
      final schema = Ack.string().minLength(5);

      final goodResult = schema.safeEncode('hello');
      expect(goodResult.isOk, isTrue);

      final badResult = schema.safeEncode('hi');
      expect(badResult.isFail, isTrue);
      expect(badResult.getError(), isA<SchemaConstraintsError>());
    });

    test('encode() throws AckException on failure', () {
      final schema = Ack.string();
      expect(() => schema.encode(42), throwsA(isA<AckException>()));
    });

    test('encode() returns the value when valid', () {
      final schema = Ack.string();
      expect(schema.encode('ok'), equals('ok'));
    });

    test('encode() returns null for null input on nullable schema', () {
      final schema = Ack.string().nullable();
      expect(schema.encode(null), isNull);
    });
  });
}
