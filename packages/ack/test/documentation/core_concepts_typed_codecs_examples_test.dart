import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Tests for code snippets in docs/core-concepts/typed-codecs.mdx.
void main() {
  group('Docs /core-concepts/typed-codecs.mdx', () {
    test('codec example parses and encodes explicitly', () {
      final intFromString = Ack.string().codec<int>(
        decode: int.parse,
        encode: (value) => value.toString(),
      );

      final int? parsed = intFromString.parse('42');
      final String? encoded = intFromString.encode(42);

      expect(parsed, 42);
      expect(encoded, '42');
    });

    test('object model example composes nested codecs', () {
      final eventSchema = Ack.object({'createdAt': Ack.datetime()})
          .model<_Event>(
            decode: (data) => _Event(createdAt: data['createdAt'] as DateTime),
            encode: (event) => {'createdAt': event.createdAt},
          );

      final _Event? parsed = eventSchema.parse({
        'createdAt': '2026-05-10T00:00:00.000Z',
      });

      final JsonMap? encoded = eventSchema.encode(parsed);

      expect(parsed?.createdAt, DateTime.utc(2026, 5, 10));
      expect(encoded, {'createdAt': '2026-05-10T00:00:00.000Z'});
    });

    test('one-way transform safeEncode returns a failure', () {
      final schema = Ack.string().transform<int>(int.parse);

      expect(schema.safeParse('42').getOrThrow(), 42);
      expect(schema.safeEncode(42).isFail, true);
    });

    test('defaults parse null but encode does not inject defaults', () {
      final schema = Ack.string().withDefault('fallback');

      expect(schema.parse(null), 'fallback');
      expect(schema.safeEncode(null).isFail, true);

      final nullable = Ack.string().nullable().withDefault('fallback');
      expect(nullable.encode(null), isNull);
    });
  });
}

final class _Event {
  const _Event({required this.createdAt});

  final DateTime createdAt;
}
