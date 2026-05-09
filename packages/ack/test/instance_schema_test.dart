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

    test('Ack.codec produces a one-way codec when encoder is omitted', () {
      final schema = Ack.codec<String, int>(
        input: Ack.string(),
        output: Ack.instance<int>(),
        decoder: int.parse,
      );

      final encodeResult = schema.safeEncode(42);
      expect(encodeResult.isFail, isTrue);
      expect(encodeResult.getError(), isA<SchemaEncodeError>());
    });
  });
}
