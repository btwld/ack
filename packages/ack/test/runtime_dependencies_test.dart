@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'ack depends only on lightweight runtime packages (no json_annotation)',
    () {
      final lines = File('pubspec.yaml').readAsLinesSync();
      final start = lines.indexOf('dependencies:');
      final dependencies = [
        for (final line
            in lines
                .skip(start + 1)
                .takeWhile((line) => line.isEmpty || line.startsWith(' ')))
          if (RegExp(r'^  (\w+):').firstMatch(line) case final match?)
            match.group(1),
      ];

      expect(
        dependencies,
        unorderedEquals(['meta', 'collection', 'punycoder', 'unorm_dart']),
      );
    },
  );
}
