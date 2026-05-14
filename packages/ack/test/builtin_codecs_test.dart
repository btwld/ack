import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Built-in codecs are bidirectional (M14)', () {
    test('factory return types are CodecSchema, not one-way transforms', () {
      expect(Ack.date(), isA<CodecSchema<String, DateTime>>());
      expect(Ack.datetime(), isA<CodecSchema<String, DateTime>>());
      expect(Ack.uri(), isA<CodecSchema<String, Uri>>());
      expect(Ack.duration(), isA<CodecSchema<int, Duration>>());
    });
  });

  group('Ack.date() — A2 (a) policy', () {
    test('round-trips local midnight dates', () {
      final schema = Ack.date();
      final value = DateTime(2026, 5, 10);
      expect(schema.encode(value), equals('2026-05-10'));
      expect(schema.parse(schema.encode(value)), equals(value));
    });

    test('parses ISO date string into local midnight DateTime', () {
      final schema = Ack.date();
      expect(schema.parse('2026-05-10'), equals(DateTime(2026, 5, 10)));
    });

    test('encode rejects UTC DateTime values (A2 (a))', () {
      // Per A2 (a), Ack.date() rejects UTC values — date is a calendar
      // date, not an instant. The error should NOT advise .toUtc().
      final result = Ack.date().safeEncode(DateTime.utc(2026, 5, 10));
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
      expect(
        result.getError().message,
        isNot(contains('toUtc')),
        reason: 'date should not push users toward .toUtc()',
      );
    });

    test('encode rejects non-midnight time components', () {
      final result = Ack.date().safeEncode(DateTime(2026, 5, 10, 12));
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('encode pads month/day to two digits', () {
      expect(Ack.date().encode(DateTime(2026, 1, 5)), equals('2026-01-05'));
    });
  });

  group('Ack.datetime() — A3 (b) policy', () {
    test('encodes UTC DateTime to ISO string', () {
      final schema = Ack.datetime();
      final value = DateTime.utc(2026, 5, 10, 12, 30);
      expect(schema.encode(value), equals(value.toIso8601String()));
    });

    test('parse → encode round-trips for UTC values', () {
      final schema = Ack.datetime();
      const iso = '2026-05-10T12:30:00.000Z';
      final parsed = schema.parse(iso);
      expect(parsed, equals(DateTime.utc(2026, 5, 10, 12, 30)));
      expect(schema.encode(parsed), equals(iso));
    });

    test('encode rejects non-UTC DateTime', () {
      final result = Ack.datetime().safeEncode(DateTime(2026, 5, 10, 12, 30));
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('encode error mentions toUtc() (A3 (b))', () {
      final result = Ack.datetime().safeEncode(DateTime(2026, 5, 10, 12, 30));
      expect(result.isFail, isTrue);
      expect(result.getError().message, contains('toUtc'));
    });
  });

  group('Ack.uri()', () {
    test('round-trips an absolute URI', () {
      final schema = Ack.uri();
      final uri = Uri.parse('https://example.com/path?x=1');
      expect(schema.encode(uri), equals('https://example.com/path?x=1'));
      expect(schema.parse(schema.encode(uri)), equals(uri));
    });

    test('encode rejects a relative URI', () {
      final result = Ack.uri().safeEncode(Uri.parse('/relative'));
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('encode rejects a scheme-only URI without authority', () {
      final result = Ack.uri().safeEncode(Uri.parse('mailto:a@example.com'));
      expect(result.isFail, isTrue);
    });
  });

  group('Ack.duration()', () {
    test('encodes whole milliseconds', () {
      expect(
        Ack.duration().encode(const Duration(milliseconds: 1500)),
        equals(1500),
      );
    });

    test('round-trips through parse', () {
      final schema = Ack.duration();
      final value = const Duration(milliseconds: 1500);
      expect(schema.parse(schema.encode(value)), equals(value));
    });

    test('encode rejects sub-millisecond durations', () {
      // 1501 microseconds = 1ms + 501us. inMilliseconds would silently
      // truncate to 1; encode must reject so the round-trip is honest.
      final result = Ack.duration().safeEncode(
        const Duration(microseconds: 1501),
      );
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaEncodeError>());
    });

    test('encode accepts zero', () {
      expect(Ack.duration().encode(Duration.zero), equals(0));
    });
  });

  group('Composite integration', () {
    test('object with Ack.datetime child encodes DateTime to string', () {
      final schema = Ack.object({'createdAt': Ack.datetime()});
      final encoded = schema.encode({'createdAt': DateTime.utc(2026, 5, 10)});
      expect(encoded, equals({'createdAt': '2026-05-10T00:00:00.000Z'}));
    });

    test('list with Ack.duration items encodes durations to integers', () {
      final schema = Ack.list(Ack.duration());
      final encoded = schema.encode([
        const Duration(milliseconds: 1),
        const Duration(milliseconds: 2),
      ]);
      expect(encoded, equals([1, 2]));
    });

    test('object with Ack.date child encodes local midnight to YYYY-MM-DD', () {
      final schema = Ack.object({'birthday': Ack.date()});
      final encoded = schema.encode({'birthday': DateTime(1990, 4, 1)});
      expect(encoded, equals({'birthday': '1990-04-01'}));
    });

    test('object with Ack.uri child encodes Uri to string', () {
      final schema = Ack.object({'home': Ack.uri()});
      final encoded = schema.encode({'home': Uri.parse('https://example.com')});
      expect(encoded, equals({'home': 'https://example.com'}));
    });
  });
}
