import 'dart:convert';
import 'dart:io';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Tests for code snippets in docs/core-concepts/json-serialization.mdx.
void main() {
  group('Docs /core-concepts/json-serialization.mdx', () {
    AckSchema<Map<String, Object?>, Map<String, Object?>> buildUserSchema() {
      return Ack.object({
        'name': Ack.string(),
        'age': Ack.integer().min(0),
        'email': Ack.string().email().nullable(),
      });
    }

    test('processApiResponse example validates decoded JSON', () {
      final userSchema = buildUserSchema();
      final logs = <String>[];

      void processApiResponse(String jsonString) {
        dynamic jsonData;
        try {
          jsonData = jsonDecode(jsonString);
        } catch (e) {
          logs.add('Failed to decode JSON: $e');
          return;
        }

        final result = userSchema.safeParse(jsonData);

        if (result.isOk) {
          logs.add('Valid JSON received: ${result.getOrThrow()}');
        } else {
          logs.add('Invalid JSON data: ${result.getError()}');
        }
      }

      processApiResponse(
        '{"name": "Alice", "age": 30, "email": "alice@example.com"}',
      );
      expect(logs.last, contains('Valid JSON received'));

      processApiResponse('{"name": "Bob", "age": -5}');
      expect(logs.last, contains('Invalid JSON data'));

      processApiResponse('not valid json');
      expect(logs.last, contains('Failed to decode JSON'));
    });

    test('working with validated data allows typed access', () {
      final userSchema = buildUserSchema();
      final result = userSchema.safeParse({
        'name': 'Alice',
        'age': 30,
        'email': 'alice@example.com',
      });

      expect(result.isOk, isTrue);
      final data = result.getOrThrow()!;
      final name = data['name'] as String;
      final age = data['age'] as int;
      expect(name, equals('Alice'));
      expect(age, equals(30));
    });

    test('validated JSON-native data can be encoded', () {
      final result = buildUserSchema().safeParse({
        'name': 'Alice',
        'age': 30,
        'email': 'alice@example.com',
      });

      final validData = result.getOrThrow()!;
      final encoded = jsonEncode(validData);

      expect(jsonDecode(encoded), equals(validData));
    });

    test('codec runtime values are encoded to their JSON boundary', () {
      final eventSchema = Ack.object({
        'name': Ack.string(),
        'startsAt': Ack.datetime(),
      });
      final event = eventSchema.parse({
        'name': 'Launch',
        'startsAt': '2026-01-15T14:00:00Z',
      });

      final boundaryData = eventSchema.encode(event);
      final encoded = jsonEncode(boundaryData);

      expect(
        jsonDecode(encoded),
        equals({'name': 'Launch', 'startsAt': '2026-01-15T14:00:00.000Z'}),
      );
    });

    test('manual schema example mirrors generated schema usage', () {
      final generatedUserSchema = Ack.object({
        'name': Ack.string(),
        'email': Ack.string(),
        'age': Ack.integer(),
      });

      const jsonString =
          '{"name": "Alice", "email": "alice@example.com", "age": 30}';
      final jsonData = jsonDecode(jsonString);

      final result = generatedUserSchema.safeParse(jsonData);
      expect(result.isOk, isTrue);
      final user = result.getOrThrow()!;
      expect(user['email'], equals('alice@example.com'));
    });

    test('doc copy focuses on validated data and immutable models', () async {
      final content = await File(
        '../../docs/core-concepts/json-serialization.mdx',
      ).readAsString();

      expect(
        content,
        isNot(
          contains('Ack schemas convert between Dart models and JSON data'),
        ),
      );
      expect(content, contains('generated immutable model'));
    });
  });
}
