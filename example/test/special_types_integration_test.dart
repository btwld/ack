import 'package:test/test.dart';
import '../lib/special_types_model.dart';

void main() {
  group('DateTime/Uri/Duration Integration Tests', () {
    test('parses DateTime from ISO string', () {
      final data = {
        'name': 'Test Event',
        'timestamp': '2024-01-15T10:30:00Z',
        'website': 'https://example.com',
        'duration': 3600000, // 1 hour in milliseconds
      };

      final event = EventType.parse(data);

      expect(event.name, 'Test Event');
      expect(event.timestamp, isA<DateTime>());
      expect(event.timestamp.year, 2024);
      expect(event.timestamp.month, 1);
      expect(event.timestamp.day, 15);
    });

    test('parses Uri from string', () {
      final data = {
        'name': 'Test',
        'timestamp': '2024-01-15T10:30:00Z',
        'website': 'https://example.com/path?query=1',
        'duration': 1000,
      };

      final event = EventType.parse(data);

      expect(event.website, isA<Uri>());
      expect(event.website.host, 'example.com');
      expect(event.website.path, '/path');
      expect(event.website.queryParameters['query'], '1');
    });

    test('parses Duration from milliseconds', () {
      final data = {
        'name': 'Test',
        'timestamp': '2024-01-15T10:30:00Z',
        'website': 'https://example.com',
        'duration': 3661000, // 1 hour, 1 minute, 1 second
      };

      final event = EventType.parse(data);

      expect(event.duration, isA<Duration>());
      expect(event.duration.inHours, 1);
      expect(event.duration.inMinutes, 61);
      expect(event.duration.inSeconds, 3661);
    });

    test('handles nullable special types correctly', () {
      final dataWithNulls = {
        'name': 'Test',
        'timestamp': '2024-01-15T10:30:00Z',
        'website': 'https://example.com',
        'duration': 1000,
        'optionalDate': null,
        'optionalUri': null,
        'optionalDuration': null,
      };

      final event = EventType.parse(dataWithNulls);

      expect(event.optionalDate, isNull);
      expect(event.optionalUri, isNull);
      expect(event.optionalDuration, isNull);
    });

    test('handles nullable special types with values', () {
      final dataWithValues = {
        'name': 'Test',
        'timestamp': '2024-01-15T10:30:00Z',
        'website': 'https://example.com',
        'duration': 1000,
        'optionalDate': '2024-12-25T00:00:00Z',
        'optionalUri': 'https://optional.example.com',
        'optionalDuration': 5000,
      };

      final event = EventType.parse(dataWithValues);

      expect(event.optionalDate, isA<DateTime>());
      expect(event.optionalDate?.month, 12);
      expect(event.optionalUri, isA<Uri>());
      expect(event.optionalUri?.host, 'optional.example.com');
      expect(event.optionalDuration, isA<Duration>());
      expect(event.optionalDuration?.inSeconds, 5);
    });
  });
}
