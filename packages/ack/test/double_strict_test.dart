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
        expect(result.isFail, isTrue,
            reason: 'A1: int → double conversion must be explicit (codec)');
      });

      test('rejects numeric string — no implicit string → double coercion',
          () {
        final schema = Ack.double();
        final result = schema.safeParse('42.0');
        expect(result.isFail, isTrue,
            reason: 'A1: string → double conversion must be explicit (codec)');
      });

      test('rejects non-numeric string', () {
        expect(Ack.double().safeParse('not-a-number').isFail, isTrue);
      });

      test('strictParsing flag does not change A1 strict double policy', () {
        // strictPrimitiveParsing was historically the toggle for the int /
        // string coercions. Under A1 those coercions are gone; the flag is
        // effectively a no-op for double parsing. Both modes reject non-double.
        expect(Ack.double().strictParsing(value: false).safeParse(42).isFail,
            isTrue);
        expect(Ack.double().strictParsing(value: true).safeParse(42).isFail,
            isTrue);
      });
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
      test('Ack.integer() is now strict — no coercion from string or double',
          () {
        // C3 completed the primitive strictness sweep. `Ack.integer()` no
        // longer accepts boundary strings or doubles; build a codec with
        // `Ack.codec(...)` for explicit conversion (see
        // test/migration_recipes_test.dart).
        expect(Ack.integer().safeParse('42').isFail, isTrue);
        expect(Ack.integer().safeParse(42.0).isFail, isTrue);
        expect(Ack.integer().safeParse(42).isOk, isTrue);
      });
    });
  });
}
