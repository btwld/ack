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

  // Group all tests under 'deepMerge' for clarity.
  group('deepMerge', () {
    test('merges two empty maps', () {
      final map1 = <String, Object?>{};
      final map2 = <String, Object?>{};
      final result = deepMerge(map1, map2);
      expect(result, isEmpty);
    });

    test('merges map2 into map1 without conflicts', () {
      final map1 = <String, Object?>{'a': 1};
      final map2 = <String, Object?>{'b': 2};
      final result = deepMerge(map1, map2);
      expect(result, equals({'a': 1, 'b': 2}));
    });

    test('overrides non-map values in map1 with map2', () {
      final map1 = <String, Object?>{'a': 1};
      final map2 = <String, Object?>{'a': 2};
      final result = deepMerge(map1, map2);
      expect(result, equals({'a': 2}));
    });

    test('recursively merges nested maps', () {
      final map1 = <String, Object?>{
        'a': {'b': 1}
      };
      final map2 = <String, Object?>{
        'a': {'c': 2}
      };
      final result = deepMerge(map1, map2);
      expect(
          result,
          equals({
            'a': {'b': 1, 'c': 2}
          }));
    });

    test('overrides nested map with non-map value', () {
      final map1 = <String, Object?>{
        'a': {'b': 1}
      };
      final map2 = <String, Object?>{'a': 2};
      final result = deepMerge(map1, map2);
      expect(result, equals({'a': 2}));
    });

    test('overrides non-map value with nested map', () {
      final map1 = <String, Object?>{'a': 1};
      final map2 = <String, Object?>{
        'a': {'b': 2}
      };
      final result = deepMerge(map1, map2);
      expect(
          result,
          equals({
            'a': {'b': 2}
          }));
    });

    test('handles null values in map2', () {
      final map1 = <String, Object?>{'a': 1};
      final map2 = <String, Object?>{'a': null};
      final result = deepMerge(map1, map2);
      expect(result, equals({'a': null}));
    });

    test('handles null values in map1', () {
      final map1 = <String, Object?>{'a': null};
      final map2 = <String, Object?>{'a': 2};
      final result = deepMerge(map1, map2);
      expect(result, equals({'a': 2}));
    });

    test('preserves keys unique to map1', () {
      final map1 = <String, Object?>{'a': 1, 'b': 2};
      final map2 = <String, Object?>{'c': 3};
      final result = deepMerge(map1, map2);
      expect(result, equals({'a': 1, 'b': 2, 'c': 3}));
    });

    test('preserves keys unique to map2', () {
      final map1 = <String, Object?>{'a': 1};
      final map2 = <String, Object?>{'b': 2, 'c': 3};
      final result = deepMerge(map1, map2);
      expect(result, equals({'a': 1, 'b': 2, 'c': 3}));
    });

    test('merges deeply nested maps', () {
      final map1 = <String, Object?>{
        'a': {
          'b': {'c': 1}
        }
      };
      final map2 = <String, Object?>{
        'a': {
          'b': {'d': 2}
        }
      };
      final result = deepMerge(map1, map2);
      expect(
          result,
          equals({
            'a': {
              'b': {'c': 1, 'd': 2}
            }
          }));
    });

    test('handles lists as non-map values', () {
      final map1 = <String, Object?>{
        'a': [1, 2]
      };
      final map2 = <String, Object?>{
        'a': [3, 4]
      };
      final result = deepMerge(map1, map2);
      expect(
          result,
          equals({
            'a': [3, 4]
          }));
    });

    test('does not modify original maps', () {
      final map1 = <String, Object?>{'a': 1};
      final map2 = <String, Object?>{'b': 2};
      final result = deepMerge(map1, map2);
      expect(map1, equals({'a': 1}));
      expect(map2, equals({'b': 2}));
      expect(result, equals({'a': 1, 'b': 2}));
    });

    test('handles maps with different nested structures', () {
      final map1 = <String, Object?>{
        'a': {'b': 1},
        'c': 2
      };
      final map2 = <String, Object?>{
        'a': {'d': 3},
        'e': 4
      };
      final result = deepMerge(map1, map2);
      expect(
          result,
          equals({
            'a': {'b': 1, 'd': 3},
            'c': 2,
            'e': 4
          }));
    });

    test('overrides nested map with null', () {
      final map1 = <String, Object?>{
        'a': {'b': 1}
      };
      final map2 = <String, Object?>{'a': null};
      final result = deepMerge(map1, map2);
      expect(result, equals({'a': null}));
    });

    test('merges when map2 has additional nested maps', () {
      final map1 = <String, Object?>{
        'a': {'b': 1}
      };
      final map2 = <String, Object?>{
        'a': {
          'c': {'d': 2}
        }
      };
      final result = deepMerge(map1, map2);
      expect(
          result,
          equals({
            'a': {
              'b': 1,
              'c': {'d': 2}
            }
          }));
    });
  });

  // Group tests under IterableExt for better organization
  group('IterableExt', () {
    // Tests for isUniqueValues
    group('hasUniqueValues', () {
      test('empty iterable returns true', () {
        expect([].areUnique, isTrue);
      });

      test('single element returns true', () {
        expect([1].areUnique, isTrue);
      });

      test('multiple unique elements returns true', () {
        expect([1, 2, 3].areUnique, isTrue);
      });

      test('list with duplicates returns false', () {
        expect([1, 2, 2, 3].areUnique, isFalse);
      });

      test('all elements identical returns false', () {
        expect([2, 2, 2].areUnique, isFalse);
      });

      test('single null element returns true', () {
        expect([null].areUnique, isTrue);
      });

      test('multiple null elements returns false', () {
        expect([null, null].areUnique, isFalse);
      });

      test('mixed elements with duplicate null returns false', () {
        expect([1, null, 2, null].areUnique, isFalse);
      });

      test('unique strings returns true', () {
        expect(['a', 'b', 'c'].areUnique, isTrue);
      });

      test('strings with duplicates returns false', () {
        expect(['a', 'b', 'a'].areUnique, isFalse);
      });

      test('set with unique elements returns true', () {
        expect({1, 2, 3}.areUnique, isTrue);
      });
    });

    // Tests for duplicates
    group('getNonUniqueValues', () {
      test('empty iterable returns empty list', () {
        expect([].duplicates, isEmpty);
      });

      test('single element returns empty list', () {
        expect([1].duplicates, isEmpty);
      });

      test('multiple unique elements returns empty list', () {
        expect([1, 2, 3].duplicates, isEmpty);
      });

      test('list with single duplicate returns that duplicate', () {
        expect([1, 2, 2, 3].duplicates, equals([2]));
      });

      test('list with all elements identical returns duplicates', () {
        expect([2, 2, 2].duplicates, equals([2, 2]));
      });

      test('single null element returns empty list', () {
        expect([null].duplicates, isEmpty);
      });

      test('multiple null elements returns duplicate nulls', () {
        expect([null, null].duplicates, equals([null]));
      });

      test('mixed elements with duplicate null returns null', () {
        expect([1, null, 2, null].duplicates, equals([null]));
      });

      test('unique strings returns empty list', () {
        expect(['a', 'b', 'c'].duplicates, isEmpty);
      });

      test('strings with duplicates returns duplicate', () {
        expect(['a', 'b', 'a'].duplicates, equals(['a']));
      });

      test('multiple duplicates returns all duplicate instances', () {
        expect(
          ['a', 'a', 'b', 'b', 'b'].duplicates,
          equals(['a', 'b', 'b']),
        );
      });

      test('set returns empty list since no duplicates', () {
        expect({1, 2, 3}.duplicates, isEmpty);
      });
    });

    // Tests for hasAll()
    group('hasAll', () {
      test('empty list has all elements of empty iterable', () {
        expect([].containsAll([]), isTrue);
      });

      test('empty list does not have all of non-empty iterable', () {
        expect([].containsAll([1]), isFalse);
      });

      test('non-empty list has all of empty iterable', () {
        expect([1, 2, 3].containsAll([]), isTrue);
      });

      test('list contains all elements of its subset', () {
        expect([1, 2, 3].containsAll([2, 3]), isTrue);
      });

      test('list does not contain all elements of non-subset', () {
        expect([1, 2, 3].containsAll([2, 4]), isFalse);
      });

      test('list with null contains [null]', () {
        expect([1, null, 2].containsAll([null]), isTrue);
      });

      test('list with duplicates contains single element', () {
        expect([1, 2, 2, 3].containsAll([2]), isTrue);
      });

      test('unique strings contain subset', () {
        expect(['a', 'b', 'c'].containsAll(['b', 'c']), isTrue);
      });

      test('strings do not contain non-subset', () {
        expect(['a', 'b'].containsAll(['b', 'c']), isFalse);
      });

      test('list contains iterable with duplicate elements', () {
        expect([1, 2, 3].containsAll([2, 2, 2]), isTrue);
      });

      test('list missing one element does not contain all', () {
        expect([1, 2, 3].containsAll([2, 3, 4]), isFalse);
      });

      test('list has all elements of a set', () {
        expect([1, 2, 3].containsAll({2, 3}), isTrue);
      });

      test('list does not have all elements of a set with extra element', () {
        expect([1, 2, 3].containsAll({2, 4}), isFalse);
      });
    });
  });
}
