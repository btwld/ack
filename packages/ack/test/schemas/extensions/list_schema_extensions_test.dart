import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('ListSchemaExtensions', () {
    group('minLength', () {
      test('should pass if list is long enough', () {
        final schema = ListSchema(StringSchema()).minLength(2);
        final result = schema.validate(['a', 'b']);
        expect(result.isOk, isTrue);
      });

      test('should fail if list is too short', () {
        final schema = ListSchema(StringSchema()).minLength(3);
        final result = schema.validate(['a', 'b']);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Too few items. Minimum 3, got 2.');
      });
    });

    group('maxLength', () {
      test('should pass if list is short enough', () {
        final schema = ListSchema(StringSchema()).maxLength(2);
        final result = schema.validate(['a', 'b']);
        expect(result.isOk, isTrue);
      });

      test('should fail if list is too long', () {
        final schema = ListSchema(StringSchema()).maxLength(1);
        final result = schema.validate(['a', 'b']);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Too many items. Maximum 1, got 2.');
      });
    });

    group('length', () {
      test('should pass if list has exact length', () {
        final schema = ListSchema(StringSchema()).length(2);
        final result = schema.validate(['a', 'b']);
        expect(result.isOk, isTrue);
      });

      test('should fail if list does not have exact length', () {
        final schema = ListSchema(StringSchema()).length(3);
        final result = schema.validate(['a', 'b']);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Must have exactly 3 items, got 2.');
      });
    });

    group('nonempty', () {
      test('should pass if list is not empty', () {
        final schema = ListSchema(StringSchema()).nonempty();
        final result = schema.validate(['a']);
        expect(result.isOk, isTrue);
      });

      test('should fail if list is empty', () {
        final schema = ListSchema(StringSchema()).nonempty();
        final result = schema.validate([]);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Too few items. Minimum 1, got 0.');
      });
    });
  });
}
