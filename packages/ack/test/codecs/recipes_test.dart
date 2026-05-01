import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Ack.codecs.isoStringToDateTime', () {
    final codec = Ack.codecs.isoStringToDateTime();

    test('decodes a UTC ISO string into a DateTime', () {
      final dt = codec.decode('2025-06-15T10:30:00Z');
      expect(dt, DateTime.utc(2025, 6, 15, 10, 30, 0));
    });

    test('round-trips a UTC DateTime back to an ISO string', () {
      final dt = DateTime.utc(2025, 6, 15, 10, 30, 0);
      final encoded = codec.encode(dt);
      expect(encoded, '2025-06-15T10:30:00.000Z');
      expect(codec.decode(encoded), dt);
    });

    test('rejects malformed input via inputSchema', () {
      final result = codec.safeDecode('not a date');
      expect(result.isFail, isTrue);
    });
  });

  group('Ack.codecs.epochMillisToDateTime', () {
    final codec = Ack.codecs.epochMillisToDateTime();

    test('decodes 0 ms to the Unix epoch in UTC', () {
      final dt = codec.decode(0);
      expect(dt, DateTime.utc(1970, 1, 1));
      expect(dt!.isUtc, isTrue);
    });

    test('round-trips a UTC DateTime', () {
      final dt = DateTime.utc(2025, 1, 1, 0, 0, 0);
      final encoded = codec.encode(dt);
      expect(codec.decode(encoded), dt);
    });

    test('local DateTime round-trips as the equivalent UTC instant', () {
      // Encoding goes through millisecondsSinceEpoch, which converts local
      // -> UTC. Decode produces the UTC equivalent. Same instant in time,
      // but the isUtc flag flips. Documented behavior — locking it in here.
      final local = DateTime(2025, 6, 15, 12, 30, 0);
      final roundTripped = codec.decode(codec.encode(local));
      expect(roundTripped!.isUtc, isTrue);
      expect(roundTripped.millisecondsSinceEpoch, local.millisecondsSinceEpoch);
    });
  });

  group('Ack.codecs.stringToUri', () {
    final codec = Ack.codecs.stringToUri();

    test('round-trips an absolute URI', () {
      final uri = Uri.parse('https://example.com/path?x=1');
      final encoded = codec.encode(uri);
      expect(encoded, 'https://example.com/path?x=1');
      expect(codec.decode(encoded), uri);
    });

    test('rejects relative URIs (no authority)', () {
      final result = codec.safeDecode('mailto:foo@bar.com');
      expect(result.isFail, isTrue);
    });
  });

  group('Ack.codecs.intMillisToDuration', () {
    final codec = Ack.codecs.intMillisToDuration();

    test('round-trips a Duration', () {
      const d = Duration(seconds: 30);
      final encoded = codec.encode(d);
      expect(encoded, 30000);
      expect(codec.decode(encoded), d);
    });
  });

  group('Ack.codecs.stringToInt', () {
    test('round-trips a base-10 int', () {
      final codec = Ack.codecs.stringToInt();
      expect(codec.decode('42'), 42);
      expect(codec.encode(42), '42');
    });

    test('respects custom radix on encode and decode', () {
      final codec = Ack.codecs.stringToInt(radix: 16);
      expect(codec.decode('ff'), 255);
      expect(codec.encode(255), 'ff');
    });

    test('decoder failure surfaces as SchemaTransformError', () {
      final codec = Ack.codecs.stringToInt();
      final result = codec.safeDecode('not-a-number');
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaTransformError>());
    });
  });

  group('Ack.codecs.stringToDouble', () {
    final codec = Ack.codecs.stringToDouble();

    test('round-trips a double', () {
      expect(codec.decode('3.14'), 3.14);
      expect(codec.encode(3.14), '3.14');
    });

    test('rejects non-finite values on encode', () {
      for (final v in [double.nan, double.infinity, double.negativeInfinity]) {
        final result = codec.safeEncode(v);
        expect(result.isFail, isTrue, reason: 'expected failure for $v');
        expect(result.getError(), isA<SchemaEncodeError>());
      }
    });
  });

  group('Ack.codecs.stringToBigInt', () {
    test('round-trips a BigInt', () {
      final codec = Ack.codecs.stringToBigInt();
      final big = BigInt.parse('123456789012345678901234567890');
      expect(codec.decode(big.toString()), big);
      expect(codec.encode(big), big.toString());
    });
  });

  group('Ack.codecs.json', () {
    final codec = Ack.codecs.json(
      Ack.object({'name': Ack.string(), 'age': Ack.integer()}),
    );

    test('round-trips a JSON object', () {
      const raw = '{"name":"Ada","age":36}';
      final decoded = codec.decode(raw);
      expect(decoded, {'name': 'Ada', 'age': 36});

      final encoded = codec.encode(decoded);
      // jsonEncode is order-preserving for maps in Dart.
      expect(encoded, raw);
    });

    test('decoder fails when the JSON does not match the schema', () {
      final result = codec.safeDecode('{"name":"Ada"}');
      expect(result.isFail, isTrue);
      final error = result.getError();
      // Structured error with path preserved — NOT a flat SchemaTransformError
      // wrapping a FormatException.
      expect(error, isNot(isA<SchemaTransformError>()));
      // The inner schema produced a nested error; the missing 'age' field is
      // reported at the '#/age' path.
      expect(error, isA<SchemaNestedError>());
      final nested = error as SchemaNestedError;
      expect(
        nested.errors.any((e) => e.path.contains('age')),
        isTrue,
        reason: 'expected a nested error with path containing "age"',
      );
    });

    test('decoder fails on malformed JSON', () {
      final result = codec.safeDecode('{not json');
      expect(result.isFail, isTrue);
    });

    test('structured path survives a deeply-nested validation failure', () {
      final deepCodec = Ack.codecs.json(
        Ack.object({
          'user': Ack.object({'age': Ack.integer()}),
        }),
      );
      // JSON is valid but 'user.age' is missing.
      final result = deepCodec.safeDecode('{"user":{}}');
      expect(result.isFail, isTrue);
      final error = result.getError();
      // Not a flat transform error — structured path is preserved.
      expect(error, isNot(isA<SchemaTransformError>()));
      expect(error, isA<SchemaNestedError>());
      final topNested = error as SchemaNestedError;
      // Walk into the 'user' nested error.
      final userError = topNested.errors.firstWhere(
        (e) => e.path.contains('user'),
        orElse: () => throw StateError('No error for "user" path'),
      );
      expect(userError, isA<SchemaNestedError>());
      final userNested = userError as SchemaNestedError;
      expect(
        userNested.errors.any((e) => e.path.contains('age')),
        isTrue,
        reason: 'expected a nested error with path containing "age"',
      );
    });
  });

  group('Ack.codecs round-trip via Ack.encode / Ack.decode', () {
    test('Ack.decode + Ack.encode mirror direct codec calls', () {
      final codec = Ack.codecs.isoStringToDateTime();
      final value = Ack.decode<DateTime>(codec, '2025-06-15T10:30:00Z');
      expect(value, DateTime.utc(2025, 6, 15, 10, 30, 0));
      expect(Ack.encode(codec, value), '2025-06-15T10:30:00.000Z');
    });
  });
}
