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

    test('parse accepts decoder output validated by nested output codecs', () {
      final schema = Ack.codec<String, Map<String, Object?>>(
        Ack.string().datetime(),
        Ack.object({'startsAt': Ack.datetime()}),
        decode: (s) => {'startsAt': DateTime.parse(s)},
        encode: (m) => (m['startsAt'] as DateTime).toUtc().toIso8601String(),
      );

      final parsed = schema.parse('2026-05-04T10:00:00.000Z');

      expect(parsed, equals({'startsAt': DateTime.utc(2026, 5, 4, 10)}));
    });

    test('parse rejects non-object-backed discriminated output branches', () {
      final outputSchema = Ack.discriminated<Object>(
        discriminatorKey: 'type',
        schemas: {'cat': Ack.string().transform<Object>((value) => value)},
      );
      final schema = Ack.codec<Map<String, Object?>, Object>(
        Ack.object({'type': Ack.literal('cat')}),
        outputSchema,
        decode: (map) => map,
        encode: (_) => <String, Object?>{'type': 'cat'},
      );

      final result = schema.safeParse({'type': 'cat'});

      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaValidationError>());
      expect(
        result.getError().message,
        equals('Discriminated branches must be object-backed schemas'),
      );
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
      ).withDefault(99);

      expect(schema.parse(null), equals(99));
    });

    test('default must satisfy the output schema', () {
      final schema = Ack.codec<String, String>(
        Ack.string(),
        Ack.string().minLength(5),
        decode: (s) => s,
        encode: (s) => s,
      ).withDefault('no');

      final result = schema.safeParse(null);

      expect(result.isFail, isTrue);
    });

    test('default does NOT synthesize during encode', () {
      final schema = Ack.codec<String, int>(
        Ack.string(),
        Ack.instance<int>(),
        decode: int.parse,
        encode: (i) => i.toString(),
      ).withDefault(99);

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

    test('nullable codec emits null branch from codec wrapper', () {
      final json = Ack.datetime().nullable().toJsonSchema();

      expect(json['anyOf'], isA<List>());
      final anyOf = json['anyOf']! as List;
      expect(
        anyOf,
        contains(
          allOf([
            isA<Map>(),
            containsPair('type', 'string'),
            containsPair('format', 'date-time'),
          ]),
        ),
      );
      expect(
        anyOf,
        contains(isA<Map>().having((m) => m['type'], 'type', 'null')),
      );
      expect(json[CodecSchema.jsonSchemaMarker], isTrue);
    });

    test('non-null codec ignores nullable input schema in JSON Schema', () {
      final schema = Ack.codec<String, int>(
        Ack.string().nullable(),
        Ack.instance<int>(),
        decode: int.parse,
        encode: (i) => i.toString(),
      );

      final json = schema.toJsonSchema();

      expect(json['anyOf'], isNull);
      expect(json['type'], equals('string'));
      expect(json[CodecSchema.jsonSchemaMarker], isTrue);
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

      final result = schema.safeEncode(DateTime(2026, 5, 4, 12));
      expect(result.isFail, isTrue);
    });

    test('Ack.datetime() round-trips UTC values', () {
      final schema = Ack.datetime();
      const inputs = ['2026-05-04T10:00:00.000Z', '1999-12-31T23:59:59.001Z'];

      for (final input in inputs) {
        final parsed = schema.parse(input);
        final encoded = schema.encode(parsed);
        expect(schema.parse(encoded), equals(parsed));
      }

      final values = [
        DateTime.utc(2026, 5, 4, 10),
        DateTime.utc(1999, 12, 31, 23, 59, 59, 1),
      ];
      for (final value in values) {
        expect(schema.parse(schema.encode(value)), equals(value));
      }

      final nonUtc = schema.safeEncode(DateTime(2026, 5, 4, 10));
      expect(nonUtc.isFail, isTrue);
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

      final relative = schema.safeEncode(Uri.parse('/relative/path'));
      expect(relative.isFail, isTrue);
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

      final result = schema.safeEncode(const Duration(microseconds: 1501));
      expect(result.isFail, isTrue);
    });
  });

  group('CodecSchema — codec-of-codec', () {
    test('encode recursively pushes through inner codec input schema', () {
      // Outer wraps a codec inputSchema (string boundary → int runtime).
      // Outer encoder produces an int (the inner codec's runtime O). encode
      // recursively runs the inner codec's encoder so the final boundary form
      // is a string ("1500"), not an int — preserving parse(encode(value)).
      final outer = Ack.codec<int, Duration>(
        Ack.codec<String, int>(
          Ack.string(),
          Ack.instance<int>(),
          decode: int.parse,
          encode: (i) => i.toString(),
        ),
        Ack.instance<Duration>(),
        decode: (ms) => Duration(milliseconds: ms),
        encode: (d) => d.inMilliseconds,
      );

      final encoded = outer.encode(const Duration(milliseconds: 1500));
      expect(encoded, equals('1500'));

      expect(outer.parse(encoded), equals(const Duration(milliseconds: 1500)));
    });
  });

  group('CodecSchema — codec inside object inputSchema', () {
    test('encode produces boundary-shaped output for nested codec field', () {
      final schema = Ack.codec<Map<String, Object?>, ({DateTime startsAt})>(
        Ack.object({'startsAt': Ack.datetime()}),
        Ack.instance<({DateTime startsAt})>(),
        decode: (m) => (startsAt: m['startsAt']! as DateTime),
        encode: (v) => {'startsAt': v.startsAt},
      );

      final v = (startsAt: DateTime.utc(2026, 5, 6, 12));
      final encoded = schema.encode(v);

      expect(encoded, isA<Map<String, Object?>>());
      final map = encoded as Map<String, Object?>;
      expect(map['startsAt'], isA<String>());
      expect(map['startsAt'], equals('2026-05-06T12:00:00.000Z'));

      final roundTripped = schema.parse(encoded)!;
      expect(roundTripped.startsAt.toUtc(), equals(v.startsAt));
    });
  });

  group('custom bool string codec — boundary surface', () {
    test('safeParse rejects non-bool strings before decode', () {
      final schema = Ack.codec<String, bool>(
        Ack.string().matches(r'^(?:true|false)$'),
        Ack.instance<bool>(),
        decode: bool.parse,
        encode: (b) => b.toString(),
      );

      final result = schema.safeParse('yes');
      expect(result.isFail, isTrue);
    });

    test('toJsonSchema publishes the bool pattern', () {
      final schema = Ack.codec<String, bool>(
        Ack.string().matches(r'^(?:true|false)$'),
        Ack.instance<bool>(),
        decode: bool.parse,
        encode: (b) => b.toString(),
      );

      final json = schema.toJsonSchema();
      expect(json['type'], equals('string'));
      expect(json['pattern'], isA<String>());
      // Sanity-check the pattern matches what decode accepts.
      final pattern = RegExp(json['pattern']! as String);
      expect(pattern.hasMatch('true'), isTrue);
      expect(pattern.hasMatch('false'), isTrue);
      expect(pattern.hasMatch('FALSE'), isFalse);
      expect(pattern.hasMatch(' True '), isFalse);
      expect(pattern.hasMatch('yes'), isFalse);
    });
  });

  group('Ack.date — encode rejects UTC values', () {
    test('safeEncode fails when given a UTC DateTime', () {
      final schema = Ack.date();
      final result = schema.safeEncode(DateTime.utc(2026, 5, 4));
      expect(result.isFail, isTrue);
    });
  });

  group('Ack.literal direct encode', () {
    test('safeEncode rejects values that do not match the literal', () {
      final schema = Ack.literal('cat');
      final result = schema.safeEncode('dog');
      expect(result.isFail, isTrue);
    });

    test('safeEncode accepts the exact literal value', () {
      final schema = Ack.literal('cat');
      expect(schema.encode('cat'), equals('cat'));
    });
  });
}
