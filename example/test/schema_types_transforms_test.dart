import 'package:test/test.dart';

import '../lib/schema_types_transforms.dart';

void main() {
  group('Transform schema examples', () {
    test('top-level transformed wrappers preserve the transformed value', () {
      final color = ColorType.parse('#12AB34');

      expect(color, isA<ColorType>());
      expect(color.value, '#12AB34');
    });

    test('profile wrapper exposes transformed object getters', () {
      final profile = ProfileType.parse({
        'homepage': 'https://example.com',
        'birthday': '2025-06-15',
        'lastLogin': '2025-06-15T10:30:00Z',
        'timeout': 1500,
        'links': ['https://example.com/a', 'https://example.com/b'],
        'favoriteColor': '#FF5733',
        'slug': 'docs',
        'accent': '#00FF00',
        'colors': ['#111111', '#222222'],
        'customColors': ['#333333'],
        'tagList': ['alpha', 'beta'],
      });

      expect(profile.homepage, Uri.parse('https://example.com'));
      expect(profile.birthday.year, 2025);
      expect(profile.birthday.month, 6);
      expect(profile.birthday.day, 15);
      expect(profile.lastLogin.toUtc(), DateTime.parse('2025-06-15T10:30:00Z'));
      expect(profile.timeout, const Duration(milliseconds: 1500));
      expect(profile.links, [
        Uri.parse('https://example.com/a'),
        Uri.parse('https://example.com/b'),
      ]);
      expect(profile.favoriteColor.value, '#FF5733');
      expect(profile.slug, 'docs#');
      expect(profile.accent.value, '#00FF00');
      expect(profile.colors.map((color) => color.value), [
        '#111111',
        '#222222',
      ]);
      expect(profile.customColors.map((color) => color.value), ['#333333']);
      expect(profile.tagList.value, ['alpha', 'beta']);
    });
  });
}
