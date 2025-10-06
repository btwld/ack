import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Tests for code snippets in docs/core-concepts/error-handling.mdx.
void main() {
  group('Docs /core-concepts/error-handling.mdx', () {
    test('SchemaResult usage mirrors documentation', () {
      final schema = Ack.string().minLength(5);
      final result = schema.safeParse('abc');

      expect(result.isFail, isTrue);
      final error = result.getError();
      expect(error, isA<SchemaError>());

      expect(() => result.getOrThrow(), throwsA(isA<AckException>()));
      expect(
        result.getOrElse(() => 'default_string'),
        equals('default_string'),
      );
      expect(result.getOrNull(), isNull);
    });

    test('SchemaError exposes details for nested validation', () {
      final userSchema = Ack.object({
        'name': Ack.string(),
        'age': Ack.integer().min(18),
        'address': Ack.object({'city': Ack.string()}),
      });

      final invalidData = {
        'name': 'Test',
        'age': 15,
        'address': {'city': 123},
      };

      final result = userSchema.safeParse(invalidData);
      expect(result.isFail, isTrue);

      final error = result.getError();
      expect(error.name, equals('object'));
      expect(error.value, equals(invalidData));
      expect(error.toString(), contains('Validation failed'));
    });

    test('TextFormField-style validator returns error text on failure', () {
      final schema = Ack.string().minLength(5);

      String? validator(String? value) {
        final result = schema.safeParse(value);
        return result.isFail ? result.getError().toString() : null;
      }

      expect(validator('valid value'), isNull);
      expect(validator('bad'), isNotNull);
    });

    test('default messages display via toString', () {
      final schema = Ack.string().minLength(5);
      final result = schema.safeParse('abc');
      final message = result.getError().toString();
      expect(message, contains('Constraints not met'));
    });
  });
}
