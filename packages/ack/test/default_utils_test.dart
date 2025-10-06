import 'package:ack/src/utils/default_utils.dart';
import 'package:test/test.dart';

void main() {
  group('cloneDefault', () {
    test('clones Map<String, int> literals into an unmodifiable MapValue', () {
      final original = <String, int>{'count': 1};

      final cloned = cloneDefault(original) as Map<String, Object?>;

      expect(cloned, equals({'count': 1}));
      expect(cloned, isNot(same(original)));
      expect(() => cloned['count'] = 2, throwsUnsupportedError);

      original['count'] = 2;
      expect(cloned['count'], 1);
    });

    test('deep clones nested maps and lists', () {
      final original = {
        'a': [
          1,
          {'b': 2},
        ],
        'nested': {
          'c': [3],
        },
      };

      final cloned = cloneDefault(original) as Map<String, Object?>;

      final clonedList = cloned['a'] as List<Object?>;
      final clonedInnerMap = clonedList[1] as Map<String, Object?>;
      final clonedNested = cloned['nested'] as Map<String, Object?>;

      expect(() => clonedList.add(42), throwsUnsupportedError);
      expect(() => clonedInnerMap['b'] = 3, throwsUnsupportedError);
      expect(() => clonedNested['c'] = [], throwsUnsupportedError);

      (original['a'] as List)[1] = {'b': 99};
      (original['nested'] as Map)['c'] = [4];

      final innerMap =
          (cloned['a'] as List<Object?>)[1] as Map<String, Object?>;
      expect(innerMap['b'], 2);
      expect((cloned['nested'] as Map<String, Object?>)['c'], equals([3]));
    });

    test('clones maps with non-string keys without losing key identity', () {
      final original = {
        1: ['a'],
      };

      final cloned = cloneDefault(original) as Map<Object?, Object?>;
      final clonedList = cloned[1] as List<Object?>;

      expect(() => cloned[1] = ['b'], throwsUnsupportedError);
      expect(() => clonedList.add('c'), throwsUnsupportedError);

      (original[1] as List).add('b');
      expect(clonedList, equals(['a']));
    });

    test('returns primitives as-is', () {
      const primitive = 'hello';
      expect(identical(cloneDefault(primitive), primitive), isTrue);
    });
  });
}
