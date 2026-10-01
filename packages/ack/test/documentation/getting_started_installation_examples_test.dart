import 'dart:io';

import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Tests for code snippets in docs/getting-started/installation.mdx.
void main() {
  group('Docs /getting-started/installation.mdx', () {
    test('basic usage after installation validates strings', () {
      final nameSchema = Ack.string().minLength(3);

      final validResult = nameSchema.safeParse('John');
      expect(validResult.isOk, isTrue);
      expect(validResult.getOrThrow(), equals('John'));

      final invalidResult = nameSchema.safeParse('Al');
      expect(invalidResult.isFail, isTrue);
    });

    test('generator setup documents both generation directions', () async {
      final content = await File(
        '../../docs/getting-started/installation.mdx',
      ).readAsString();

      expect(content, contains('ack_annotations'));
      expect(content, contains('@AckInfer()'));
      expect(content, contains('@AckModel()'));
      expect(content, contains('ack_generator'));
      expect(content, contains('build_runner'));
      expect(content, contains('@Schemable()'));
      expect(content, contains('>=3.13.0 <4.0.0'));
    });
  });
}
