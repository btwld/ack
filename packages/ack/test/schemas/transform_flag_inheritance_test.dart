import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Test to verify that transform() inherits isOptional and isNullable flags.
void main() {
  group('one-way CodecSchema flag inheritance', () {
    test('transform should inherit isOptional flag', () {
      final schema = Ack.string().optional().transform((val) => val);

      expect(
        schema.isOptional,
        isTrue,
        reason: 'CodecSchema should inherit isOptional from wrapped schema',
      );
    });

    test('transform should inherit isNullable flag', () {
      final schema = Ack.string().nullable().transform((val) => val);

      expect(
        schema.isNullable,
        isTrue,
        reason: 'CodecSchema should inherit isNullable from wrapped schema',
      );
    });

    test('transform should inherit both optional and nullable flags', () {
      final schema = Ack.string().optional().nullable().transform((val) => val);

      expect(
        schema.isOptional,
        isTrue,
        reason: 'CodecSchema should inherit isOptional from wrapped schema',
      );
      expect(
        schema.isNullable,
        isTrue,
        reason: 'CodecSchema should inherit isNullable from wrapped schema',
      );
    });

    test('optional+nullable+transform in object context should work', () {
      final schema = Ack.object({
        'name': Ack.string(),
        'nickname': Ack.string().optional().nullable().transform((val) => val),
      });

      final result1 = schema.safeParse({'name': 'John'});
      final result2 = schema.safeParse({'name': 'John', 'nickname': null});
      final result3 = schema.safeParse({'name': 'John', 'nickname': 'Johnny'});

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
