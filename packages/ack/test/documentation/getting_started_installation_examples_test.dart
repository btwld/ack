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
  });
}
