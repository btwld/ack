import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('.transform(...) is a one-way CodecSchema (M13)', () {
    test('transform parses through one-way CodecSchema', () {
      final schema = Ack.string().transform<int>(int.parse);
      expect(schema.parse('42'), equals(42));
    });

    test('transform encode fails with SchemaEncodeError.oneWayTransform', () {
      final schema = Ack.string().transform<int>(int.parse);
      final result = schema.safeEncode(42);
      expect(result.isFail, isTrue);
      final err = result.getError();
      expect(err, isA<SchemaEncodeError>());
      expect(err.message, contains('Ack.codec'));
    });

    test('transform returns CodecSchema<I, O>', () {
      final schema = Ack.string().transform<int>(int.parse);
      expect(schema, isA<CodecSchema<String, int>>());
    });

    test('TransformedSchema<I, O> typedef annotation compiles and runs', () {
      // ignore: deprecated_member_use_from_same_package
      final TransformedSchema<String, int> schema =
          Ack.string().transform<int>(int.parse);
      expect(schema.parse('1'), equals(1));
      expect(schema, isA<CodecSchema<String, int>>());
    });

    test('transform inherits isOptional / isNullable / description', () {
      final base = Ack.string()
          .nullable()
          .optional()
          .describe('numeric input');
      final schema = base.transform<int>(int.parse);
      expect(schema.isOptional, isTrue);
      expect(schema.isNullable, isTrue);
      expect(schema.description, equals('numeric input'));
    });

    test('transform composes with .withDefault for parse-time defaults', () {
      // .transform → CodecSchema; .withDefault → DefaultSchema wrapping it.
      final schema = Ack.string()
          .transform<int>(int.parse)
          .withDefault(42);
      expect(schema.parse(null), equals(42));
    });

    test('discriminated codec-backed branch still unwraps', () {
      // Branch is CodecSchema<MapValue, _Animal>. The unwrap util follows
      // CodecSchema.inputSchema to find the ObjectSchema.
      final branch = Ack.codec<Map<String, Object?>, _Animal>(
        input: Ack.object({
          'type': Ack.literal('cat'),
          'name': Ack.string(),
        }),
        output: Ack.instance<_Animal>(),
        decoder: (m) => _Cat(m['name']! as String),
        encoder: (a) => {'type': 'cat', 'name': a.name},
      );
      final schema = Ack.discriminated<_Animal>(
        discriminatorKey: 'type',
        schemas: {'cat': branch},
      );
      expect(
        schema.parse({'type': 'cat', 'name': 'Milo'}),
        isA<_Cat>(),
      );
    });
  });

  group('TransformedSchema-as-typedef (M13)', () {
    test('extension typed for TransformedSchema applies to CodecSchema', () {
      // DateTimeSchemaExtensions is on `TransformedSchema<String, DateTime>`.
      // After M13 the typedef is CodecSchema<String, DateTime>, so the
      // extension still resolves on the codec returned by Ack.datetime().
      final schema = Ack.datetime().min(DateTime.utc(2020));
      expect(schema, isA<CodecSchema<String, DateTime>>());
    });
  });
}

class _Animal {
  final String name;
  const _Animal(this.name);
}

class _Cat extends _Animal {
  const _Cat(super.name);
}
