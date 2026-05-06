import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('explicit coercion codecs', () {
    test('primitive schemas do not coerce boundary values', () {
      expect(Ack.integer().safeParse('42').isFail, isTrue);
      expect(Ack.double().safeParse('42.5').isFail, isTrue);
      expect(Ack.boolean().safeParse('true').isFail, isTrue);
      expect(Ack.string().safeParse(42).isFail, isTrue);
    });

    test('intFromString parses and encodes integer strings', () {
      final schema = Ack.intFromString();

      expect(schema.parse('42'), equals(42));
      expect(schema.encode(42), equals('42'));
      expect(schema.safeParse('4.2').isFail, isTrue);
    });

    test('doubleFromString parses and encodes decimal strings', () {
      final schema = Ack.doubleFromString();

      expect(schema.parse('42.5'), equals(42.5));
      expect(schema.encode(42.5), equals('42.5'));
      expect(schema.safeParse('not-a-number').isFail, isTrue);
    });

    test('boolFromString parses and encodes bool strings', () {
      final schema = Ack.boolFromString();

      expect(schema.parse('TRUE'), isTrue);
      expect(schema.parse(' false '), isFalse);
      expect(schema.encode(true), equals('true'));
      expect(schema.safeParse('yes').isFail, isTrue);
    });
  });
}
