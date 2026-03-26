import 'dart:convert';

import 'package:ack_example/schema_types_edge_cases.dart';
import 'package:ack_example/schema_types_primitives.dart';
import 'package:ack_example/schema_types_simple.dart';
import 'package:ack_example/schema_types_transforms.dart';
import 'package:test/test.dart';

void main() {
  group('Extension type toJson', () {
    test('object extension type returns map data', () {
      final user = UserType.parse({'name': 'Alice', 'age': 30, 'active': true});

      expect(user.toJson(), {'name': 'Alice', 'age': 30, 'active': true});
      expect(user.toJson(), isA<Map<String, Object?>>());
    });

    test('primitive extension type returns wrapped value', () {
      final password = PasswordType.parse('mySecurePassword123');

      expect(password.toJson(), 'mySecurePassword123');
      expect(password.toJson(), isA<String>());
    });

    test('collection extension type returns wrapped list', () {
      final tags = TagsType.parse(['dart', 'ack']);

      expect(tags.toJson(), ['dart', 'ack']);
      expect(tags.toJson(), isA<List<String>>());
    });

    test('transformed primitive extension type returns wire value', () {
      final color = ColorType.parse('red');

      expect(color.toJson(), 'red');
      expect(color.parsed, isA<Color>());
    });

    test('transformed object extension type returns JSON-safe wire values', () {
      final profile = ProfileType.parse({
        'homepage': 'https://example.com',
        'birthday': '2024-01-15',
        'lastLogin': '2024-01-16T11:45:00Z',
        'timeout': 1500,
        'links': ['https://example.com/docs'],
        'favoriteColor': 'blue',
        'slug': 'hello',
        'accent': 'red',
        'colors': ['red', 'green'],
        'customColors': ['cyan'],
        'tagList': ['dart', 'ack'],
      });

      expect(profile.toJson()['homepage'], 'https://example.com');
      expect(profile.homepage, 'https://example.com');
      expect(profile.homepageParsed, isA<Uri>());
      expect(() => jsonEncode(profile.toJson()), returnsNormally);
    });

    test('transformed object copyWith keeps wrapper fields JSON-safe', () {
      final profile = ProfileType.parse({
        'homepage': 'https://example.com',
        'birthday': '2024-01-15',
        'lastLogin': '2024-01-16T11:45:00Z',
        'timeout': 1500,
        'links': ['https://example.com/docs'],
        'favoriteColor': 'blue',
        'slug': 'hello',
        'accent': 'red',
        'colors': ['red', 'green'],
        'customColors': ['cyan'],
        'tagList': ['dart', 'ack'],
      });

      final updated = profile.copyWith(
        accent: ColorType.parse('green'),
        colors: [ColorType.parse('green')],
        homepage: 'https://example.com/app',
      );

      expect(updated.toJson()['accent'], 'green');
      expect(updated.toJson()['colors'], ['green']);
      expect(updated.homepageParsed, Uri.parse('https://example.com/app'));
      expect(updated.accentParsed.value, 'green');
      expect(updated.colorsParsed.map((color) => color.value), ['green']);
      expect(() => jsonEncode(updated.toJson()), returnsNormally);
    });

    test('copyWith preserves omission for optional non-nullable fields', () {
      final modifier = ModifierType.parse({
        'requiredField': 'hello',
        'nullableField': null,
      });

      final updated = modifier.copyWith(nullableField: 'present');

      expect(updated.toJson()['requiredField'], 'hello');
      expect(updated.toJson()['nullableField'], 'present');
      expect(updated.toJson().containsKey('optionalField'), isFalse);
      expect(updated.toJson().containsKey('optionalNullable'), isFalse);
      expect(updated.toJson().containsKey('nullableOptional'), isFalse);
    });
  });
}
