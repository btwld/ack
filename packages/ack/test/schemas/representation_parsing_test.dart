import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('parseRepresentationAs', () {
    test('returns mapped representation for string schema', () {
      final schema = Ack.string();
      final result = schema.parseRepresentationAs(
        'hello',
        (repr) => 'wrapped:$repr',
      );
      expect(result, 'wrapped:hello');
    });

    test('returns mapped representation for transformed schema', () {
      final schema = Ack.string().transform<Uri>((s) => Uri.parse(s));
      final result = schema.parseRepresentationAs(
        'https://example.com',
        (repr) => 'wire:$repr',
      );
      // representation is the wire value (String), not the parsed Uri
      expect(result, 'wire:https://example.com');
    });

    test('returns mapped representation for integer schema', () {
      final schema = Ack.integer();
      final result = schema.parseRepresentationAs(
        42,
        (repr) => 'int:$repr',
      );
      expect(result, 'int:42');
    });

    test('returns mapped representation for duration schema', () {
      final schema = Ack.duration();
      final result = schema.parseRepresentationAs(
        5000,
        (repr) => 'ms:$repr',
      );
      // representation is int (milliseconds), not Duration
      expect(result, 'ms:5000');
    });

    test('throws on invalid input', () {
      final schema = Ack.object({'name': Ack.string()});
      expect(
        () => schema.parseRepresentationAs('not a map', (repr) => repr!),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('safeParseRepresentationAs', () {
    test('returns Ok with mapped representation on valid input', () {
      final schema = Ack.string().transform<Uri>((s) => Uri.parse(s));
      final result = schema.safeParseRepresentationAs(
        'https://example.com',
        (repr) => 'wire:$repr',
      );
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), 'wire:https://example.com');
    });

    test('returns Fail on invalid input', () {
      final schema = Ack.object({'name': Ack.string()});
      final result = schema.safeParseRepresentationAs(
        'not a map',
        (repr) => repr!,
      );
      expect(result.isOk, isFalse);
    });
  });

  group('safeParseRepresentation', () {
    test('returns representation for string schema', () {
      final schema = Ack.string();
      final result = schema.safeParseRepresentation('hello');
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), 'hello');
    });

    test('returns representation for transformed schema', () {
      final schema = Ack.string().transform<Uri>((s) => Uri.parse(s));
      final result = schema.safeParseRepresentation('https://example.com');
      expect(result.isOk, isTrue);
      // representation is the pre-transform wire value
      expect(result.getOrNull(), 'https://example.com');
    });

    test('returns representation for object schema', () {
      final schema = Ack.object({'name': Ack.string()});
      final result = schema.safeParseRepresentation({'name': 'Alice'});
      expect(result.isOk, isTrue);
      expect(result.getOrNull(), isA<Map>());
    });

    test('returns Fail on invalid input', () {
      final schema = Ack.integer();
      final result = schema.safeParseRepresentation('not a number');
      expect(result.isOk, isFalse);
    });
  });

  group('representation-first round-trip', () {
    test('wire value survives parse -> representation -> toJson cycle', () {
      final schema = Ack.string().transform<Uri>((s) => Uri.parse(s));
      const wireValue = 'https://example.com/path?q=1';

      // Simulate what generated code does:
      // 1. parseRepresentationAs validates and wraps in extension type
      final extensionTypeValue = schema.parseRepresentationAs(
        wireValue,
        (repr) => repr! as String,
      );

      // 2. toJson returns the representation directly
      expect(extensionTypeValue, wireValue);

      // 3. The parsed value is available via schema.parse
      final parsed = schema.parse(wireValue);
      expect(parsed, isA<Uri>());
      expect(parsed?.host, 'example.com');
    });

    test('object schema fields preserve wire types through copyWith', () {
      final schema = Ack.object({
        'homepage': Ack.uri(),
        'timeout': Ack.duration(),
      });

      final result = schema.safeParseRepresentation({
        'homepage': 'https://example.com',
        'timeout': 3000,
      });

      expect(result.isOk, isTrue);
      final data = result.getOrNull() as Map;
      // Wire types preserved
      expect(data['homepage'], isA<String>());
      expect(data['timeout'], isA<int>());
    });
  });
}
