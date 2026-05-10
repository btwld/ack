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

    group('integer is independent', () {
      test('Ack.integer() coercion behaviour is unchanged in this milestone',
          () {
        // M11 is narrowly scoped to `Ack.double()`. Integer string coercion
        // remains as it was; future work will revisit broader primitive
        // strictness.
        expect(Ack.integer().safeParse('42').isOk, isTrue);
        expect(Ack.integer().safeParse(42.0).isOk, isTrue);
      });
    });
  });
}
