import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('custom coercion codecs', () {
    test('primitive schemas do not coerce boundary values', () {
      expect(Ack.integer().safeParse('42').isFail, isTrue);
      expect(Ack.double().safeParse('42.5').isFail, isTrue);
      expect(Ack.boolean().safeParse('true').isFail, isTrue);
      expect(Ack.string().safeParse(42).isFail, isTrue);
    });

    test('int string codec parses and encodes integer strings', () {
      final schema = Ack.codec<String, int>(
        Ack.string(),
        Ack.instance<int>(),
        decode: int.parse,
        encode: (i) => i.toString(),
      );

      expect(schema.parse('42'), equals(42));
      expect(schema.encode(42), equals('42'));
      expect(schema.safeParse('4.2').isFail, isTrue);
    });

    test('double string codec parses and encodes decimal strings', () {
      final schema = Ack.codec<String, double>(
        Ack.string(),
        Ack.instance<double>(),
        decode: double.parse,
        encode: (d) => d.toString(),
      );

      expect(schema.parse('42.5'), equals(42.5));
      expect(schema.encode(42.5), equals('42.5'));
      expect(schema.safeParse('not-a-number').isFail, isTrue);
    });

    test('bool string codec parses and encodes lowercase bool strings', () {
      final schema = Ack.codec<String, bool>(
        Ack.string().matches(r'^(?:true|false)$'),
        Ack.instance<bool>(),
        decode: bool.parse,
        encode: (b) => b.toString(),
      );

      expect(schema.parse('true'), isTrue);
      expect(schema.parse('false'), isFalse);
      expect(schema.encode(true), equals('true'));
      expect(schema.safeParse('TRUE').isFail, isTrue);
      expect(schema.safeParse('yes').isFail, isTrue);
    });
  });
}
