import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Base encode — primitives', () {
    test('accepts matching runtime values unchanged', () {
      expect(Ack.string().encode('hello'), equals('hello'));
      expect(Ack.integer().encode(42), equals(42));
      expect(Ack.boolean().encode(true), equals(true));
      expect(Ack.double().encode(1.5), equals(1.5));
    });

    test('rejects coercion-friendly mismatches (does not parse)', () {
      final result = Ack.integer().safeEncode('42');
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('refine runs during encode', () {
      final schema = Ack.string().refine(
        (s) => s.length >= 3,
        message: 'too short',
      );

      expect(schema.encode('long enough'), equals('long enough'));

      final fail = schema.safeEncode('xx');
      expect(fail.isFail, isTrue);
    });
  });

  group('Base encode — null and optional/nullable semantics', () {
    test('nullable schema accepts null', () {
      final schema = Ack.string().nullable();
      expect(schema.encode(null), isNull);
    });

    test('non-nullable schema rejects null', () {
      final result = Ack.string().safeEncode(null);
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('optional alone does not accept null', () {
      final schema = Ack.string().optional();
      final result = schema.safeEncode(null);
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('optional + nullable accepts null', () {
      final schema = Ack.string().optional().nullable();
      expect(schema.encode(null), isNull);
    });
  });

  group('Base encode — defaults are forward-only', () {
    test('default value never substitutes for null on encode', () {
      final schema = Ack.string().withDefault('FALLBACK');
      // Parse uses the default.
      expect(schema.parse(null), equals('FALLBACK'));
      // Encode does not — null on a non-nullable schema fails.
      final result = schema.safeEncode(null);
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test(
      'nullable after default accepts null on encode without substituting',
      () {
        final schema = Ack.string().withDefault('FALLBACK').nullable();

        expect(schema.parse(null), equals('FALLBACK'));
        expect(schema.encode(null), isNull);
      },
    );
  });
}
