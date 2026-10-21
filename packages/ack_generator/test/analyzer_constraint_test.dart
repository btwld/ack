import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test('ack_generator pins Analyzer to the supported 14.x line', () {
    final pubspec = File(
      p.join(
        Directory.current.path.endsWith('ack_generator')
            ? Directory.current.path
            : p.join(Directory.current.path, 'packages', 'ack_generator'),
        'pubspec.yaml',
      ),
    ).readAsStringSync();

    expect(pubspec, contains('analyzer: ">=14.3.0 <15.0.0"'));
  });

  test('schema analysis uses only the supported Analyzer 14 AST shape', () {
    final packageRoot = Directory.current.path.endsWith('ack_generator')
        ? Directory.current.path
        : p.join(Directory.current.path, 'packages', 'ack_generator');
    final source = File(
      p.join(
        packageRoot,
        'lib',
        'src',
        'analyzer',
        'schema_model_graph_builder.dart',
      ),
    ).readAsStringSync();

    expect(source, isNot(contains('dynamic dynamicArgument')));
    expect(source, isNot(contains('.argumentExpression')));
  });
}
