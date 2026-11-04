import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../tool/cleanup_benchmark.dart' show measure;

void main() {
  test('enum compilation grows linearly with distinct values', () {
    double elapsed(int size) {
      final document = {'enum': List<int>.generate(size, (i) => i)};
      return measure(() => Ack.fromJsonSchema(document));
    }

    final small = elapsed(2000);
    final large = elapsed(20000);
    expect(
      large / small,
      lessThan(40),
      reason: '10x input must stay below 40x',
    );
  });

  test('enum dedupe preserves first values and JSON numeric equality', () {
    final schema = Ack.fromJsonSchema({
      'enum': [
        1,
        1.0,
        [1],
        [1.0],
        {'a': 1, 'b': 2},
        {'b': 2.0, 'a': 1.0},
        null,
        null,
        true,
        true,
      ],
    });
    final definitions = schema.toJsonSchemaDraft7()['definitions']! as Map;
    expect(
      definitions.values,
      contains(
        containsPair('enum', [
          1,
          [1],
          {'a': 1, 'b': 2},
          null,
          true,
        ]),
      ),
    );
    expect(schema.safeParse([1.0]).isOk, isTrue);
    expect(schema.safeEncode({'b': 2.0, 'a': 1.0}).isOk, isTrue);
    expect(schema.safeParse(false).isFail, isTrue);
  });
}
