import 'package:ack/ack.dart';
import 'package:test/test.dart';

enum _Color { red, green, blue }

void main() {
  group('ObjectSchema encode', () {
    test('encodes nested codec field', () {
      final schema = Ack.object({
        'name': Ack.string(),
        'startsAt': Ack.datetime(),
      });
      final dt = DateTime.utc(2026, 5, 4, 10);
      final encoded = schema.encode({'name': 'Launch', 'startsAt': dt})
          as Map<String, Object?>;
      expect(encoded['name'], equals('Launch'));
      expect(encoded['startsAt'], equals('2026-05-04T10:00:00.000Z'));
    });

    test('omits missing optional field', () {
      final schema = Ack.object({
        'a': Ack.string(),
        'b': Ack.string().optional(),
      });
      final encoded = schema.encode({'a': 'x'}) as Map<String, Object?>;
      expect(encoded.containsKey('b'), isFalse);
    });

    test('fails on missing required field', () {
      final schema = Ack.object({
        'a': Ack.string(),
        'b': Ack.string(),
      });
      final result = schema.safeEncode({'a': 'x'});
      expect(result.isFail, isTrue);
    });

    test('does not synthesize default during encode', () {
      final schema = Ack.object({
        'a': Ack.string().withDefault('FALLBACK'),
      });
      final result = schema.safeEncode(<String, Object?>{});
      expect(result.isFail, isTrue);
    });

    test('rejects additional properties when not allowed', () {
      final schema = Ack.object({'a': Ack.string()});
      final result = schema.safeEncode({'a': 'x', 'b': 'y'});
      expect(result.isFail, isTrue);
    });

    test('passes through additional properties when allowed', () {
      final schema = Ack.object(
        {'a': Ack.string()},
        additionalProperties: true,
      );
      final encoded = schema.encode({'a': 'x', 'b': 'y'})
          as Map<String, Object?>;
      expect(encoded['b'], equals('y'));
    });

    test('preserves nested error path', () {
      final schema = Ack.object({
        'count': Ack.string().transform<int>(int.parse),
      });
      final result = schema.safeEncode({'count': 42});
      expect(result.isFail, isTrue);
      final err = result.getError() as SchemaNestedError;
      expect(err.errors.first.path, equals('#/count'));
    });

    test('object-level refine runs during encode', () {
      final schema = Ack.object({
        'a': Ack.integer(),
        'b': Ack.integer(),
      }).refine(
        (m) => (m['a'] as int) < (m['b'] as int),
        message: 'a must be less than b',
      );

      expect(schema.encode({'a': 1, 'b': 2}), isA<Map<String, Object?>>());
      expect(schema.safeEncode({'a': 5, 'b': 2}).isFail, isTrue);
    });
  });

  group('ListSchema encode', () {
    test('encodes nested codec items', () {
      final schema = Ack.list(Ack.datetime());
      final dts = [
        DateTime.utc(2026, 5, 4),
        DateTime.utc(2026, 6, 1),
      ];
      final encoded = schema.encode(dts) as List<Object?>;
      expect(encoded[0], equals('2026-05-04T00:00:00.000Z'));
      expect(encoded[1], equals('2026-06-01T00:00:00.000Z'));
    });

    test('preserves index path on item failure', () {
      final schema = Ack.list(Ack.string().transform<int>(int.parse));
      final result = schema.safeEncode([1, 2, 3]);
      expect(result.isFail, isTrue);
      final err = result.getError() as SchemaNestedError;
      expect(err.errors.first.path, equals('#/0'));
    });
  });

  group('AnyOfSchema encode', () {
    test('first matching branch wins', () {
      final schema = Ack.anyOf([Ack.string(), Ack.integer()]);
      expect(schema.encode('hello'), equals('hello'));
      expect(schema.encode(42), equals(42));
    });

    test('aggregates errors when no branch matches', () {
      final schema = Ack.anyOf([Ack.string(), Ack.integer()]);
      final result = schema.safeEncode(true);
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaNestedError>());
    });

    test('nullable any-of accepts null', () {
      final schema = Ack.anyOf([Ack.string(), Ack.integer()]).nullable();
      expect(schema.encode(null), isNull);
    });
  });

  group('DiscriminatedObjectSchema encode', () {
    final schema = Ack.discriminated(
      discriminatorKey: 'type',
      schemas: {
        'cat': Ack.object({
          'type': Ack.literal('cat'),
          'name': Ack.string(),
        }),
        'dog': Ack.object({
          'type': Ack.literal('dog'),
          'name': Ack.string(),
          'breed': Ack.string(),
        }),
      },
    );

    test('Map+discriminator dispatches to matching branch', () {
      final encoded = schema.encode({'type': 'cat', 'name': 'Fluffy'})
          as Map<String, Object?>;
      expect(encoded['type'], equals('cat'));
      expect(encoded['name'], equals('Fluffy'));
    });

    test('unknown discriminator fails at discriminator path', () {
      final result = schema.safeEncode({'type': 'fish', 'name': 'Bubbles'});
      expect(result.isFail, isTrue);
      final err = result.getError();
      expect(err.path, equals('#/type'));
    });
  });

  group('EnumSchema encode', () {
    test('emits string boundary form (.name) for round-trip parity', () {
      final schema = Ack.enumValues(_Color.values);
      expect(schema.encode(_Color.red), equals('red'));
      expect(schema.encode(_Color.blue), equals('blue'));
    });

    test('round-trips through parse', () {
      final schema = Ack.enumValues(_Color.values);
      final round = schema.encode(schema.parse('green'));
      expect(round, equals('green'));
    });

    test('rejects values outside the allowed set', () {
      final schema = Ack.enumValues(_Color.values);
      final result = schema.safeEncode('not a color');
      expect(result.isFail, isTrue);
    });
  });
}
