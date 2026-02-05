import 'package:test/test.dart';
import '../lib/special_types_model.dart';

void main() {
  group('DateTime/Uri/Duration Integration Tests', () {
    test('accepts DateTime ISO string', () {
      final data = {
        'name': 'Test Event',
        'timestamp': '2024-01-15T10:30:00Z',
        'website': 'https://example.com',
        'duration': 3600000, // 1 hour in milliseconds
      };

      final result = eventSchema.safeParse(data);
      expect(result.isOk, isTrue);

      final event = result.getOrThrow() as Map<String, Object?>;
      expect(event['name'], 'Test Event');
      expect(event['timestamp'], '2024-01-15T10:30:00Z');
    });

    test('accepts Uri strings', () {
      final data = {
        'name': 'Test',
        'timestamp': '2024-01-15T10:30:00Z',
        'website': 'https://example.com/path?query=1',
        'duration': 1000,
      };

      final result = eventSchema.safeParse(data);
      expect(result.isOk, isTrue);

      final event = result.getOrThrow() as Map<String, Object?>;
      expect(event['website'], 'https://example.com/path?query=1');
    });

    test('accepts Duration milliseconds', () {
      final data = {
        'name': 'Test',
        'timestamp': '2024-01-15T10:30:00Z',
        'website': 'https://example.com',
        'duration': 3661000, // 1 hour, 1 minute, 1 second
      };

      final result = eventSchema.safeParse(data);
      expect(result.isOk, isTrue);

      final event = result.getOrThrow() as Map<String, Object?>;
      expect(event['duration'], 3661000);
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

      final result = eventSchema.safeParse(dataWithNulls);
      expect(result.isOk, isTrue);

      final event = result.getOrThrow() as Map<String, Object?>;
      expect(event['optionalDate'], isNull);
      expect(event['optionalUri'], isNull);
      expect(event['optionalDuration'], isNull);
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

      final result = eventSchema.safeParse(dataWithValues);
      expect(result.isOk, isTrue);

      final event = result.getOrThrow() as Map<String, Object?>;
      expect(event['optionalDate'], '2024-12-25T00:00:00Z');
      expect(event['optionalUri'], 'https://optional.example.com');
      expect(event['optionalDuration'], 5000);
    });
  });
}
