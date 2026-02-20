import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaResult.map', () {
    test('maps successful non-null value', () {
      final mapped = SchemaResult.ok<String>('hello').map((value) {
        return value!.length;
      });

      expect(mapped.isOk, isTrue);
      expect(mapped.getOrNull(), equals(5));
    });

    test('maps successful null value', () {
      final mapped = SchemaResult.ok<String>(null).map((value) {
        return value ?? 'fallback';
      });

      expect(mapped.isOk, isTrue);
      expect(mapped.getOrNull(), equals('fallback'));
    });

    test('does not call transform for fail and preserves exact error', () {
      final originalError = SchemaValidationError(
        message: 'boom',
        context: SchemaContext(name: 'value', schema: Ack.string(), value: 42),
      );
      var transformCalled = false;

      final mapped = SchemaResult.fail<String>(originalError).map((value) {
        transformCalled = true;
        return value?.length ?? 0;
      });

      expect(transformCalled, isFalse);
      expect(mapped.isFail, isTrue);
      expect(identical(mapped.getError(), originalError), isTrue);
    });
  });
}
