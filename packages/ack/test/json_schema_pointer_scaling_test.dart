import 'package:ack/ack.dart';
import 'package:test/test.dart';

import 'support/measure.dart';

void main() {
  test('schema location indexing scales linearly with depth', () {
    double elapsed(int depth) {
      Map<String, Object?> document = {'type': 'integer'};
      for (var i = 0; i < depth; i++) {
        document = {
          'type': 'object',
          'properties': {'x': document},
        };
      }
      return measure(() => Ack.fromJsonSchema(document));
    }

    elapsed(1000); // Warm the compiler before comparing both depths.
    final small = elapsed(100);
    final large = elapsed(1000);
    expect(
      large / small,
      lessThan(25),
      reason: '10x depth must stay below 25x ($small us -> $large us)',
    );
  });

  test('location segments preserve empty and escaped reference tokens', () {
    const key = 'a/~%#';
    final schema = Ack.fromJsonSchema({
      r'$defs': {
        '': {
          'type': 'object',
          'properties': {
            key: {'type': 'integer'},
          },
        },
      },
      r'$ref': r'#/$defs/',
    });
    expect(schema.safeParse({key: 1}).isOk, isTrue);
    expect(schema.safeEncode({key: 'bad'}).isFail, isTrue);
    expect(
      Ack.fromJsonSchema(schema.toJsonSchema()).safeParse({key: 1}).isOk,
      isTrue,
    );
  });
}
