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

    test('returns contains match for short values', () {
      final result = findClosestStringMatch(
        'ello',
        ['Hello', 'World', 'Hey'],
      );
      // 'ello' is contained in 'Hello' and Hello is <=8 chars
      expect(result, 'Hello');
    });

    test('returns contains match for short values only', () {
      final result = findClosestStringMatch(
        'Hello, world!',
        ['world'],
      );
      // 'world' is short (<=8 chars) and contained in input
      expect(result, 'world');
    });

    test('returns closest match when edit distance is reasonable', () {
      final result = findClosestStringMatch(
        'hallow',
        ['hello', 'hollow', 'yellow'],
      );
      // 'hallow' is very similar to 'hollow' (1 character difference)
      expect(result, 'hollow');
    });

    test('returns exact match when available', () {
      final result = findClosestStringMatch(
        'abc-def',
        ['abc', 'c-d', 'f', 'abc-def'],
      );
      // Exact match found and returned immediately
      expect(result, 'abc-def');
    });

    test('returns null when no reasonable match found', () {
      final result = findClosestStringMatch(
        'xyz',
        ['hello', 'world', 'test'],
      );
      // No prefix/contains match found
      expect(result, isNull);
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
  });

  group('isJsonValue', () {
    test('returns true for valid JSON object strings', () {
      expect(looksLikeJson('{}'), isTrue);
      expect(looksLikeJson('{"key": "value"}'), isTrue);
      expect(looksLikeJson('{"nested": {"key": "value"}}'), isTrue);
    });

    test('returns true for valid JSON array strings', () {
      expect(looksLikeJson('[]'), isTrue);
      expect(looksLikeJson('[1, 2, 3]'), isTrue);
      expect(looksLikeJson('[{"key": "value"}]'), isTrue);
    });

    test('returns true with whitespace around valid JSON', () {
      expect(looksLikeJson('  {}  '), isTrue);
      expect(looksLikeJson('\n{}\n'), isTrue);
      expect(looksLikeJson('\t[]  '), isTrue);
      expect(looksLikeJson('  \n  {"key": "value"}  \n  '), isTrue);
    });

    test('returns false for empty string', () {
      expect(looksLikeJson(''), isFalse);
    });

    test('returns false for whitespace only', () {
      expect(looksLikeJson('   '), isFalse);
      expect(looksLikeJson('\n\t  \n'), isFalse);
    });

    test('returns false for invalid JSON format', () {
      expect(looksLikeJson('{'), isFalse); // Missing closing brace
      expect(looksLikeJson('}'), isFalse); // Missing opening brace
      expect(looksLikeJson('['), isFalse); // Missing closing bracket
      expect(looksLikeJson(']'), isFalse); // Missing opening bracket
      expect(looksLikeJson('{"unclosed": "object"'), isFalse);
      expect(looksLikeJson('[1, 2,'), isFalse);
    });

    test('returns false for non-JSON strings', () {
      expect(looksLikeJson('hello'), isFalse);
      expect(looksLikeJson('123'), isFalse);
      expect(looksLikeJson('true'), isFalse);
      expect(looksLikeJson('null'), isFalse);
    });

    test('returns false for mismatched brackets', () {
      expect(looksLikeJson('{]'), isFalse);
      expect(looksLikeJson('[}'), isFalse);
    });
  });
}
