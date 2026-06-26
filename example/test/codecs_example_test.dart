import 'package:ack/ack.dart';
import 'package:ack_example/codecs_example.dart';
import 'package:test/test.dart';

void main() {
  group('Codec examples', () {
    test('built-in codecs decode boundary values into Dart runtime types', () {
      final event = eventSchema.parse({
        'name': 'Launch',
        'startsAt': '2026-01-01T09:00:00Z',
        'due': '2026-01-01',
        'website': 'https://example.com',
        'timeout': 5000,
        'priority': 'high',
      })!;

      expect(event['startsAt'], isA<DateTime>());
      expect((event['startsAt']! as DateTime).isUtc, isTrue);
      expect(event['due'], isA<DateTime>());
      expect(event['website'], isA<Uri>());
      expect(event['timeout'], const Duration(milliseconds: 5000));
      expect(event['priority'], Priority.high);
    });

    test('custom codec round-trips in both directions', () {
      expect(tagsCodec.parse('dart,flutter,ack'), ['dart', 'flutter', 'ack']);
      expect(tagsCodec.encode(['dart', 'flutter', 'ack']), 'dart,flutter,ack');
    });

    test('datetime codec encodes a UTC DateTime back to ISO 8601', () {
      expect(
        Ack.datetime().encode(DateTime.utc(2026, 1, 1, 9)),
        '2026-01-01T09:00:00.000Z',
      );
    });
  });
}
