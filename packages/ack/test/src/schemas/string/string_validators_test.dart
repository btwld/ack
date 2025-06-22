import 'package:ack/src/constraints/core/comparison_constraint.dart';
import 'package:ack/src/constraints/core/pattern_constraint.dart';
import 'package:test/test.dart';

void main() {
  group('String Validators', () {
    group('EmailValidator', () {
      final validator = PatternConstraint.email();

      test('Valid emails pass validation', () {
        expect(validator.isValid('test@example.com'), isTrue);
        expect(validator.isValid('user.name@domain.com'), isTrue);
        expect(validator.isValid('user+tag@domain.com'), isTrue);
      });

      test('Invalid emails fail validation', () {
        expect(validator.isValid('not-an-email'), isFalse);
        expect(validator.isValid('missing@domain'), isFalse);
        expect(validator.isValid('@domain.com'), isFalse);
        expect(validator.isValid(''), isFalse);
      });

      test('schema validation works with email validator', () {
        final validator = PatternConstraint.email();
        expect(validator.isValid('test@example.com'), isTrue);

        final result = validator.validate('not-an-email');
        expect(result?.message,
            equals('Invalid email format. Ex: example@domain.com'));
      });
    });

    group('HexColorValidator', () {
      final validator = PatternConstraint.hexColor();

      test('Valid hex colors pass validation', () {
        expect(validator.isValid('#fff'), isTrue);
        expect(validator.isValid('#ffffff'), isTrue);
        expect(validator.isValid('fff'), isTrue);
        expect(validator.isValid('ffffff'), isTrue);
      });

      test('Invalid hex colors fail validation', () {
        expect(validator.isValid('#ff'), isFalse);
        expect(validator.isValid('red'), isFalse);
        expect(validator.isValid('#ggg'), isFalse);
        expect(validator.isValid(''), isFalse);
      });

      test('schema validation works with hex color validator', () {
        final validator = PatternConstraint.hexColor();
        expect(validator.isValid('#00ff55'), isTrue);

        final result = validator.validate('not-a-color');
        expect(
            result?.message, equals('Invalid hex color format. Ex: #f0f0f0'));
      });
    });

    group('IsEmptyValidator', () {
      final validator = ComparisonConstraint.stringExactLength(0);

      test('Empty string passes validation', () {
        expect(validator.isValid(''), isTrue);
      });

      test('Non-empty strings fail validation', () {
        expect(validator.isValid('not empty'), isFalse);
        expect(validator.isValid(' '), isFalse);
        expect(validator.isValid('a'), isFalse);
      });

      test('schema validation works with isEmpty validator', () {
        final validator = ComparisonConstraint.stringExactLength(0);
        expect(validator.isValid(''), isTrue);

        final result = validator.validate('not empty');
        expect(result?.message, equals('Must be exactly 0 characters'));
      });
    });

    group('MinLengthValidator', () {
      final validator = ComparisonConstraint.stringMinLength(3);

      test('Strings meeting minimum length pass validation', () {
        expect(validator.isValid('abc'), isTrue);
        expect(validator.isValid('abcd'), isTrue);
        expect(validator.isValid('12345'), isTrue);
      });

      test('Strings below minimum length fail validation', () {
        expect(validator.isValid('a'), isFalse);
        expect(validator.isValid('ab'), isFalse);
        expect(validator.isValid(''), isFalse);
      });

      test('schema validation works with minLength validator', () {
        final validator = ComparisonConstraint.stringMinLength(3);
        expect(validator.isValid('abc'), isTrue);

        final result = validator.validate('ab');
        expect(result?.message, equals('Too short, min 3 characters'));
      });
    });

    group('MaxLengthValidator', () {
      final validator = ComparisonConstraint.stringMaxLength(3);

      test('Strings within maximum length pass validation', () {
        expect(validator.isValid(''), isTrue);
        expect(validator.isValid('a'), isTrue);
        expect(validator.isValid('ab'), isTrue);
        expect(validator.isValid('abc'), isTrue);
      });

      test('Strings exceeding maximum length fail validation', () {
        expect(validator.isValid('abcd'), isFalse);
        expect(validator.isValid('12345'), isFalse);
      });

      test('schema validation works with maxLength validator', () {
        final validator = ComparisonConstraint.stringMaxLength(3);
        expect(validator.isValid('abc'), isTrue);

        final result = validator.validate('abcd');
        expect(result?.message, equals('Too long, max 3 characters'));
      });
    });

    group('NotOneOfValidator', () {
      final validator = PatternConstraint.notEnumValues(['apple', 'banana']);

      test('Strings not in disallowed values pass validation', () {
        expect(validator.isValid('orange'), isTrue);
        expect(validator.isValid(''), isTrue);
        expect(validator.isValid('APPLE'), isTrue);
      });

      test('Strings in disallowed values fail validation', () {
        expect(validator.isValid('apple'), isFalse);
        expect(validator.isValid('banana'), isFalse);
      });

      test('schema validation works with notOneOf validator', () {
        final validator = PatternConstraint.notEnumValues(['apple', 'banana']);
        expect(validator.isValid('orange'), isTrue);
        expect(validator.isValid(''), isTrue);
        expect(validator.isValid('APPLE'), isTrue);
        expect(validator.isValid('apple'), isFalse);

        final result = validator.validate('apple');

        expect(result?.message, contains('apple'));
      });
    });

    group('EnumValidator', () {
      final validator = PatternConstraint.enumString(['red', 'green', 'blue']);

      test('Strings in enum pass validation', () {
        expect(validator.isValid('red'), isTrue);
        expect(validator.isValid('green'), isTrue);
        expect(validator.isValid('blue'), isTrue);
      });

      test('Strings not in enum fail validation', () {
        expect(validator.isValid('yellow'), isFalse);
        expect(validator.isValid(''), isFalse);
        expect(validator.isValid('RED'), isFalse);
      });

      test('schema validation works with enum validator', () {
        final validator =
            PatternConstraint.enumString(['red', 'green', 'blue']);
        expect(validator.isValid('red'), isTrue);

        final result = validator.validate('yellow');
        expect(result?.message, equals('Allowed: "red", "green", "blue"'));
      });
    });

    group('NotEmptyValidator', () {
      final validator = ComparisonConstraint.stringMinLength(1);

      test('Non-empty strings pass validation', () {
        expect(validator.isValid('hello'), isTrue);
        expect(validator.isValid(' '), isTrue);
        expect(validator.isValid('a'), isTrue);
      });

      test('Empty string fails validation', () {
        expect(validator.isValid(''), isFalse);
      });

      test('schema validation works with notEmpty validator', () {
        final validator = ComparisonConstraint.stringMinLength(1);
        expect(validator.isValid('hello'), isTrue);

        final result = validator.validate('');
        expect(result?.message, equals('Too short, min 1 characters'));
      });
    });

    group('DateTimeValidator', () {
      final validator = PatternConstraint.dateTime();

      test('Valid datetime strings pass validation', () {
        expect(validator.isValid('2023-01-01T00:00:00.000Z'), isTrue);
        expect(validator.isValid('2023-12-31T23:59:59.999Z'), isTrue);
        expect(validator.isValid('2023-06-15T12:30:45Z'), isTrue);
      });

      test('Invalid datetime strings fail validation', () {
        expect(validator.isValid('not a datetime'), isFalse);
        expect(validator.isValid('32'), isFalse);
        expect(validator.isValid(''), isFalse);
      });

      test('schema validation works with datetime validator', () {
        final validator = PatternConstraint.dateTime();
        expect(validator.isValid('2021-01-01T00:00:00Z'), isTrue);

        final result = validator.validate('not a datetime');
        expect(
            result?.message, equals('Invalid date-time (ISO 8601 required)'));
      });
    });
  });
}
