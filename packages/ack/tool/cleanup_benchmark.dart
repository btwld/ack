// Run from the workspace: dart run packages/ack/tool/cleanup_benchmark.dart
import 'dart:convert';

import 'package:ack/ack.dart';

import '../test/support/measure.dart';

void main(List<String> args) {
  if (args.contains('idna')) {
    final schema = Ack.fromJsonSchema({
      'format': 'idn-hostname',
    }, assertFormats: true);
    for (final size in [10, 100]) {
      print(
        '$size IDNA rejections: ${measure(() {
          for (var i = 0; i < size; i++) {
            try {
              schema.safeParse('xn--😀.example');
            } on RangeError {
              // Measure the original failure as well as the corrected result.
            }
          }
          return null;
        })} us',
      );
    }
    return;
  }
  for (final nested in [false, true]) {
    if (args.contains('formats') || args.contains('enum')) break;
    for (final size in [10, 100, 1000]) {
      AckSchema<Object, Object> schema = Ack.integer();
      Object? value = 1;
      Map<String, Object?> document = {'type': 'integer'};
      if (nested) {
        for (var i = 0; i < size; i++) {
          schema = Ack.object({'x': schema});
          value = <String, Object?>{'x': value};
          document = {
            'type': 'object',
            'properties': {'x': document},
          };
        }
      } else {
        schema = Ack.object({
          for (var i = 0; i < size; i++) 'p$i': Ack.integer(),
        });
        value = <String, Object?>{for (var i = 0; i < size; i++) 'p$i': i};
        document = {
          'type': 'object',
          'properties': {
            for (var i = 0; i < size; i++) 'p$i': {'type': 'integer'},
          },
        };
      }
      final input = value;
      final actions = <String, Object? Function()>{
        'parse': () => schema.parse(input),
        'encode+validate': () => schema.encode(input),
        'toJsonSchema': schema.toJsonSchema,
        'fromJsonSchema': () => Ack.fromJsonSchema(document),
      };
      for (final entry in actions.entries) {
        try {
          print(
            jsonEncode({
              'shape': nested ? 'nested' : 'flat',
              'size': size,
              'operation': entry.key,
              'us': measure(entry.value),
            }),
          );
        } on StackOverflowError {
          print(
            '${nested ? 'nested' : 'flat'} $size ${entry.key}: stack overflow',
          );
        }
      }
    }
  }
  final hostname = Ack.fromJsonSchema({
    'type': 'string',
    'format': 'idn-hostname',
  }, assertFormats: true);
  for (final size in [1000, 10000]) {
    if (args.contains('enum')) break;
    final input = '${'・' * size}カ.example';
    print(
      jsonEncode({
        'operation': 'contextO',
        'size': size,
        'us': measure(() => hostname.safeParse(input)),
      }),
    );
  }
  for (final size in [2000, 20000]) {
    if (args.contains('formats')) break;
    final document = {'enum': List<int>.generate(size, (i) => i)};
    print(
      jsonEncode({
        'operation': 'enum',
        'size': size,
        'us': measure(() => Ack.fromJsonSchema(document)),
      }),
    );
  }
}
