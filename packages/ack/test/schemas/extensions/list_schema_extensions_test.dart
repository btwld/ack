import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('ListSchemaExtensions', () {
    group('minLength', () {
      test('should pass if list is long enough', () {
        final schema = ListSchema(StringSchema()).minItems(2);
        final result = schema.safeParse(['a', 'b']);
        expect(result.isOk, isTrue);
      });

      test('should fail if list is too short', () {
        final schema = ListSchema(StringSchema()).minItems(3);
        final result = schema.safeParse(['a', 'b']);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Too few items. Minimum 3, got 2.',
        );
      });
    });

    group('maxLength', () {
      test('should pass if list is short enough', () {
        final schema = ListSchema(StringSchema()).maxItems(2);
        final result = schema.safeParse(['a', 'b']);
        expect(result.isOk, isTrue);
      });

      test('should fail if list is too long', () {
        final schema = ListSchema(StringSchema()).maxItems(1);
        final result = schema.safeParse(['a', 'b']);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Too many items. Maximum 1, got 2.',
        );
      });
    });

    group('exactLength', () {
      test('length should pass if string is exact length', () {
        final schema = Ack.list(Ack.string()).exactLength(2);
        final result = schema.safeParse(['a', 'b']);
        expect(result.isOk, isTrue);
      });

      test('length should fail if string is not exact length', () {
        final schema = Ack.list(Ack.string()).exactLength(2);
        final result = schema.safeParse(['a']);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Must have exactly 2 items, got 1.',
        );
      });
    });

    group('nonEmpty', () {
      test('nonempty should pass if list is not empty', () {
        final schema = Ack.list(Ack.string()).nonEmpty();
        final result = schema.safeParse(['a']);
        expect(result.isOk, isTrue);
      });

      test('nonempty should fail if list is empty', () {
        final schema = Ack.list(Ack.string()).nonEmpty();
        final result = schema.safeParse([]);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Too few items. Minimum 1, got 0.',
        );
      });
    });

    group('unique', () {
      test('unique should pass if all items are unique', () {
        // ... existing code ...
      });
    });
  });
}
