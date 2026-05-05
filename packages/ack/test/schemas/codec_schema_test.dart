import 'package:ack/ack.dart';
import 'package:test/test.dart';

enum _Status { active, inactive }

void main() {
  group('CodecSchema — same-type round trip', () {
    test('identity codec encodes and decodes unchanged', () {
      final schema = Ack.codec<String, String>(
        Ack.string(),
        Ack.string(),
        decode: (s) => s,
        encode: (s) => s,
      );
      expect(schema.parse('x'), equals('x'));
      expect(schema.encode('x'), equals('x'));
    });
  });

  group('CodecSchema — String <=> DateTime', () {
    final schema = Ack.codec<String, DateTime>(
      Ack.string().datetime(),
      Ack.instance<DateTime>(),
      decode: DateTime.parse,
      encode: (d) => d.toUtc().toIso8601String(),
    );

    test('parse decodes ISO string to DateTime', () {
      final result = schema.parse('2026-05-04T10:00:00.000Z');
      expect(result, isA<DateTime>());
      expect(result!.toUtc().year, equals(2026));
    });

    test('encode produces ISO string', () {
      final dt = DateTime.utc(2026, 5, 4, 10);
      expect(schema.encode(dt), equals('2026-05-04T10:00:00.000Z'));
    });

    test('parse → encode round-trips stably', () {
      const iso = '2026-05-04T10:00:00.000Z';
      final round = schema.encode(schema.parse(iso));
      expect(round, equals(iso));
    });
  });

  group('CodecSchema — input validation precedes decode', () {
    test('input failure prevents decode closure', () {
      var decodeCalled = false;
      final schema = Ack.codec<String, int>(
        Ack.string().minLength(3),
        Ack.instance<int>(),
        decode: (s) {
          decodeCalled = true;
          return int.parse(s);
        },
        encode: (i) => i.toString(),
      );

      final result = schema.safeParse('xx'); // fails minLength
      expect(result.isFail, isTrue);
      expect(decodeCalled, isFalse);
    });
  });

  group('CodecSchema — output validation precedes encode', () {
    test('output failure prevents encode closure', () {
      var encodeCalled = false;
      final schema = Ack.codec<String, int>(
        Ack.string(),
        Ack.instance<int>(),
        decode: int.parse,
        encode: (i) {
          encodeCalled = true;
          return i.toString();
        },
      );

      // outputSchema is InstanceSchema<int>; passing a String fails type check.
      final result = schema.safeEncode('not an int');
      expect(result.isFail, isTrue);
      expect(encodeCalled, isFalse);
    });

    test(
      'encode passes enum output schema validation before encode closure',
      () {
        final schema = Ack.codec<String, _Status>(
          Ack.string(),
          Ack.enumValues(_Status.values),
          decode: (s) => _Status.values.byName(s),
          encode: (s) => s.name,
        );

        expect(schema.encode(_Status.active), equals('active'));
      },
    );

    test('encode accepts runtime values validated by nested output codecs', () {
      final schema = Ack.codec<String, Map<String, Object?>>(
        Ack.string().datetime(),
        Ack.object({'startsAt': Ack.datetime()}),
        decode: (s) => {'startsAt': s},
        encode: (m) => (m['startsAt'] as DateTime).toUtc().toIso8601String(),
      );
      final runtimeValue = {'startsAt': DateTime.utc(2026, 5, 4, 10)};

      expect(schema.encode(runtimeValue), equals('2026-05-04T10:00:00.000Z'));
    });

    test('encode validation does not parse output-schema coercions', () {
      var encodeCalled = false;
      final schema = Ack.codec<String, Object>(
        Ack.string(),
        Ack.integer(),
        decode: int.parse,
        encode: (value) {
          encodeCalled = true;
          return value.toString();
        },
      );

      final result = schema.safeEncode('42');

      expect(result.isFail, isTrue);
      expect(encodeCalled, isFalse);
    });
  });

  group('CodecSchema — decode/encode throw wrapping', () {
    test('decode throw becomes SchemaTransformError', () {
      final schema = Ack.codec<String, int>(
        Ack.string(),
        Ack.instance<int>(),
        decode: (s) => throw Exception('boom'),
        encode: (i) => i.toString(),
      );
      final result = schema.safeParse('x');
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaTransformError>());
    });

    test('encode throw becomes SchemaEncodeError', () {
      final schema = Ack.codec<String, int>(
        Ack.string(),
        Ack.instance<int>(),
        decode: int.parse,
        encode: (i) => throw Exception('boom'),
      );
      final result = schema.safeEncode(42);
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });
  });

  group('CodecSchema — defaults are forward-only', () {
    test('default applies during parse', () {
      final schema = Ack.codec<String, int>(
        Ack.string(),
        Ack.instance<int>(),
        decode: int.parse,
        encode: (i) => i.toString(),
      ).copyWith(defaultValue: 99);

      expect(schema.parse(null), equals(99));
    });

    test('default must satisfy the output schema', () {
      final schema = Ack.codec<String, String>(
        Ack.string(),
        Ack.string().minLength(5),
        decode: (s) => s,
        encode: (s) => s,
      ).copyWith(defaultValue: 'no');

      final result = schema.safeParse(null);

      expect(result.isFail, isTrue);
    });

    test('default does NOT synthesize during encode', () {
      final schema = Ack.codec<String, int>(
        Ack.string(),
        Ack.instance<int>(),
        decode: int.parse,
        encode: (i) => i.toString(),
      ).copyWith(defaultValue: 99);

      final result = schema.safeEncode(null);
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });
  });

  group('CodecSchema — JSON Schema marker', () {
    test('emits x-transformed: true', () {
      final schema = Ack.codec<String, int>(
        Ack.string(),
        Ack.instance<int>(),
        decode: int.parse,
        encode: (i) => i.toString(),
      );
      final json = schema.toJsonSchema();
      expect(json['x-transformed'], isTrue);
    });
  });

  group('.transform(fn) — one-way encode failure', () {
    test(
      'encoding a transform fails with SchemaEncodeError mentioning Ack.codec',
      () {
        final schema = Ack.string().transform<int>(int.parse);
        final result = schema.safeEncode(42);
        expect(result.isFail, isTrue);
        final err = result.getError();
        expect(err, isA<SchemaEncodeError>());
        expect(err.message, contains('Ack.codec'));
      },
    );

    test('parse still works as before', () {
      final schema = Ack.string().transform<int>(int.parse);
      expect(schema.parse('42'), equals(42));
    });

    test('nested transform inside object preserves field path on encode', () {
      final schema = Ack.object({
        'count': Ack.string().transform<int>(int.parse),
      });
      final result = schema.safeEncode({'count': 42});
      expect(result.isFail, isTrue);
      final err = result.getError();
      // Root error is the object's nested aggregator; child carries the path.
      expect(err, isA<SchemaNestedError>());
      final nested = (err as SchemaNestedError).errors;
      expect(nested.first.path, equals('#/count'));
    });
  });

  group('Built-in codecs round-trip', () {
    test('Ack.date() round-trips boundary and runtime values', () {
      final schema = Ack.date();
      const inputs = ['2026-05-04', '1999-12-31', '2032-01-01'];

      for (final input in inputs) {
        expect(schema.encode(schema.parse(input)), equals(input));
      }

      final values = [DateTime(2026, 5, 4), DateTime(1999, 12, 31)];
      for (final value in values) {
        expect(schema.parse(schema.encode(value)), equals(value));
      }
    });

    test('Ack.datetime() round-trips via canonical UTC form', () {
      final schema = Ack.datetime();
      const inputs = [
        '2026-05-04T10:00:00.000Z',
        '2026-05-04T10:00:00-04:00',
        '1999-12-31T23:59:59.001Z',
      ];

      for (final input in inputs) {
        final parsed = schema.parse(input);
        final encoded = schema.encode(parsed);
        expect(schema.parse(encoded), equals(parsed));
      }

      final values = [DateTime.utc(2026, 5, 4, 10), DateTime(2026, 5, 4, 10)];
      for (final value in values) {
        expect(schema.parse(schema.encode(value)), equals(value.toUtc()));
      }
    });

    test('Ack.uri() round-trips boundary and runtime values', () {
      final schema = Ack.uri();
      const inputs = [
        'https://example.com/path',
        'https://example.com/path?x=1#frag',
      ];

      for (final input in inputs) {
        expect(schema.encode(schema.parse(input)), equals(input));
      }

      final values = [
        Uri.parse('https://example.com/path'),
        Uri.parse('https://example.com/path?x=1#frag'),
      ];
      for (final value in values) {
        expect(schema.parse(schema.encode(value)), equals(value));
      }
    });

    test('Ack.duration() round-trips boundary and runtime values', () {
      final schema = Ack.duration();
      const inputs = [0, 1500, 60000];

      for (final input in inputs) {
        expect(schema.encode(schema.parse(input)), equals(input));
      }

      final values = [
        Duration.zero,
        const Duration(milliseconds: 1500),
        const Duration(minutes: 1),
      ];
      for (final value in values) {
        expect(schema.parse(schema.encode(value)), equals(value));
      }
    });
  });
}
