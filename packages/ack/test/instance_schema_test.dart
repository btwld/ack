import 'package:ack/ack.dart';
import 'package:test/test.dart';

class _Money {
  final int cents;
  const _Money(this.cents);
}

void main() {
  group('InstanceSchema<T>', () {
    test('accepts values of the right runtime type', () {
      final schema = InstanceSchema<DateTime>();
      final dt = DateTime.utc(2025, 1, 1);

      final parseResult = schema.safeParse(dt);
      expect(parseResult.isOk, isTrue);
      expect(parseResult.getOrNull(), equals(dt));

      final encodeResult = schema.safeEncode(dt);
      expect(encodeResult.isOk, isTrue);
      expect(encodeResult.getOrNull(), equals(dt));
    });

    test('rejects values of the wrong runtime type', () {
      final schema = InstanceSchema<DateTime>();

      final parseResult = schema.safeParse('not a date');
      expect(parseResult.isFail, isTrue);

      final encodeResult = schema.safeEncode('not a date');
      expect(encodeResult.isFail, isTrue);
    });

    test(
      'parse-side type mismatch produces a parse-side error, '
      'not SchemaEncodeError',
      () {
        // Regression: InstanceSchema's parse path uses the runtime type
        // check helpers, which previously emitted SchemaEncodeError on any
        // failure regardless of the operation. Parse failures must surface
        // as parse-side errors so error consumers can branch on the class.
        final schema = InstanceSchema<DateTime>();
        final result = schema.safeParse('not a date');

        expect(result.isFail, isTrue);
        expect(
          result.getError(),
          isNot(isA<SchemaEncodeError>()),
          reason:
              'parse failures from _validateRuntime must not be reported as encode errors',
        );
        expect(
          result.getError().context.operation,
          equals(SchemaOperation.parse),
        );
      },
    );

    test(
      'parse-side null on a non-nullable schema produces a parse-side error, '
      'not SchemaEncodeError',
      () {
        final schema = InstanceSchema<DateTime>();
        final result = schema.safeParse(null);

        expect(result.isFail, isTrue);
        expect(result.getError(), isNot(isA<SchemaEncodeError>()));
      },
    );

    test('runs constraints/refinements on the runtime value', () {
      final schema = InstanceSchema<DateTime>().refine(
        (dt) => dt.isUtc,
        message: 'must be UTC',
      );

      expect(schema.safeParse(DateTime.utc(2025)).isOk, isTrue);
      expect(schema.safeParse(DateTime(2025)).isFail, isTrue);
    });

    test('works for user-defined classes', () {
      final schema = InstanceSchema<_Money>();
      final money = _Money(100);

      expect(schema.safeParse(money).getOrNull(), same(money));
      expect(schema.safeEncode(money).getOrNull(), same(money));
    });

    test('nullable() allows null', () {
      final schema = InstanceSchema<DateTime>().nullable();
      expect(schema.safeParse(null).isOk, isTrue);
      expect(schema.safeEncode(null).isOk, isTrue);
    });

    test('toJsonSchema is structurally empty (codec wrappers handle JSON)', () {
      final schema = InstanceSchema<DateTime>();
      final json = schema.toJsonSchema();
      // Should not declare a misleading type since the runtime type has no
      // direct JSON Schema form.
      expect(json['type'], isNull);
    });
  });

  group('Ack.instance / Ack.codec factories', () {
    test('Ack.instance<T>() creates an InstanceSchema<T>', () {
      final schema = Ack.instance<DateTime>();
      expect(schema, isA<InstanceSchema<DateTime>>());
    });

    test('Ack.codec wires an input schema, output schema, and converters', () {
      final schema = Ack.codec<String, int>(
        input: Ack.string(),
        output: Ack.instance<int>(),
        decoder: int.parse,
        encoder: (i) => i.toString(),
      );

      expect(schema, isA<CodecSchema<String, int>>());
      expect(schema.parse('42'), equals(42));
      expect(schema.encode(42), equals('42'));
    });

    test(
      'Ack.codec requires an encoder; one-way construction goes through '
      'CodecSchema(...) directly',
      () {
        // Public Ack.codec(...) cannot omit `encoder` — that would not type-check.
        // One-way codecs are constructed via the internal CodecSchema(...)
        // constructor (used by .transform(...) and built-ins).
        final schema = CodecSchema<String, int>(
          inputSchema: Ack.string(),
          outputSchema: Ack.instance<int>(),
          decoder: int.parse,
          // encoder: null  — implicit, one-way.
        );

        final encodeResult = schema.safeEncode(42);
        expect(encodeResult.isFail, isTrue);
        expect(encodeResult.getError(), isA<SchemaEncodeError>());
      },
    );
  });
}
