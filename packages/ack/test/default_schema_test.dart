import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('DefaultSchema (M12)', () {
    group('parse', () {
      test('synthesizes the default on null input', () {
        final schema = Ack.string().withDefault('guest');
        expect(schema.parse(null), equals('guest'));
      });

      test('forwards a non-null input through the inner schema', () {
        final schema = Ack.string().withDefault('guest');
        expect(schema.parse('alice'), equals('alice'));
      });

      test('default must satisfy inner constraints', () {
        final schema = Ack.string().minLength(5).withDefault('x');
        final result = schema.safeParse(null);
        expect(result.isFail, isTrue,
            reason: 'default validates through inner runtime path');
      });

      test('codec default is treated as runtime value, not boundary', () {
        // Ack.codec<String, DateTime> has runtime form DateTime. The default
        // is a DateTime — must validate through outputSchema (not be re-parsed
        // as a boundary string).
        final schema = Ack.codec<String, DateTime>(
          input: Ack.string(),
          output: Ack.instance<DateTime>(),
          decoder: DateTime.parse,
          encoder: (v) => v.toIso8601String(),
        ).withDefault(DateTime.utc(2026, 1, 1));
        expect(schema.parse(null), equals(DateTime.utc(2026, 1, 1)));
      });
    });

    group('encode', () {
      test('does not synthesize default during encode', () {
        final schema = Ack.string().withDefault('guest');
        final result = schema.safeEncode(null);
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaEncodeError>());
      });

      test('over nullable inner encodes null as null (A7)', () {
        // A7: DefaultSchema(nullableInner).encode(null) returns null;
        // defaults are parse-only.
        final schema = Ack.string().nullable().withDefault('guest');
        final result = schema.safeEncode(null);
        expect(result.isOk, isTrue);
        expect(result.getOrNull(), isNull);
      });

      test('non-null runtime values are encoded through the inner schema', () {
        final schema = Ack.string().withDefault('guest');
        final result = schema.safeEncode('alice');
        expect(result.isOk, isTrue);
        expect(result.getOrNull(), equals('alice'));
      });

      test('codec wrapped with default still encodes runtime values', () {
        final schema = Ack.codec<String, DateTime>(
          input: Ack.string(),
          output: Ack.instance<DateTime>(),
          decoder: DateTime.parse,
          encoder: (v) => v.toIso8601String(),
        ).withDefault(DateTime.utc(2026, 1, 1));
        final encoded = schema.encode(DateTime.utc(2030, 7, 4));
        expect(encoded, equals(DateTime.utc(2030, 7, 4).toIso8601String()));
      });
    });

    group('object integration', () {
      test('missing optional DefaultSchema property synthesizes default on '
          'parse', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'role': Ack.string().withDefault('guest').optional(),
        });
        final parsed = schema.parse({'name': 'Leo'});
        expect(parsed, equals({'name': 'Leo', 'role': 'guest'}));
      });

      test('missing optional DefaultSchema property is omitted on encode '
          '(no default synthesis on encode)', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'role': Ack.string().withDefault('guest').optional(),
        });
        final encoded = schema.encode({'name': 'Leo'});
        expect(encoded, equals({'name': 'Leo'}));
      });
    });

    group('JSON Schema', () {
      test('serializes the default to its boundary value (codec)', () {
        final schema = Ack.codec<String, DateTime>(
          input: Ack.string(),
          output: Ack.instance<DateTime>(),
          decoder: DateTime.parse,
          encoder: (v) => v.toIso8601String(),
        ).withDefault(DateTime.utc(2026, 1, 1));
        final json = schema.toJsonSchema();
        expect(json['default'], isA<String>());
        expect(
          json['default'],
          equals(DateTime.utc(2026, 1, 1).toIso8601String()),
        );
      });

      test('serializes a primitive default as-is', () {
        final json = Ack.string().withDefault('hello').toJsonSchema();
        expect(json['default'], equals('hello'));
        expect(json['type'], equals('string'));
      });
    });

    group('discriminated unwrap', () {
      test('Discriminated branch unwraps DefaultSchema wrapper', () {
        // Wrapping a branch with .withDefault().optional() should still let
        // the discriminator dispatch find the underlying ObjectSchema.
        final branch = Ack.object({
          'type': Ack.literal('cat'),
          'name': Ack.string(),
        }).withDefault({'type': 'cat', 'name': 'Milo'}).optional();
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {'cat': branch},
        );
        // Smoke test: schema construction and JSON Schema export do not throw.
        expect(schema.toJsonSchema(), isA<Map<String, Object?>>());
        // Parse a regular cat works.
        expect(
          schema.parse({'type': 'cat', 'name': 'Felix'}),
          equals({'type': 'cat', 'name': 'Felix'}),
        );
      });
    });

    group('legacy compatibility', () {
      test('legacy copyWith(defaultValue:) still synthesizes default on null',
          () {
        // For one beta cycle the legacy default field stays. Existing code
        // using copyWith(defaultValue:) keeps working.
        final schema = const StringSchema().copyWith(defaultValue: 'legacy');
        expect(schema.parse(null), equals('legacy'));
      });
    });
  });
}
