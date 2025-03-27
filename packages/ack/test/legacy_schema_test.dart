import 'dart:convert';

// Import the Schema class from the user's code
import 'package:ack/src/legacy_schema.dart';
import 'package:test/test.dart';

void main() {
  group('Legacy Schema Tests', () {
    group('toJson and fromJson Conversion', () {
      test('String schema roundtrip conversion', () {
        final originalSchema = Schema.string(
          description: 'A string value',
          nullable: true,
        );

        final jsonString = originalSchema.toJson();
        final parsedSchema = Schema.fromJson(jsonString);

        // Convert back to json to compare equality
        final reparsedJson = parsedSchema.toJson();

        // Convert both to maps for better comparison in test failure messages
        final originalMap = jsonDecode(jsonString);
        final parsedMap = jsonDecode(reparsedJson);

        expect(parsedMap, equals(originalMap));
      });

      test('Enum string schema roundtrip conversion', () {
        final originalSchema = Schema.enumString(
          enumValues: ['red', 'green', 'blue'],
          description: 'Color options',
          nullable: false,
        );

        final jsonString = originalSchema.toJson();
        final parsedSchema = Schema.fromJson(jsonString);

        final reparsedJson = parsedSchema.toJson();

        final originalMap = jsonDecode(jsonString);
        final parsedMap = jsonDecode(reparsedJson);

        expect(parsedMap, equals(originalMap));
      });

      test('Number schema roundtrip conversion', () {
        final originalSchema = Schema.number(
          description: 'A floating point value',
          format: 'double',
          nullable: true,
        );

        final jsonString = originalSchema.toJson();
        final parsedSchema = Schema.fromJson(jsonString);

        final reparsedJson = parsedSchema.toJson();

        final originalMap = jsonDecode(jsonString);
        final parsedMap = jsonDecode(reparsedJson);

        expect(parsedMap, equals(originalMap));
      });

      test('Integer schema roundtrip conversion', () {
        final originalSchema = Schema.integer(
          description: 'An integer value',
          format: 'int32',
          nullable: false,
        );

        final jsonString = originalSchema.toJson();
        final parsedSchema = Schema.fromJson(jsonString);

        final reparsedJson = parsedSchema.toJson();

        final originalMap = jsonDecode(jsonString);
        final parsedMap = jsonDecode(reparsedJson);

        expect(parsedMap, equals(originalMap));
      });

      test('Boolean schema roundtrip conversion', () {
        final originalSchema = Schema.boolean(
          description: 'A boolean value',
          nullable: false,
        );

        final jsonString = originalSchema.toJson();
        final parsedSchema = Schema.fromJson(jsonString);

        final reparsedJson = parsedSchema.toJson();

        final originalMap = jsonDecode(jsonString);
        final parsedMap = jsonDecode(reparsedJson);

        expect(parsedMap, equals(originalMap));
      });

      test('DateTime schema roundtrip conversion', () {
        final originalSchema = Schema.dateTime(
          description: 'A date and time',
          nullable: true,
        );

        final jsonString = originalSchema.toJson();
        final parsedSchema = Schema.fromJson(jsonString);

        final reparsedJson = parsedSchema.toJson();

        final originalMap = jsonDecode(jsonString);
        final parsedMap = jsonDecode(reparsedJson);

        expect(parsedMap, equals(originalMap));
      });

      test('Array schema roundtrip conversion', () {
        final originalSchema = Schema.array(
          items: Schema.string(description: 'A string item'),
          description: 'An array of strings',
          nullable: false,
        );

        final jsonString = originalSchema.toJson();
        final parsedSchema = Schema.fromJson(jsonString);

        final reparsedJson = parsedSchema.toJson();

        final originalMap = jsonDecode(jsonString);
        final parsedMap = jsonDecode(reparsedJson);

        expect(parsedMap, equals(originalMap));
      });

      test('Object schema roundtrip conversion', () {
        final originalSchema = Schema.object(
          properties: {
            'name': Schema.string(description: 'User name'),
            'age': Schema.integer(description: 'User age'),
            'tags': Schema.array(
              items: Schema.string(),
              description: 'User tags',
            ),
          },
          requiredProperties: ['name', 'age'],
          description: 'A user object',
          nullable: false,
        );

        final jsonString = originalSchema.toJson();
        final parsedSchema = Schema.fromJson(jsonString);

        final reparsedJson = parsedSchema.toJson();

        final originalMap = jsonDecode(jsonString);
        final parsedMap = jsonDecode(reparsedJson);

        expect(parsedMap, equals(originalMap));
      });

      test('Complex nested object schema roundtrip conversion', () {
        final originalSchema = Schema.object(
          properties: {
            'id': Schema.string(description: 'Record ID'),
            'user': Schema.object(
              properties: {
                'name': Schema.string(),
                'email': Schema.string(description: 'Email address'),
                'preferences': Schema.object(
                  properties: {
                    'theme': Schema.enumString(
                      enumValues: ['light', 'dark', 'system'],
                      description: 'UI theme',
                    ),
                    'notifications':
                        Schema.boolean(description: 'Enable notifications'),
                  },
                  requiredProperties: ['theme'],
                ),
              },
              requiredProperties: ['name', 'email'],
            ),
            'items': Schema.array(
              items: Schema.object(
                properties: {
                  'itemId': Schema.string(),
                  'quantity': Schema.integer(),
                  'price': Schema.number(format: 'double'),
                },
                requiredProperties: ['itemId', 'quantity', 'price'],
              ),
            ),
            'createdAt': Schema.dateTime(),
          },
          requiredProperties: ['id', 'user', 'items'],
          description: 'A complex order record',
        );

        final jsonString = originalSchema.toJson();
        final parsedSchema = Schema.fromJson(jsonString);

        final reparsedJson = parsedSchema.toJson();

        final originalMap = jsonDecode(jsonString);
        final parsedMap = jsonDecode(reparsedJson);

        expect(parsedMap, equals(originalMap));
      });
    });
  });
}
