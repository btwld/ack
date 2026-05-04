import 'package:ack/ack.dart';
import 'package:test/test.dart';

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
    test('Ack.date() encodes DateTime back to YYYY-MM-DD', () {
      final dt = DateTime(2026, 5, 4);
      expect(Ack.date().encode(dt), equals('2026-05-04'));
    });

    test('Ack.date() round-trips through parse', () {
      final round = Ack.date().encode(Ack.date().parse('2026-05-04'));
      expect(round, equals('2026-05-04'));
    });

    test('Ack.datetime() encodes DateTime back to ISO with Z', () {
      final dt = DateTime.utc(2026, 5, 4, 10);
      final encoded = Ack.datetime().encode(dt);
      expect(encoded, equals('2026-05-04T10:00:00.000Z'));
    });

    test('Ack.uri() encodes Uri back to its string form', () {
      final uri = Uri.parse('https://example.com/path');
      expect(Ack.uri().encode(uri), equals('https://example.com/path'));
    });

    test('Ack.duration() encodes Duration back to milliseconds', () {
      expect(
        Ack.duration().encode(const Duration(milliseconds: 1500)),
        equals(1500),
      );
    });
  });
}
