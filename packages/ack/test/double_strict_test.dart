import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Ack.double() strict policy (M11 / A1)', () {
    group('parse', () {
      test('accepts only double values', () {
        final schema = Ack.double();
        expect(schema.safeParse(42.0).isOk, isTrue);
      });

      test('rejects int — no implicit int → double coercion', () {
        final schema = Ack.double();
        final result = schema.safeParse(42);
        expect(
          result.isFail,
          isTrue,
          reason: 'A1: int → double conversion must be explicit (codec)',
        );
      });

      test('rejects numeric string — no implicit string → double coercion', () {
        final schema = Ack.double();
        final result = schema.safeParse('42.0');
        expect(
          result.isFail,
          isTrue,
          reason: 'A1: string → double conversion must be explicit (codec)',
        );
      });

      test('rejects non-numeric string', () {
        expect(Ack.double().safeParse('not-a-number').isFail, isTrue);
      });

      // (C4) strictParsing(...) / strictPrimitiveParsing were removed in
      // 1.0.0-beta.12 — primitive schemas are strict by definition, so the
      // toggle was dead API. No toggle test needed.
    });

    group('encode', () {
      test('accepts only double runtime values', () {
        expect(Ack.double().safeEncode(42.0).isOk, isTrue);
      });

      test('rejects int runtime values', () {
        final result = Ack.double().safeEncode(42);
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaEncodeError>());
      });

      test('rejects string runtime values', () {
        final result = Ack.double().safeEncode('42.0');
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaEncodeError>());
      });
    });

    group('JSON Schema', () {
      test('JSON Schema type stays "number"', () {
        // The boundary representation in JSON is still `number`. A1 affects
        // runtime/parse strictness, not the JSON Schema export.
        expect(Ack.double().toJsonSchema()['type'], equals('number'));
      });
    });

    group('all primitives are strict (C3)', () {
      test(
        'Ack.integer() is now strict — no coercion from string or double',
        () {
          // C3 completed the primitive strictness sweep. `Ack.integer()` no
          // longer accepts boundary strings or doubles; build a codec with
          // `Ack.codec(...)` for explicit conversion (see
          // test/migration_recipes_test.dart).
          expect(Ack.integer().safeParse('42').isFail, isTrue);
          expect(Ack.integer().safeParse(42.0).isFail, isTrue);
          expect(Ack.integer().safeParse(42).isOk, isTrue);
        },
      );
    });
  });
}
