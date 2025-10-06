import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Test to verify that transform() inherits isOptional and isNullable flags
void main() {
  group('TransformedSchema flag inheritance', () {
    test('transform should inherit isOptional flag', () {
      final schema = Ack.string().optional().transform((val) => val ?? '');

      print(
        'Wrapped schema isOptional: ${(schema as dynamic).schema.isOptional}',
      );
      print('TransformedSchema isOptional: ${schema.isOptional}');

      expect(
        schema.isOptional,
        isTrue,
        reason:
            'TransformedSchema should inherit isOptional from wrapped schema',
      );
    });

    test('transform should inherit isNullable flag', () {
      final schema = Ack.string().nullable().transform((val) => val ?? '');

      print(
        'Wrapped schema isNullable: ${(schema as dynamic).schema.isNullable}',
      );
      print('TransformedSchema isNullable: ${schema.isNullable}');

      expect(
        schema.isNullable,
        isTrue,
        reason:
            'TransformedSchema should inherit isNullable from wrapped schema',
      );
    });

    test('transform should inherit both optional and nullable flags', () {
      final schema = Ack.string().optional().nullable().transform(
        (val) => val ?? '',
      );

      print(
        'Wrapped schema isOptional: ${(schema as dynamic).schema.isOptional}',
      );
      print(
        'Wrapped schema isNullable: ${(schema as dynamic).schema.isNullable}',
      );
      print('TransformedSchema isOptional: ${schema.isOptional}');
      print('TransformedSchema isNullable: ${schema.isNullable}');

      expect(
        schema.isOptional,
        isTrue,
        reason:
            'TransformedSchema should inherit isOptional from wrapped schema',
      );
      expect(
        schema.isNullable,
        isTrue,
        reason:
            'TransformedSchema should inherit isNullable from wrapped schema',
      );
    });

    test('optional+nullable+transform in object context should work', () {
      final schema = Ack.object({
        'name': Ack.string(),
        'nickname': Ack.string().optional().nullable().transform(
          (val) => val ?? 'no-nick',
        ),
      });

      print('\nTesting object with optional+nullable+transform field:');

      // Test 1: Missing field (should work if isOptional is inherited)
      final result1 = schema.safeParse({'name': 'John'});
      print('Missing field - isOk: ${result1.isOk}');
      if (result1.isFail) {
        print('  Error: ${result1.getError()}');
      }

      // Test 2: Null value (should work if isNullable is inherited)
      final result2 = schema.safeParse({'name': 'John', 'nickname': null});
      print('Null value - isOk: ${result2.isOk}');
      if (result2.isFail) {
        print('  Error: ${result2.getError()}');
      }

      // Test 3: Actual value
      final result3 = schema.safeParse({'name': 'John', 'nickname': 'Johnny'});
      print('Actual value - isOk: ${result3.isOk}');
      if (result3.isFail) {
        print('  Error: ${result3.getError()}');
      }

      // These will fail if flags are not inherited
      expect(
        result1.isOk,
        isTrue,
        reason: 'Should accept missing optional field',
      );
      expect(
        result2.isOk,
        isTrue,
        reason: 'Should accept null for nullable field',
      );
      expect(result3.isOk, isTrue, reason: 'Should accept actual value');
    });
  });
}
