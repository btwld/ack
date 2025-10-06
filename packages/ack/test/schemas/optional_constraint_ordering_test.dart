import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Tests that constraints and refinements work correctly regardless of where
/// they are added relative to the .optional() call.
void main() {
  group('Optional Constraint Ordering', () {
    test('constraints before optional() should work', () {
      final schema = Ack.string().minLength(5).optional();

      // Valid non-null value
      expect(schema.safeParse('hello').isOk, isTrue);

      // Invalid non-null value (too short)
      final result = schema.safeParse('hi');
      expect(result.isFail, isTrue);
      expect(result.getError().toString(), contains('Minimum 5'));

      // Null should fail (optional does NOT imply nullable)
      expect(schema.safeParse(null).isFail, isTrue);
    });

    test('refinements after optional() should work', () {
      // This is the key test - refinements added AFTER optional()
      // should still be applied to non-null values
      final schema = Ack.string().optional().refine(
        (value) => value.length >= 5,
        message: 'Must be at least 5 characters',
      );

      // Valid non-null value
      expect(schema.safeParse('hello').isOk, isTrue);

      // Invalid non-null value (too short)
      final result = schema.safeParse('hi');
      expect(result.isFail, isTrue);
      expect(
        result.getError().toString(),
        contains('Must be at least 5 characters'),
      );

      // Null should fail (optional does NOT imply nullable)
      expect(schema.safeParse(null).isFail, isTrue);
    });

    test('multiple refinements with optional in the middle', () {
      final schema = Ack.string()
          .refine((v) => v.length >= 3, message: 'Too short')
          .optional()
          .refine((v) => v.length <= 10, message: 'Too long');

      // Valid value
      expect(schema.safeParse('hello').isOk, isTrue);

      // Too short (refinement before optional)
      final shortResult = schema.safeParse('hi');
      expect(shortResult.isFail, isTrue);
      expect(shortResult.getError().toString(), contains('Too short'));

      // Too long (refinement after optional)
      final longResult = schema.safeParse('this is too long');
      expect(longResult.isFail, isTrue);
      expect(longResult.getError().toString(), contains('Too long'));

      // Null fails (optional does NOT imply nullable)
      expect(schema.safeParse(null).isFail, isTrue);
    });

    test('refinements are checked when value is present', () {
      // Verify that refinements added after optional() are actually applied
      final schema = Ack.string().optional().refine(
        (v) => v.contains('@'),
        message: 'Must contain @',
      );

      // Non-null value is checked against refinements
      expect(schema.safeParse('test@example').isOk, isTrue);
      expect(schema.safeParse('invalid').isFail, isTrue);

      // Null fails (optional does NOT imply nullable)
      expect(schema.safeParse(null).isFail, isTrue);
    });
  });
}
