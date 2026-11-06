import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  test('deepUnmodifiableCopy accepts null and preserves opaque leaves', () {
    final opaque = Object();
    final timestamp = DateTime.utc(2026, 10, 26);
    expect(deepUnmodifiableCopy(null), isNull);
    expect(deepUnmodifiableCopy(opaque), same(opaque));
    expect(deepUnmodifiableCopy(timestamp), same(timestamp));
    expect(deepUnmodifiableCopy(double.infinity), double.infinity);
  });

  test(
    'deepUnmodifiableCopy snapshots arbitrary map keys, lists, and sets',
    () {
      final opaque = Object();
      final nested = <Object?>[opaque, null];
      final map = <Object?, Object?>{1: nested};
      final set = <Object?>{map};
      final source = <Object?>[map, set];
      final snapshot = deepUnmodifiableCopy(source)! as List<Object?>;
      nested.clear();
      map[2] = 'later';
      set.clear();
      source.clear();

      final copiedMap = snapshot.first! as Map<Object?, Object?>;
      expect(copiedMap.keys, [1]);
      final copiedList = copiedMap[1]! as List<Object?>;
      expect(copiedList.first, same(opaque));
      expect(copiedList.last, isNull);
      final copiedSet = snapshot.last! as Set<Object?>;
      expect(copiedSet, hasLength(1));
      expect(deepEquals(copiedSet.single, copiedMap), isTrue);
      expect(() => snapshot.clear(), throwsUnsupportedError);
      expect(() => copiedMap.clear(), throwsUnsupportedError);
      expect(() => copiedList.clear(), throwsUnsupportedError);
      expect(() => copiedSet.clear(), throwsUnsupportedError);
    },
  );

  test('deepUnmodifiableJsonMap snapshots nested maps, lists, and sets', () {
    final nestedMap = <String, Object?>{'enabled': true};
    final nestedList = <Object?>[nestedMap];
    final nestedSet = <Object?>{'first', nestedList};
    final source = <String, Object?>{
      'map': nestedMap,
      'list': nestedList,
      'set': nestedSet,
    };

    final snapshot = deepUnmodifiableJsonMap(source);

    source['later'] = true;
    nestedMap['enabled'] = false;
    nestedList.add('later');
    nestedSet.add('later');

    expect(snapshot, {
      'map': {'enabled': true},
      'list': [
        {'enabled': true},
      ],
      'set': {
        'first',
        [
          {'enabled': true},
        ],
      },
    });
    expect(() => snapshot['later'] = true, throwsUnsupportedError);
    expect(
      () => (snapshot['map']! as Map<String, Object?>)['later'] = true,
      throwsUnsupportedError,
    );
    expect(
      () => (snapshot['list']! as List<Object?>).add('later'),
      throwsUnsupportedError,
    );
    expect(
      () => (snapshot['set']! as Set<Object?>).add('later'),
      throwsUnsupportedError,
    );
  });

  test(
    'deepEquals and deepHashCode stay consistent for nested collections',
    () {
      final left = {
        'tags': ['a', 'b'],
        'scores': {'x': 1, 'y': 2},
        'flags': {'on', 'off'},
      };
      final right = {
        'tags': ['a', 'b'],
        'scores': {'y': 2, 'x': 1},
        'flags': {'off', 'on'},
      };
      final different = {
        'tags': ['a', 'c'],
        'scores': {'x': 1, 'y': 2},
        'flags': {'on', 'off'},
      };

      expect(deepEquals(left, right), isTrue);
      expect(deepHashCode(left), deepHashCode(right));
      expect(deepEquals(left, different), isFalse);
      expect(deepEquals([1], [1.0]), isTrue);
      expect(deepHashCode([1]), deepHashCode([1.0]));
    },
  );

  test('deep collection semantics ignore concrete collection wrappers', () {
    final growable = <Object?>[
      1,
      <String, Object?>{
        'items': <String>['a', 'b'],
      },
    ];
    final wrapped = List<Object?>.unmodifiable([
      1,
      Map<String, Object?>.unmodifiable({
        'items': List<String>.unmodifiable(['a', 'b']),
      }),
    ]);

    expect(deepEquals(growable, wrapped), isTrue);
    expect(deepHashCode(growable), deepHashCode(wrapped));
    expect(deepEquals([1], [1.0]), isTrue);
    expect(deepHashCode([1]), deepHashCode([1.0]));
  });

  test('deep map keys follow scalar equality and the hash contract', () {
    final equivalentPairs = <(Object?, Object?)>[
      (<num, String>{1: 'one'}, <num, String>{1: 'one'}),
      (
        <Object?, Object?>{
          'nested': <num, Object?>{
            1: <Object?>['value'],
          },
        },
        <Object?, Object?>{
          'nested': <num, Object?>{
            1: <Object?>['value'],
          },
        },
      ),
      (
        <String, Object?>{
          'nested': <Object?>[
            <String, Object?>{
              'values': <Object?>{1, 'one'},
            },
          ],
        },
        <String, Object?>{
          'nested': <Object?>[
            <String, Object?>{
              'values': <Object?>{'one', 1},
            },
          ],
        },
      ),
    ];

    for (final (left, right) in equivalentPairs) {
      expect(deepEquals(left, right), isTrue);
      expect(
        deepHashCode(left),
        deepHashCode(right),
        reason: 'deep-equal values must have the same hash code',
      );
    }

    final integerKey = <num, String>{1: 'one'};
    final doubleKey = <num, String>{1.0: 'one'};

    expect(
      deepEquals(integerKey, doubleKey),
      isTrue,
      reason: 'mathematically equal numeric map keys are equivalent',
    );
    expect(deepHashCode(integerKey), deepHashCode(doubleKey));
  });

  test('numeric scalar equality and hashing ignore representation', () {
    for (final (left, right) in <(num, num)>[(1, 1.0), (0, -0.0)]) {
      expect(deepEquals(left, right), isTrue);
      expect(deepHashCode(left), deepHashCode(right));
    }

    expect(deepEquals(1, 1.5), isFalse);
  });

  test(
    'numeric equality and hashing recurse through every collection kind',
    () {
      final integers = <String, Object?>{
        'list': [1, 2],
        'set': {3, 4},
        'iterable': Iterable<int>.generate(2, (index) => index + 5),
      };
      final doubles = <String, Object?>{
        'list': [1.0, 2.0],
        'set': {4.0, 3.0},
        'iterable': Iterable<double>.generate(2, (index) => index + 5.0),
      };

      expect(deepEquals(integers, doubles), isTrue);
      expect(deepHashCode(integers), deepHashCode(doubles));
    },
  );

  test('deep equality preserves collection category and list order', () {
    expect(deepEquals([1, 2], [2.0, 1.0]), isFalse);
    expect(deepEquals([1], {1.0}), isFalse);
    expect(deepEquals([1], Iterable<int>.generate(1, (index) => 1)), isFalse);
  });
}
