import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('AckSchema equality', () {
    test('identical StringSchema instances should be equal', () {
      final s1 = Ack.string();
      final s2 = Ack.string();
      // Currently failing because no == implementation
      expect(s1 == s2, isTrue, reason: 'Two default StringSchema should be equal');
      expect(s1.hashCode, equals(s2.hashCode));
    });

    test('StringSchema with same options should be equal', () {
      final s1 = Ack.string().nullable();
      final s2 = Ack.string().nullable();
      expect(s1 == s2, isTrue);
      expect(s1.hashCode, equals(s2.hashCode));
    });

    test('StringSchema with different options should not be equal', () {
      final s1 = Ack.string();
      final s2 = Ack.string().nullable();
      expect(s1 == s2, isFalse);
    });

    test('IntegerSchema instances should be equal', () {
      final i1 = Ack.integer();
      final i2 = Ack.integer();
      expect(i1 == i2, isTrue);
      expect(i1.hashCode, equals(i2.hashCode));
    });

    test('DoubleSchema instances should be equal', () {
      final d1 = Ack.double();
      final d2 = Ack.double();
      expect(d1 == d2, isTrue);
      expect(d1.hashCode, equals(d2.hashCode));
    });

    test('BooleanSchema instances should be equal', () {
      final b1 = Ack.boolean();
      final b2 = Ack.boolean();
      expect(b1 == b2, isTrue);
      expect(b1.hashCode, equals(b2.hashCode));
    });

    test('ListSchema with same item schema should be equal', () {
      final l1 = Ack.list(Ack.string());
      final l2 = Ack.list(Ack.string());
      expect(l1 == l2, isTrue);
      expect(l1.hashCode, equals(l2.hashCode));
    });

    test('ObjectSchema with same properties should be equal', () {
      final o1 = Ack.object({'name': Ack.string(), 'age': Ack.integer()});
      final o2 = Ack.object({'name': Ack.string(), 'age': Ack.integer()});
      expect(o1 == o2, isTrue);
      expect(o1.hashCode, equals(o2.hashCode));
    });

    test('ObjectSchema with different properties should not be equal', () {
      final o1 = Ack.object({'name': Ack.string()});
      final o2 = Ack.object({'title': Ack.string()});
      expect(o1 == o2, isFalse);
    });

    test('EnumSchema with same values should be equal', () {
      final e1 = Ack.enumValues(TestEnum.values);
      final e2 = Ack.enumValues(TestEnum.values);
      expect(e1 == e2, isTrue);
      expect(e1.hashCode, equals(e2.hashCode));
    });

    test('AnyOfSchema with same schemas should be equal', () {
      final a1 = Ack.anyOf([Ack.string(), Ack.integer()]);
      final a2 = Ack.anyOf([Ack.string(), Ack.integer()]);
      expect(a1 == a2, isTrue);
      expect(a1.hashCode, equals(a2.hashCode));
    });

    test('AnySchema instances should be equal', () {
      final a1 = Ack.any();
      final a2 = Ack.any();
      expect(a1 == a2, isTrue);
      expect(a1.hashCode, equals(a2.hashCode));
    });

    test('DiscriminatedObjectSchema with same config should be equal', () {
      final d1 = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'a': Ack.object({'name': Ack.string()}),
        },
      );
      final d2 = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'a': Ack.object({'name': Ack.string()}),
        },
      );
      expect(d1 == d2, isTrue);
      expect(d1.hashCode, equals(d2.hashCode));
    });

    test('schemas can be used as Set elements', () {
      final set = <AckSchema>{Ack.string(), Ack.integer()};
      expect(set.contains(Ack.string()), isTrue);
      expect(set.contains(Ack.integer()), isTrue);
    });

    test('schemas can be used as Map keys', () {
      final map = <AckSchema, String>{
        Ack.string(): 'string',
        Ack.integer(): 'integer',
      };
      expect(map[Ack.string()], equals('string'));
      expect(map[Ack.integer()], equals('integer'));
    });
  });
}

enum TestEnum { a, b, c }
