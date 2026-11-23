import 'package:ack_example/schema_types_transforms.dart';
import 'package:test/test.dart';

void main() {
  group('Codec schema examples', () {
    test('top-level codec models preserve the decoded value', () {
      final color = ColorModel.parse('#12AB34');

      expect(color, isA<ColorModel>());
      expect(color.value.value, '#12AB34');
    });

    test('profile model exposes decoded codec values', () {
      final profile = Profile.parse({
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
      expect(profile.accent.value.value, '#00FF00');
      expect(profile.colors.map((color) => color.value.value), [
        '#111111',
        '#222222',
      ]);
      expect(profile.customColors.map((color) => color.value), ['#333333']);
      expect(profile.tagList.value, ['alpha', 'beta']);
    });
  });
}
