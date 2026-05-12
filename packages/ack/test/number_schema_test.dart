import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Ack.number() — non-strict numeric primitive', () {
    group('parse', () {
      test('accepts int', () {
        expect(Ack.number().safeParse(42).isOk, isTrue);
      });

      test('accepts double', () {
        expect(Ack.number().safeParse(42.5).isOk, isTrue);
      });

      test('accepts double "whole" values like 0.0 and -1.0', () {
        expect(Ack.number().safeParse(0.0).isOk, isTrue);
        expect(Ack.number().safeParse(-1.0).isOk, isTrue);
      });

      test('rejects numeric strings — conversion is codec-only', () {
        expect(Ack.number().safeParse('42').isFail, isTrue);
        expect(Ack.number().safeParse('42.5').isFail, isTrue);
      });

      test('rejects non-numeric strings', () {
        expect(Ack.number().safeParse('not-a-number').isFail, isTrue);
      });

      test('rejects booleans (Dart bool is not num)', () {
        expect(Ack.number().safeParse(true).isFail, isTrue);
        expect(Ack.number().safeParse(false).isFail, isTrue);
      });

      test('rejects maps and lists', () {
        expect(Ack.number().safeParse(<String, Object?>{}).isFail, isTrue);
        expect(Ack.number().safeParse(<Object?>[]).isFail, isTrue);
      });

      test('rejects null on non-nullable schema', () {
        expect(Ack.number().safeParse(null).isFail, isTrue);
      });
    });

    group('encode', () {
      test('accepts int runtime values', () {
        expect(Ack.number().safeEncode(42).isOk, isTrue);
      });

      test('accepts double runtime values', () {
        expect(Ack.number().safeEncode(42.5).isOk, isTrue);
      });

      test('rejects string runtime values', () {
        final result = Ack.number().safeEncode('42');
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaEncodeError>());
      });

      test('rejects bool runtime values', () {
        final result = Ack.number().safeEncode(true);
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaEncodeError>());
      });
    });

    group('nullable', () {
      test('.nullable().safeParse(null) is ok', () {
        expect(Ack.number().nullable().safeParse(null).isOk, isTrue);
      });

      test('.nullable() still accepts both int and double', () {
        final schema = Ack.number().nullable();
        expect(schema.safeParse(1).isOk, isTrue);
        expect(schema.safeParse(1.5).isOk, isTrue);
      });

      test('.nullable() still rejects strings', () {
        expect(Ack.number().nullable().safeParse('1').isFail, isTrue);
      });
    });

    group('JSON Schema', () {
      test('emits type "number"', () {
        expect(Ack.number().toJsonSchema()['type'], equals('number'));
      });

      test('.nullable() wraps in anyOf with {"type":"null"}', () {
        final json = Ack.number().nullable().toJsonSchema();
        final anyOf = json['anyOf'];
        expect(anyOf, isA<List>());
        final nullBranch = (anyOf as List).whereType<Map>().any(
          (entry) => entry['type'] == 'null',
        );
        expect(nullBranch, isTrue);
      });

      test(
        'round-trips through toJsonSchemaModel as JsonSchemaType.number',
        () {
          final model = Ack.number().toJsonSchemaModel();
          expect(model.type, equals(JsonSchemaType.number));
        },
      );
    });

    group('constraints', () {
      test('min/max accept both int and double inside range', () {
        final schema = Ack.number().min(0).max(100);
        expect(schema.safeParse(50).isOk, isTrue);
        expect(schema.safeParse(50.5).isOk, isTrue);
        expect(schema.safeParse(0).isOk, isTrue);
        expect(schema.safeParse(100).isOk, isTrue);
      });

      test('min/max reject out-of-range values regardless of subtype', () {
        final schema = Ack.number().min(0).max(100);
        expect(schema.safeParse(-1).isFail, isTrue);
        expect(schema.safeParse(101).isFail, isTrue);
        expect(schema.safeParse(100.5).isFail, isTrue);
      });

      test('positive() rejects zero and negative values', () {
        final schema = Ack.number().positive();
        expect(schema.safeParse(1).isOk, isTrue);
        expect(schema.safeParse(0.1).isOk, isTrue);
        expect(schema.safeParse(0).isFail, isTrue);
        expect(schema.safeParse(-1).isFail, isTrue);
      });

      test('negative() rejects zero and positive values', () {
        final schema = Ack.number().negative();
        expect(schema.safeParse(-1).isOk, isTrue);
        expect(schema.safeParse(-0.5).isOk, isTrue);
        expect(schema.safeParse(0).isFail, isTrue);
        expect(schema.safeParse(1).isFail, isTrue);
      });

      test('multipleOf accepts integer and double multiples', () {
        final schema = Ack.number().multipleOf(0.5);
        expect(schema.safeParse(1.5).isOk, isTrue);
        expect(schema.safeParse(2).isOk, isTrue);
        expect(schema.safeParse(1.4).isFail, isTrue);
      });

      test('greaterThan/lessThan exclusive bounds', () {
        final schema = Ack.number().greaterThan(0).lessThan(10);
        expect(schema.safeParse(0).isFail, isTrue);
        expect(schema.safeParse(10).isFail, isTrue);
        expect(schema.safeParse(0.0001).isOk, isTrue);
        expect(schema.safeParse(9).isOk, isTrue);
      });
    });

    group('equality', () {
      test('two const NumberSchemas are equal', () {
        expect(const NumberSchema(), equals(const NumberSchema()));
      });

      test('nullable variants differ from non-nullable', () {
        expect(Ack.number().nullable() == Ack.number(), isFalse);
      });

      test('NumberSchema is not equal to DoubleSchema or IntegerSchema', () {
        // ignore: unrelated_type_equality_checks
        expect(Ack.number() == Ack.double(), isFalse);
        // ignore: unrelated_type_equality_checks
        expect(Ack.number() == Ack.integer(), isFalse);
      });
    });

    group('does not affect strict siblings', () {
      test('Ack.integer() still rejects doubles', () {
        expect(
          Ack.integer().safeParse(42.0).isFail,
          isTrue,
          reason: 'Adding Ack.number() must not widen Ack.integer() strictness',
        );
      });

      test('Ack.double() still rejects ints', () {
        expect(
          Ack.double().safeParse(42).isFail,
          isTrue,
          reason: 'Adding Ack.number() must not widen Ack.double() strictness',
        );
      });
    });
  });
}
