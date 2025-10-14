import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('StringSchema.matches() - Auto-anchoring', () {
    test('automatically anchors unanchored patterns', () {
      final schema = Ack.string().matches(r'\d{5}');

      // Should match full string
      expect(schema.safeParse('12345').isOk, isTrue);

      // Should NOT match partial strings (fails due to anchoring)
      expect(schema.safeParse('123456').isOk, isFalse);
      expect(schema.safeParse('012345').isOk, isFalse);
      expect(schema.safeParse('abc12345').isOk, isFalse);
      expect(schema.safeParse('12345xyz').isOk, isFalse);
    });

    test('preserves explicitly anchored patterns', () {
      final schema = Ack.string().matches(r'^\d{5}$');

      expect(schema.safeParse('12345').isOk, isTrue);
      expect(schema.safeParse('123456').isOk, isFalse);
      expect(schema.safeParse('012345').isOk, isFalse);
    });

    test('completes partially anchored patterns (start anchor only)', () {
      final schema = Ack.string().matches(r'^\d{5}');

      expect(schema.safeParse('12345').isOk, isTrue);

      // Should NOT match if extra characters at end
      expect(schema.safeParse('12345xyz').isOk, isFalse);
    });

    test('completes partially anchored patterns (end anchor only)', () {
      final schema = Ack.string().matches(r'\d{5}$');

      expect(schema.safeParse('12345').isOk, isTrue);

      // Should NOT match if extra characters at start
      expect(schema.safeParse('abc12345').isOk, isFalse);
    });

    test('works with complex patterns containing alternation', () {
      final schema = Ack.string().matches(r'foo|bar');

      expect(schema.safeParse('foo').isOk, isTrue);
      expect(schema.safeParse('bar').isOk, isTrue);

      // Should NOT match partial strings (anchored)
      expect(schema.safeParse('foobar').isOk, isFalse);
      expect(schema.safeParse('prefix_foo').isOk, isFalse);
      expect(schema.safeParse('bar_suffix').isOk, isFalse);
    });

    test('works with patterns containing character classes', () {
      final schema = Ack.string().matches(r'[A-Z]{3}');

      expect(schema.safeParse('ABC').isOk, isTrue);

      // Should NOT match partial strings
      expect(schema.safeParse('ABCD').isOk, isFalse);
      expect(schema.safeParse('0ABC').isOk, isFalse);
    });

    test('works with quantifiers', () {
      final schema = Ack.string().matches(r'\w+');

      expect(schema.safeParse('hello').isOk, isTrue);
      expect(schema.safeParse('a').isOk, isTrue);

      // Should NOT match strings with spaces (anchored to full string)
      expect(schema.safeParse('hello world').isOk, isFalse);
    });

    test('works with optional groups', () {
      final schema = Ack.string().matches(r'\d{3}-?\d{4}');

      expect(schema.safeParse('1234567').isOk, isTrue);
      expect(schema.safeParse('123-4567').isOk, isTrue);

      // Should NOT match partial strings
      expect(schema.safeParse('0001234567').isOk, isFalse);
    });

    test('handles empty string patterns correctly', () {
      final schema = Ack.string().matches(r'');

      // Empty pattern should only match empty string
      expect(schema.safeParse('').isOk, isTrue);
      expect(schema.safeParse('a').isOk, isFalse);
    });

    test('handles patterns with special characters', () {
      final schema = Ack.string().matches(r'\d+\.\d+');

      expect(schema.safeParse('3.14').isOk, isTrue);
      expect(schema.safeParse('123.456').isOk, isTrue);

      // Should NOT match partial strings
      expect(schema.safeParse('pi=3.14').isOk, isFalse);
    });
  });

  group('StringSchema.contains() - No Auto-anchoring', () {
    test('performs partial matching without anchoring', () {
      final schema = Ack.string().contains(r'\d{5}');

      // Should match anywhere in the string
      expect(schema.safeParse('12345').isOk, isTrue);
      expect(schema.safeParse('abc12345').isOk, isTrue);
      expect(schema.safeParse('12345xyz').isOk, isTrue);
      expect(schema.safeParse('prefix12345suffix').isOk, isTrue);

      // Should NOT match if pattern isn't present
      expect(schema.safeParse('1234').isOk, isFalse);
    });

    test('respects explicit anchors in contains()', () {
      final schema = Ack.string().contains(r'^\d{5}');

      // Anchor is respected - must start with pattern
      expect(schema.safeParse('12345').isOk, isTrue);
      expect(schema.safeParse('12345xyz').isOk, isTrue);

      // Does not match when pattern isn't at start
      expect(schema.safeParse('abc12345').isOk, isFalse);
    });

    test('handles complex patterns in contains()', () {
      final schema = Ack.string().contains(r'foo|bar');

      expect(schema.safeParse('foo').isOk, isTrue);
      expect(schema.safeParse('bar').isOk, isTrue);
      expect(schema.safeParse('prefix_foo_suffix').isOk, isTrue);
      expect(schema.safeParse('bar_baz').isOk, isTrue);

      expect(schema.safeParse('baz').isOk, isFalse);
    });
  });

  group('StringSchema.literal() - Exact String Matching', () {
    test('matches exact string only (no regex)', () {
      final schema = Ack.string().literal('hello');

      expect(schema.safeParse('hello').isOk, isTrue);

      // Should NOT match partial or different strings
      expect(schema.safeParse('hello world').isOk, isFalse);
      expect(schema.safeParse('say hello').isOk, isFalse);
      expect(schema.safeParse('HELLO').isOk, isFalse);
      expect(schema.safeParse('hell').isOk, isFalse);
    });

    test('treats regex special characters as literal', () {
      final schema = Ack.string().literal(r'\d+');

      // Should match the literal string '\d+', not the regex pattern
      expect(schema.safeParse(r'\d+').isOk, isTrue);
      expect(schema.safeParse('123').isOk, isFalse);
    });

    test('handles special characters literally', () {
      final schema = Ack.string().literal(r'$100.00');

      expect(schema.safeParse(r'$100.00').isOk, isTrue);
      expect(schema.safeParse('100.00').isOk, isFalse);
    });
  });

  group('Method Comparison - .literal() vs .matches() vs .contains()', () {
    test('demonstrates the difference between all three methods', () {
      final literalSchema = Ack.string().literal('test');
      final matchesSchema = Ack.string().matches(r'test');
      final containsSchema = Ack.string().contains(r'test');

      // All match the exact string 'test'
      expect(literalSchema.safeParse('test').isOk, isTrue);
      expect(matchesSchema.safeParse('test').isOk, isTrue);
      expect(containsSchema.safeParse('test').isOk, isTrue);

      // With prefix/suffix
      final input = 'prefix_test_suffix';
      expect(literalSchema.safeParse(input).isOk, isFalse); // Exact match only
      expect(matchesSchema.safeParse(input).isOk, isFalse); // Full string must match pattern
      expect(containsSchema.safeParse(input).isOk, isTrue);  // Pattern anywhere in string
    });

    test('demonstrates regex pattern behavior differences', () {
      final pattern = r'\d{3}';

      final matchesSchema = Ack.string().matches(pattern);
      final containsSchema = Ack.string().contains(pattern);

      // matches() requires full string to match pattern (auto-anchored)
      expect(matchesSchema.safeParse('123').isOk, isTrue);
      expect(matchesSchema.safeParse('1234').isOk, isFalse);
      expect(matchesSchema.safeParse('abc123').isOk, isFalse);

      // contains() finds pattern anywhere in string
      expect(containsSchema.safeParse('123').isOk, isTrue);
      expect(containsSchema.safeParse('1234').isOk, isTrue);
      expect(containsSchema.safeParse('abc123xyz').isOk, isTrue);
    });
  });

  group('Edge Cases', () {
    test('handles patterns with escaped anchors', () {
      // User might want to match the literal characters ^ and $
      final schema = Ack.string().matches(r'\\^');

      // This should match strings like '\^'
      expect(schema.safeParse(r'\^').isOk, isTrue);
    });

    test('handles multi-line patterns', () {
      final schema = Ack.string().matches(r'.+');

      expect(schema.safeParse('hello').isOk, isTrue);

      // Should match the entire string
      expect(schema.safeParse('hello\nworld').isOk, isFalse);
    });

    test('handles patterns with lookaheads', () {
      final schema = Ack.string().matches(r'\d+(?=px)px');

      expect(schema.safeParse('10px').isOk, isTrue);
      expect(schema.safeParse('10em').isOk, isFalse);
    });

    test('handles patterns with word boundaries', () {
      final schema = Ack.string().matches(r'\bword\b');

      expect(schema.safeParse('word').isOk, isTrue);

      // Word boundaries don't prevent partial matching without anchors,
      // but auto-anchoring should still enforce full string match
      expect(schema.safeParse('prefix word suffix').isOk, isFalse);
    });
  });
}
