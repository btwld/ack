/// Migration recipes for explicit primitive coercion (M14a).
///
/// Per the M14a B4 decision (codec-open-questions.md), `Ack` does NOT
/// expose `Ack.intFromString()`, `Ack.doubleFromString()`, or
/// `Ack.boolFromString()`. The reference design's primitive for explicit
/// conversion is [Ack.codec], and these recipes are runnable
/// documentation showing the migration path away from the legacy
/// implicit coercion (which was tightened for `Ack.double()` in M11 and
/// will be retired more broadly in a follow-up sweep).
///
/// Each test below builds the recipe inline so that copying the body
/// into user code "just works".
library;

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Migration recipe — string ↔ int', () {
    test('basic decimal int', () {
      final intFromString = Ack.codec<String, int>(
        input: Ack.string().refine(
          (value) => int.tryParse(value) != null,
          message: 'Expected an integer string.',
        ),
        output: Ack.integer(),
        decoder: int.parse,
        encoder: (value) => value.toString(),
      );

      expect(intFromString.parse('42'), equals(42));
      expect(intFromString.encode(42), equals('42'));
      expect(intFromString.safeParse('not-an-int').isFail, isTrue);
    });

    test('hexadecimal (radix: 16) — encoder must mirror the radix', () {
      // The radix-specific encoder MUST use toRadixString(radix) rather
      // than toString(), or the round-trip silently drifts.
      const radix = 16;
      final hexInt = Ack.codec<String, int>(
        input: Ack.string().refine(
          (value) => int.tryParse(value, radix: radix) != null,
          message: 'Expected a base-$radix integer string.',
        ),
        output: Ack.integer(),
        decoder: (value) => int.parse(value, radix: radix),
        encoder: (value) => value.toRadixString(radix),
      );

      expect(hexInt.parse('ff'), equals(255));
      expect(hexInt.encode(255), equals('ff'));
      expect(hexInt.parse(hexInt.encode(255)), equals(255));
      expect(hexInt.safeParse('xyz').isFail, isTrue);
    });
  });

  group('Migration recipe — string ↔ double', () {
    test('round-trip', () {
      final doubleFromString = Ack.codec<String, double>(
        input: Ack.string().refine(
          (value) => double.tryParse(value) != null,
          message: 'Expected a double string.',
        ),
        output: Ack.double(),
        decoder: double.parse,
        encoder: (value) => value.toString(),
      );

      expect(doubleFromString.parse('3.14'), equals(3.14));
      expect(doubleFromString.encode(3.14), equals('3.14'));
      expect(doubleFromString.safeParse('not-a-number').isFail, isTrue);
    });
  });

  group('Migration recipe — string ↔ bool', () {
    test('strict "true" / "false" parsing, case- and whitespace-insensitive',
        () {
      bool? parseBool(String value) {
        return switch (value.trim().toLowerCase()) {
          'true' => true,
          'false' => false,
          _ => null,
        };
      }

      final boolFromString = Ack.codec<String, bool>(
        input: Ack.string().refine(
          (value) => parseBool(value) != null,
          message: 'Expected "true" or "false".',
        ),
        output: Ack.boolean(),
        decoder: (value) => parseBool(value)!,
        encoder: (value) => value.toString(),
      );

      expect(boolFromString.parse('true'), isTrue);
      expect(boolFromString.parse('FALSE'), isFalse);
      expect(boolFromString.parse(' true '), isTrue);
      expect(boolFromString.encode(true), equals('true'));
      expect(boolFromString.encode(false), equals('false'));
      expect(boolFromString.safeParse('yes').isFail, isTrue);
    });
  });

  group('Composability', () {
    test('a recipe codec composes inside ObjectSchema and round-trips', () {
      // Demonstrates the recipes survive the same composite-encode pipeline
      // as the built-in M14 codecs (date/datetime/uri/duration) — no
      // special-case wiring is needed because they are just CodecSchemas.
      final intFromString = Ack.codec<String, int>(
        input: Ack.string().refine(
          (value) => int.tryParse(value) != null,
          message: 'Expected an integer string.',
        ),
        output: Ack.integer(),
        decoder: int.parse,
        encoder: (value) => value.toString(),
      );

      final schema = Ack.object({
        'count': intFromString,
        'label': Ack.string(),
      });

      final parsed = schema.parse({'count': '42', 'label': 'answers'});
      expect(parsed, equals({'count': 42, 'label': 'answers'}));

      final encoded = schema.encode({'count': 42, 'label': 'answers'});
      expect(encoded, equals({'count': '42', 'label': 'answers'}));
    });
  });
}
