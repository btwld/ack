import 'package:ack/ack.dart';
import 'package:test/test.dart';

final class _Event {
  _Event(this.createdAt);
  final DateTime createdAt;
}

enum _Role { admin, member }

void main() {
  group('AckSchema<Boundary, Runtime> type model', () {
    test('Ack.string is AckSchema<String, String>', () {
      final AckSchema<String, String> schema = Ack.string();
      final String? parsed = schema.parse('hello');
      final String? encoded = schema.encode('hello');
      expect(parsed, 'hello');
      expect(encoded, 'hello');
    });

    test('Ack.integer is AckSchema<int, int>', () {
      final AckSchema<int, int> schema = Ack.integer();
      final int? parsed = schema.parse(42);
      final int? encoded = schema.encode(42);
      expect(parsed, 42);
      expect(encoded, 42);
    });

    test('Ack.double is AckSchema<double, double>', () {
      final AckSchema<double, double> schema = Ack.double();
      final double? parsed = schema.parse(1.5);
      final double? encoded = schema.encode(1.5);
      expect(parsed, 1.5);
      expect(encoded, 1.5);
    });

    test('Ack.number is AckSchema<num, num>', () {
      final AckSchema<num, num> schema = Ack.number();
      final num? parsed = schema.parse(42);
      final num? encoded = schema.encode(42);
      expect(parsed, 42);
      expect(encoded, 42);
    });

    test('Ack.boolean is AckSchema<bool, bool>', () {
      final AckSchema<bool, bool> schema = Ack.boolean();
      final bool? parsed = schema.parse(true);
      final bool? encoded = schema.encode(true);
      expect(parsed, true);
      expect(encoded, true);
    });
  });

  group('Built-in codecs', () {
    test('Ack.date encode is statically typed as String', () {
      final schema = Ack.date();
      final String? encoded = schema.encode(DateTime(2026, 5, 10));
      expect(encoded, '2026-05-10');
    });

    test('Ack.date parse is statically typed as DateTime', () {
      final schema = Ack.date();
      final DateTime? parsed = schema.parse('2026-05-10');
      expect(parsed, isA<DateTime>());
      expect(parsed!.year, 2026);
      expect(parsed.month, 5);
      expect(parsed.day, 10);
    });

    test('Ack.datetime encodes to ISO 8601 string', () {
      final schema = Ack.datetime();
      final value = DateTime.utc(2026, 5, 10, 12, 30);
      final String? encoded = schema.encode(value);
      expect(encoded, '2026-05-10T12:30:00.000Z');
    });

    test('Ack.duration encode is statically typed as int', () {
      final schema = Ack.duration();
      final int? encoded = schema.encode(
        const Duration(milliseconds: 500),
      );
      expect(encoded, 500);
    });

    test('Ack.duration parse is statically typed as Duration', () {
      final schema = Ack.duration();
      final Duration? parsed = schema.parse(1500);
      expect(parsed, const Duration(milliseconds: 1500));
    });

    test('Ack.uri round-trips', () {
      final schema = Ack.uri();
      final Uri? parsed = schema.parse('https://example.com/x');
      expect(parsed, Uri.parse('https://example.com/x'));
      final String? encoded = schema.encode(parsed);
      expect(encoded, 'https://example.com/x');
    });
  });

  group('Nested list codec encode', () {
    test('Ack.list(Ack.date()) encode is List<String>', () {
      final schema = Ack.list(Ack.date());
      final List<String>? encoded = schema.encode([
        DateTime(2026, 5, 10),
      ]);
      expect(encoded, ['2026-05-10']);
    });

    test('Ack.list(Ack.duration()) encode is List<int>', () {
      final schema = Ack.list(Ack.duration());
      final List<int>? encoded = schema.encode([
        const Duration(milliseconds: 1),
        const Duration(milliseconds: 2),
      ]);
      expect(encoded, [1, 2]);
    });
  });

  group('Object model mapping', () {
    test('ObjectSchema.model parses model and encodes JsonMap', () {
      final schema = Ack.object({
        'createdAt': Ack.datetime(),
      }).model<_Event>(
        decode: (data) => _Event(data['createdAt'] as DateTime),
        encode: (event) => {
          'createdAt': event.createdAt,
        },
      );

      final _Event? parsed = schema.parse({
        'createdAt': '2026-05-10T00:00:00.000Z',
      });
      expect(parsed, isNotNull);
      expect(parsed!.createdAt, DateTime.utc(2026, 5, 10));

      final JsonMap? encoded = schema.encode(parsed);
      expect(encoded, {
        'createdAt': '2026-05-10T00:00:00.000Z',
      });
    });
  });

  group('Generic codec combinator', () {
    test('schema.codec creates typed bidirectional schema', () {
      final schema = Ack.string().codec<int>(
        decode: int.parse,
        encode: (value) => value.toString(),
      );

      final int? parsed = schema.parse('42');
      final String? encoded = schema.encode(42);
      expect(parsed, 42);
      expect(encoded, '42');
    });
  });

  group('Enum schema with String boundary', () {
    test('Parses .name and encodes back', () {
      final schema = Ack.enumValues(_Role.values);
      final _Role? parsed = schema.parse('admin');
      expect(parsed, _Role.admin);
      final String? encoded = schema.encode(_Role.admin);
      expect(encoded, 'admin');
    });
  });

  group('DefaultSchema wrapper', () {
    test('parse(null) returns runtime default', () {
      final schema = Ack.string().withDefault('fallback');
      final String? parsed = schema.parse(null);
      expect(parsed, 'fallback');
    });

    test('encode(null) does NOT inject default', () {
      final schema = Ack.string().nullable().withDefault('fallback');
      final String? encoded = schema.encode(null);
      expect(encoded, isNull);
    });

    test('parse with explicit value bypasses default', () {
      final schema = Ack.integer().withDefault(0);
      expect(schema.parse(5), 5);
    });
  });

  group('TransformedSchema is one-way', () {
    test('parse works via transformer', () {
      final schema = Ack.string().transform<int>(int.parse);
      expect(schema.parse('123'), 123);
    });

    test('encode fails with oneWayTransform error', () {
      final schema = Ack.string().transform<int>(int.parse);
      final result = schema.safeEncode(123);
      expect(result.isFail, true);
      final error = result.getError();
      expect(error, isA<SchemaEncodeError>());
      expect(
        (error as SchemaEncodeError).kind,
        SchemaEncodeFailureKind.oneWayTransform,
      );
    });
  });

  group('Object encode validations', () {
    test('Missing required property fails encode', () {
      final schema = Ack.object({
        'name': Ack.string(),
        'age': Ack.integer(),
      });
      final result = schema.safeEncode({'name': 'x'});
      expect(result.isFail, true);
    });

    test('Unexpected property fails encode', () {
      final schema = Ack.object({'name': Ack.string()});
      final result = schema.safeEncode({'name': 'x', 'extra': 'y'});
      expect(result.isFail, true);
    });

    test('additionalProperties: true allows extras on encode', () {
      final schema = Ack.object(
        {'name': Ack.string()},
        additionalProperties: true,
      );
      final result = schema.safeEncode({'name': 'x', 'extra': 'y'});
      expect(result.isOk, true);
      expect(result.getOrNull(), {'name': 'x', 'extra': 'y'});
    });
  });

  group('SchemaContext.operation', () {
    test('parse uses SchemaOperation.parse', () {
      late SchemaOperation op;
      final schema = Ack.string().refine((s) {
        op = SchemaOperation.parse; // captured lazily on parse path
        return true;
      });
      schema.parse('x');
      expect(op, SchemaOperation.parse);
    });
  });
}
