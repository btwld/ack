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
        expect(
          result.isFail,
          isTrue,
          reason: 'default validates through inner runtime path',
        );
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

      test('omits JSON Schema default for non-JSON runtime defaults', () {
        // InstanceSchema.encodeBoundary is identity, so a DateTime would
        // leak through unless toJsonSchema applies a JSON-safety check.
        final schema = Ack.instance<DateTime>().withDefault(
          DateTime.utc(2026, 1, 1),
        );
        final json = schema.toJsonSchema();
        expect(json.containsKey('default'), isFalse);
      });

      test('omits JSON Schema default when default fails inner validation', () {
        // Per M12 review (Ack stricter than Zod here): a default that would
        // fail inner runtime validation is not emitted in JSON Schema.
        final schema = Ack.string().minLength(5).withDefault('x');
        final json = schema.toJsonSchema();
        expect(json.containsKey('default'), isFalse);
      });

      test('nullable wrapper adds a null branch to the JSON Schema', () {
        // The wrapper's isNullable can differ from the inner's. When the
        // wrapper is nullable but the inner isn't, the JSON Schema must
        // include the null branch.
        final json = Ack.string()
            .withDefault('guest')
            .nullable()
            .toJsonSchema();
        expect(json['anyOf'], isA<List>());
        expect(
          json['anyOf'] as List,
          contains(isA<Map>().having((m) => m['type'], 'type', 'null')),
        );
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

    group('default value identity', () {
      test('withDefault is the only API for parse-time defaults', () {
        // C2: AckSchema.defaultValue field and copyWith(defaultValue:) were
        // removed. DefaultSchema is the sole owner of parse-time defaults.
        final schema = const StringSchema().withDefault('legacy');
        expect(schema, isA<DefaultSchema<String>>());
        expect(schema.parse(null), equals('legacy'));
      });
    });
  });
}
