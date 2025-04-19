import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Installation Documentation Examples', () {
    test('Basic usage example', () {
      // Create a schema
      final nameSchema = Ack.string.minLength(3);
      
      // Validate data
      final result = nameSchema.validate('John');
      
      expect(result.isOk, isTrue);
      
      if (result.isOk) {
        final value = result.getOrThrow();
        expect(value, equals('John'));
      }
    });
  });
}
