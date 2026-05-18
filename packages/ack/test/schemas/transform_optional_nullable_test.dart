import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Covers optional/nullable transform combinations.
void main() {
  group('Transform with optional().nullable() combination', () {
    test(
      'should handle .optional().nullable().transform() - missing field',
      () {
        final schema = Ack.string().optional().nullable().transform(
          (val) => val.toUpperCase(),
        );

        final result = schema.safeParse('hello');

        expect(
          result.isOk,
          isTrue,
          reason: 'Should successfully transform a string value',
        );
        expect(result.getOrNull(), equals('HELLO'));
      },
    );

    test('should handle .optional().nullable().transform() - null value', () {
      final schema = Ack.string().optional().nullable().transform(
        (val) => val.toUpperCase(),
      );

      final result = schema.safeParse(null);

      expect(result.isOk, isTrue, reason: 'Should handle null value');
      // Null passes through without calling transformer
      expect(result.getOrNull(), isNull);
    });

    test(
      'should work in object context with optional().nullable().transform()',
      () {
        final schema = Ack.object({
          'name': Ack.string(),
          'nickname': Ack.string().optional().nullable().transform(
            (val) => val.toUpperCase(),
          ),
        });

        final result1 = schema.safeParse({'name': 'John'});
        final result2 = schema.safeParse({'name': 'John', 'nickname': null});
        final result3 = schema.safeParse({
          'name': 'John',
          'nickname': 'Johnny',
        });

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
      // Null passes through without calling the transformer
      final schema = Ack.string().nullable().transform((_) => 'was not null');

      final result = schema.safeParse(null);
      expect(result.isOk, isTrue);
      // Null passes through without calling transformer
      expect(result.getOrNull(), isNull);
    });

    test('order matters: .nullable().optional().transform()', () {
      final schema = Ack.string().nullable().optional().transform(
        (val) => val.toUpperCase(),
      );

      final result1 = schema.safeParse(null);
      final result2 = schema.safeParse('hello');

      expect(result1.isOk, isTrue);
      expect(result1.getOrNull(), isNull);
      expect(result2.isOk, isTrue);
      expect(result2.getOrNull(), equals('HELLO'));
    });
  });
}
