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
      test('should pass for empty list', () {
        final schema = Ack.list(Ack.integer()).unique();
        final result = schema.safeParse([]);
        expect(result.isOk, isTrue);
      });

      test('should pass for single-item list', () {
        final schema = Ack.list(Ack.string()).unique();
        final result = schema.safeParse(['a']);
        expect(result.isOk, isTrue);
      });

      test('should pass when all primitive items are unique', () {
        final schema = Ack.list(Ack.integer()).unique();
        final result = schema.safeParse([1, 2, 3, 4, 5]);
        expect(result.isOk, isTrue);
      });

      test('should fail when primitive list has duplicates at start', () {
        final schema = Ack.list(Ack.string()).unique();
        final result = schema.safeParse(['a', 'a', 'b', 'c']);
        expect(result.isOk, isFalse);
      });

      test('should fail when primitive list has duplicates in middle', () {
        final schema = Ack.list(Ack.integer()).unique();
        final result = schema.safeParse([1, 2, 3, 2, 4]);
        expect(result.isOk, isFalse);
      });

      test('should fail when primitive list has duplicates at end', () {
        final schema = Ack.list(Ack.string()).unique();
        final result = schema.safeParse(['a', 'b', 'c', 'c']);
        expect(result.isOk, isFalse);
      });

      test('should pass when object list items are unique', () {
        final schema = Ack.list(
          Ack.object({'id': Ack.integer(), 'name': Ack.string()}),
        ).unique();
        final result = schema.safeParse([
          {'id': 1, 'name': 'Alice'},
          {'id': 2, 'name': 'Bob'},
        ]);
        expect(result.isOk, isTrue);
      });

      test('should fail when object list has duplicate objects', () {
        final schema = Ack.list(Ack.object({'id': Ack.integer()})).unique();
        final result = schema.safeParse([
          {'id': 1},
          {'id': 2},
          {'id': 1},
        ]);
        expect(result.isOk, isFalse);
      });

      test('should handle nested structures', () {
        final schema = Ack.list(
          Ack.object({'items': Ack.list(Ack.integer())}),
        ).unique();

        final result = schema.safeParse([
          {
            'items': [1, 2, 3],
          },
          {
            'items': [4, 5, 6],
          },
        ]);
        expect(result.isOk, isTrue);

        final duplicateResult = schema.safeParse([
          {
            'items': [1, 2, 3],
          },
          {
            'items': [1, 2, 3],
          },
        ]);
        expect(duplicateResult.isOk, isFalse);
      });
    });
  });
}
