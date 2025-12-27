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

  group('deepMerge', () {
    test('should merge maps with no overlapping keys', () {
      final map1 = {'a': 1};
      final map2 = {'b': 2};
      expect(deepMerge(map1, map2), {'a': 1, 'b': 2});
    });

    test('should overwrite non-map values from the second map', () {
      final map1 = {'a': 1, 'b': 1};
      final map2 = {'b': 2, 'c': 3};
      expect(deepMerge(map1, map2), {'a': 1, 'b': 2, 'c': 3});
    });

    test('should recursively merge nested maps', () {
      final map1 = {
        'a': 1,
        'nested': {'x': 10, 'y': 20},
      };
      final map2 = {
        'b': 2,
        'nested': {'y': 30, 'z': 40},
      };
      expect(deepMerge(map1, map2), {
        'a': 1,
        'b': 2,
        'nested': {'x': 10, 'y': 30, 'z': 40},
      });
    });

    test('should handle one map being empty', () {
      final map = {'a': 1};
      expect(deepMerge(map, {}), map);
      expect(deepMerge({}, map), map);
    });
  });

  group('IterableExtensions', () {
    group('duplicates', () {
      test('should return duplicate elements', () {
        final list = [1, 2, 2, 3, 4, 4, 4];
        expect(list.duplicates, equals([2, 4, 4]));
      });

      test('should return an empty iterable if there are no duplicates', () {
        final list = [1, 2, 3, 4, 5];
        expect(list.duplicates, isEmpty);
      });
    });

    group('hasDuplicates', () {
      test('should return true if there are duplicates', () {
        final list = [1, 2, 3, 2];
        expect(list.hasDuplicates, isTrue);
      });

      test('should return false if there are no duplicates', () {
        final list = [1, 2, 3, 4];
        expect(list.hasDuplicates, isFalse);
      });
    });

    group('firstWhereOrNull', () {
      test('should return the first element that satisfies the test', () {
        final list = [1, 2, 3, 4, 5];
        expect(list.firstWhereOrNull((e) => e > 3), 4);
      });

      test('should return null if no element satisfies the test', () {
        final list = [1, 2, 3, 4, 5];
        expect(list.firstWhereOrNull((e) => e > 5), isNull);
      });
    });
  });
}

class _NonSerializable {}
