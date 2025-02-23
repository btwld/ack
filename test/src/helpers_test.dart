import 'package:ack/src/helpers.dart';
import 'package:test/test.dart';

void main() {
  group('findClosestStringMatch', () {
    test('returns null when allowedValues is empty', () {
      final result = findClosestStringMatch('Hello', []);
      expect(result, isNull);
    });

    test('returns direct match if value is exactly in allowedValues', () {
      final result = findClosestStringMatch(
        'Hello',
        ['Hello', 'World', 'Hey'],
      );
      expect(result, 'Hello', reason: 'Exact match should take precedence');
    });

    test('returns direct match if normalizedValue is contained in allowedValue',
        () {
      final result = findClosestStringMatch(
        'ello',
        ['Hello', 'World', 'Hey'],
      );
      // 'ello' is contained in 'Hello' (case-insensitive)
      expect(result, 'Hello');
    });

    test(
        'returns direct match if allowedValue is contained in the normalizedValue',
        () {
      final result = findClosestStringMatch(
        'Hello, world!',
        ['world'],
      );
      // 'world' is contained in "Hello, world!"
      expect(result, 'world');
    });

    test('picks the closest match from multiple allowed values', () {
      final result = findClosestStringMatch(
        'hallow',
        ['hello', 'hollow', 'yellow'],
      );
      // "hallow" -> "hollow" distance is smaller than "hallow" -> "hello" or "hallow" -> "yellow"
      // "hallow" vs "hollow" differs by 1 char: distance=1
      // "hallow" vs "hello" differs by more
      expect(result, 'hollow');
    });

    test(
        'returns the last perfect match in the list if multiple direct containments exist',
        () {
      // By default, your loop does not break, so you get the last direct match found.
      // This test might be changed if you break on the FIRST perfect match.
      final result = findClosestStringMatch(
        'abc-def',
        ['abc', 'c-d', 'f', 'abc-def'],
      );
      // 'abc-def' fully contains 'abc-def'
      // Actually in the code: 'abc-def'.contains('abc'), 'abc-def'.contains('c-d'), 'abc-def'.contains('f'), etc.
      // The last one is exactly 'abc-def', so that is also a perfect match, set bestScore=1.0.
      // The loop continues and ends with bestMatch='abc-def'.
      expect(result, 'abc-def');
    });
  });

  group('levenshtein', () {
    test('distance is 0 for identical strings', () {
      expect(levenshtein('abc', 'abc'), 0);
    });

    test('distance is length of t if s is empty', () {
      expect(levenshtein('', 'abc'), 3);
    });

    test('distance is length of s if t is empty', () {
      expect(levenshtein('abc', ''), 3);
    });

    test('calculates distance correctly for small examples', () {
      // One substitution
      expect(levenshtein('cat', 'cut'), 1);
      // One insertion
      expect(levenshtein('cat', 'cart'), 1);
      // One deletion
      expect(levenshtein('cart', 'cat'), 1);
      // Mixed edits
      expect(levenshtein('kitten', 'sitting'), 3);
    });
  });
}
