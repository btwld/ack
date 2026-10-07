/// JIT numbers drift with warmup, so measure an AOT build:
///
/// ```sh
/// dart compile exe benchmark/parse_benchmark.dart -o build/parse_benchmark
/// build/parse_benchmark
/// ```
library;

import 'package:ack/ack.dart';

const _draft = 'https://json-schema.org/draft/2020-12/schema';

void main() {
  final string = Ack.string();
  final object = Ack.object({
    'a': Ack.string(),
    'b': Ack.string(),
    'c': Ack.string(),
  });
  final anything = Ack.fromJsonSchema(true);
  final flat = Ack.fromJsonSchema({
    r'$schema': _draft,
    'type': 'object',
    'properties': {
      for (var i = 0; i < 8; i++)
        'p$i': {'type': 'string', 'minLength': 1, 'pattern': r'^[a-z]+$'},
    },
  });
  final flatValue = {for (var i = 0; i < 8; i++) 'p$i': 'abc'};
  final nested = Ack.fromJsonSchema({
    r'$schema': _draft,
    'type': 'object',
    'properties': {
      'items': {
        'type': 'array',
        'items': {
          'type': 'object',
          'required': ['id', 'tags'],
          'properties': {
            'id': {'type': 'string'},
            'tags': {
              'type': 'array',
              'items': {'type': 'string'},
            },
          },
        },
      },
    },
  });
  final nestedValue = {
    'items': [
      for (var i = 0; i < 50; i++)
        {
          'id': 'x$i',
          'tags': ['a', 'b', 'c'],
        },
    ],
  };

  _report('Ack.string()', 200000, () => string.safeParse('x'));
  _report(
    'Ack.object, 3 string fields',
    200000,
    () => object.safeParse(const {'a': 'x', 'b': 'y', 'c': 'z'}),
  );
  _report('fromJsonSchema(true)', 200000, () => anything.safeParse('x'));
  _report('imported, 8 properties', 100000, () => flat.safeParse(flatValue));
  _report(
    'imported, 8 properties (encode)',
    100000,
    () => flat.safeEncode(flatValue),
  );
  _report(
    'imported, 50 nested items',
    10000,
    () => nested.safeParse(nestedValue),
  );
  _report(
    'imported, 50 nested items (encode)',
    10000,
    () => nested.safeEncode(nestedValue),
  );
}

void _report(String name, int iterations, void Function() body) {
  for (var i = 0; i < iterations ~/ 10; i++) {
    body();
  }
  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    body();
  }
  final ns = stopwatch.elapsedMicroseconds * 1000 / iterations;
  print('${name.padRight(36)} ${ns.toStringAsFixed(0).padLeft(7)} ns');
}
