import 'package:ack/src/helpers.dart';
import 'package:test/test.dart';

void main() {
  group('prettyJson', () {
    test('should format a valid map', () {
      final map = {'b': 2, 'a': 1};
      final expected = '''
{
  "b": 2,
  "a": 1
}''';
      expect(prettyJson(map), expected);
    });

    test('should format a valid list', () {
      final list = [1, 'two', true];
      final expected = '''
[
  1,
  "two",
  true
]''';
      expect(prettyJson(list), expected);
    });

    test('should handle non-serializable objects gracefully', () {
      final object = _NonSerializable();
      expect(prettyJson(object), object.toString());
    });

    test('should handle null input', () {
      expect(prettyJson(null), 'null');
    });
  });

  group('findClosestStringMatch', () {
    final allowed = ['Apple', 'Banana', 'Orange', 'Grapefruit', 'Pineapple'];

    test('should find an exact case-insensitive match', () {
      expect(findClosestStringMatch('apple', allowed), 'Apple');
      expect(findClosestStringMatch('BANANA', allowed), 'Banana');
    });

    test('should find a prefix match', () {
      expect(findClosestStringMatch('App', allowed), 'Apple');
      expect(findClosestStringMatch('Pine', allowed), 'Pineapple');
    });

    test('should find a contains match for short strings', () {
      final shortAllowed = ['err', 'warn', 'info'];
      expect(findClosestStringMatch('error', shortAllowed), 'err');
      expect(findClosestStringMatch('i', shortAllowed), 'info');
    });

    test('should find a match using Levenshtein distance for typos', () {
      expect(findClosestStringMatch('Banna', allowed), 'Banana');
      expect(findClosestStringMatch('Ornge', allowed), 'Orange');
    });

    test('should return null if no close match is found', () {
      expect(findClosestStringMatch('Kiwis', allowed), isNull);
    });

    test('should return null for empty allowed list', () {
      expect(findClosestStringMatch('anything', []), isNull);
    });

    test('should return null for empty input value', () {
      expect(findClosestStringMatch('', allowed), isNull);
    });

    test('should respect the similarity threshold', () {
      expect(
        findClosestStringMatch('Bna', allowed, similarityThreshold: 0.8),
        isNull,
      );
      expect(
        findClosestStringMatch('Bna', allowed, similarityThreshold: 0.4),
        'Banana',
      );
    });
  });

  group('buildDidYouMeanSuggestion', () {
    final allowed = ['active', 'inactive'];

    test('should return a suggestion with a leading space', () {
      expect(
        buildDidYouMeanSuggestion('actve', allowed),
        ' Did you mean "active"?',
      );
    });

    test('should return empty string when no close match is found', () {
      expect(buildDidYouMeanSuggestion('unknown', allowed), '');
    });

    test('should return empty string when closest match equals input', () {
      expect(buildDidYouMeanSuggestion('active', allowed), '');
    });
  });
}

class _NonSerializable {}
