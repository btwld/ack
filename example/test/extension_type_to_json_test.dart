import 'dart:convert';

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
  });

  group('Representation-first transforms', () {
    test('ColorType stores wire String, toJson returns String', () {
      final color = ColorType.parse('red');

      expect(color.toJson(), 'red');
      expect(color.toJson(), isA<String>());
      expect(jsonEncode(color.toJson()), '"red"');
    });

    test('ColorType.parsed returns transformed Color', () {
      final color = ColorType.parse('blue');

      expect(color.parsed, isA<Color>());
      expect(color.parsed.value, 'blue');
    });

    test('ProfileType stores wire types, toJson returns serializable map', () {
      final profile = ProfileType.parse({
        'homepage': 'https://example.com',
        'birthday': '2000-01-15',
        'lastLogin': '2025-03-20T10:30:00Z',
        'timeout': 5000,
        'links': ['https://a.com', 'https://b.com'],
        'favoriteColor': 'green',
        'slug': 'test',
        'accent': 'purple',
        'colors': ['red', 'blue'],
        'customColors': ['cyan', 'magenta'],
        'tagList': ['dart', 'ack'],
      });

      // Primary getters return representation (wire) types
      expect(profile.homepage, 'https://example.com');
      expect(profile.homepage, isA<String>());
      expect(profile.birthday, '2000-01-15');
      expect(profile.birthday, isA<String>());
      expect(profile.timeout, 5000);
      expect(profile.timeout, isA<int>());
      expect(profile.links, isA<List<String>>());
      expect(profile.favoriteColor, 'green');
      expect(profile.slug, 'test');

      // Parsed getters return transformed types
      expect(profile.homepageParsed, isA<Uri>());
      expect(profile.homepageParsed.host, 'example.com');
      expect(profile.birthdayParsed, isA<DateTime>());
      expect(profile.birthdayParsed.year, 2000);
      expect(profile.timeoutParsed, isA<Duration>());
      expect(profile.timeoutParsed.inMilliseconds, 5000);
      expect(profile.favoriteColorParsed, isA<Color>());
      expect(profile.favoriteColorParsed.value, 'green');

      // Named ref getters
      expect(profile.accent, isA<ColorType>());
      expect(profile.accentParsed, isA<Color>());
      expect(profile.accentParsed.value, 'purple');

      // List of named refs
      expect(profile.colors, isA<List<ColorType>>());
      expect(profile.colorsParsed.map((c) => c.value), ['red', 'blue']);

      // toJson returns serializable map
      final json = profile.toJson();
      expect(json, isA<Map<String, Object?>>());
      expect(() => jsonEncode(json), returnsNormally);
    });

    test('ProfileType copyWith preserves representation types', () {
      final profile = ProfileType.parse({
        'homepage': 'https://example.com',
        'birthday': '2000-01-15',
        'lastLogin': '2025-03-20T10:30:00Z',
        'timeout': 5000,
        'links': ['https://a.com'],
        'favoriteColor': 'green',
        'slug': 'test',
        'accent': 'purple',
        'colors': ['red'],
        'customColors': ['cyan'],
        'tagList': ['dart'],
      });

      final updated = profile.copyWith(
        homepage: 'https://new.com',
        timeout: 3000,
        accent: ColorType.parse('yellow'),
      );

      expect(updated.homepage, 'https://new.com');
      expect(updated.timeout, 3000);
      expect(updated.accent.toJson(), 'yellow');
      // Unchanged fields preserved
      expect(updated.birthday, '2000-01-15');
      expect(updated.favoriteColor, 'green');
    });
  });
}
