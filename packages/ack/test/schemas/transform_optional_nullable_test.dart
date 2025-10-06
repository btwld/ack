import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Test to verify whether .optional().nullable().transform() works correctly.
/// This test investigates the skipped test in optional_nullable_semantics_test.dart:134-135
void main() {
  group('Transform with optional().nullable() combination', () {
    test(
      'should handle .optional().nullable().transform() - missing field',
      () {
        final schema = Ack.string().optional().nullable().transform((val) {
          if (val == null) return 'default';
          return val.toUpperCase();
        });

        final result = schema.safeParse('hello');

        print('Result isOk: ${result.isOk}');
        print('Result value: ${result.getOrNull()}');
        if (result.isFail) {
          print('Error: ${result.getError()}');
        }

        expect(
          result.isOk,
          isTrue,
          reason: 'Should successfully transform a string value',
        );
        expect(result.getOrNull(), equals('HELLO'));
      },
    );

    test('should handle .optional().nullable().transform() - null value', () {
      final schema = Ack.string().optional().nullable().transform((val) {
        if (val == null) return 'default';
        return val.toUpperCase();
      });

      final result = schema.safeParse(null);

      print('Result isOk: ${result.isOk}');
      print('Result value: ${result.getOrNull()}');
      if (result.isFail) {
        print('Error: ${result.getError()}');
      }

      expect(result.isOk, isTrue, reason: 'Should handle null value');
      expect(result.getOrNull(), equals('default'));
    });

    test(
      'should work in object context with optional().nullable().transform()',
      () {
        final schema = Ack.object({
          'name': Ack.string(),
          'nickname': Ack.string().optional().nullable().transform((val) {
            if (val == null) return 'No nickname';
            return val.toUpperCase();
          }),
        });

        // Test 1: Missing field
        final result1 = schema.safeParse({'name': 'John'});
        print('Test 1 - Missing field:');
        print('  Result isOk: ${result1.isOk}');
        print('  Result value: ${result1.getOrNull()}');
        if (result1.isFail) {
          print('  Error: ${result1.getError()}');
        }

        // Test 2: Null value
        final result2 = schema.safeParse({'name': 'John', 'nickname': null});
        print('Test 2 - Null value:');
        print('  Result isOk: ${result2.isOk}');
        print('  Result value: ${result2.getOrNull()}');
        if (result2.isFail) {
          print('  Error: ${result2.getError()}');
        }

        // Test 3: Actual value
        final result3 = schema.safeParse({
          'name': 'John',
          'nickname': 'Johnny',
        });
        print('Test 3 - Actual value:');
        print('  Result isOk: ${result3.isOk}');
        print('  Result value: ${result3.getOrNull()}');
        if (result3.isFail) {
          print('  Error: ${result3.getError()}');
        }

        expect(
          result1.isOk,
          isTrue,
          reason: 'Should handle missing optional field',
        );
        expect(result2.isOk, isTrue, reason: 'Should handle null value');
        expect(result3.isOk, isTrue, reason: 'Should handle actual value');

        expect(result3.getOrNull()?['nickname'], equals('JOHNNY'));
      },
    );

    test('compare: .nullable().transform() without optional', () {
      // This is the working case from transform_extension_test.dart:32-44
      final schema = Ack.string().nullable().transform((val) {
        return val == null ? 'was null' : 'was not null';
      });

      final result = schema.safeParse(null);
      expect(result.isOk, isTrue);
      expect(result.getOrThrow(), 'was null');
    });

    test('order matters: .nullable().optional().transform()', () {
      final schema = Ack.string().nullable().optional().transform((val) {
        if (val == null) return 'default';
        return val.toUpperCase();
      });

      final result1 = schema.safeParse(null);
      print('Nullable then Optional - null value:');
      print('  Result isOk: ${result1.isOk}');
      print('  Result value: ${result1.getOrNull()}');
      if (result1.isFail) {
        print('  Error: ${result1.getError()}');
      }

      final result2 = schema.safeParse('hello');
      print('Nullable then Optional - string value:');
      print('  Result isOk: ${result2.isOk}');
      print('  Result value: ${result2.getOrNull()}');
      if (result2.isFail) {
        print('  Error: ${result2.getError()}');
      }

      expect(result1.isOk, isTrue);
      expect(result2.isOk, isTrue);
    });
  });
}
