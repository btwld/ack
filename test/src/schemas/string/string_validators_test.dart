import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('String Validators', () {
    group('EmailValidator', () {
      final validator = StringEmailConstraint();

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
        final validator = StringEmailConstraint();
        expect(validator.isValid('test@example.com'), isTrue);

        final result = validator.validate('not-an-email');
        expect(result?.message, contains('not-an-email'));
      });
    });

    group('HexColorValidator', () {
      final validator = StringHexColorValidator();

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
        final validator = StringHexColorValidator();
        expect(validator.isValid('#00ff55'), isTrue);

        final result = validator.validate('not-a-color');
        expect(result?.message, contains('not-a-color'));
      });
    });

    group('IsEmptyValidator', () {
      final validator = StringEmptyConstraint();

      test('Empty string passes validation', () {
        expect(validator.isValid(''), isTrue);
      });

      test('Non-empty strings fail validation', () {
        expect(validator.isValid('not empty'), isFalse);
        expect(validator.isValid(' '), isFalse);
        expect(validator.isValid('a'), isFalse);
      });

      test('schema validation works with isEmpty validator', () {
        final validator = StringEmptyConstraint();
        expect(validator.isValid(''), isTrue);

        final result = validator.validate('not empty');
        expect(result?.message, contains('not empty'));
      });
    });

    group('MinLengthValidator', () {
      final validator = StringMinLengthConstraint(3);

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
        final validator = StringMinLengthConstraint(3);
        expect(validator.isValid('abc'), isTrue);

        final result = validator.validate('ab');
        expect(result?.message, contains('(2)'));
        expect(result?.message, contains('(3)'));
      });
    });

    group('MaxLengthValidator', () {
      final validator = StringMaxLengthConstraint(3);

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
        final validator = StringMaxLengthConstraint(3);
        expect(validator.isValid('abc'), isTrue);

        final result = validator.validate('abcd');
        expect(result?.message, contains('(4)'));
        expect(result?.message, contains('(3)'));
      });
    });

    group('NotOneOfValidator', () {
      final validator = StringNotOneOfValidator(['apple', 'banana']);

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
        final validator = StringNotOneOfValidator(['apple', 'banana']);
        expect(validator.isValid('orange'), isTrue);
        expect(validator.isValid(''), isTrue);
        expect(validator.isValid('APPLE'), isTrue);
        expect(validator.isValid('apple'), isFalse);

        final result = validator.validate('apple');

        expect(result?.message, contains('apple'));
      });
    });

    group('EnumValidator', () {
      final validator = StringEnumConstraint(['red', 'green', 'blue']);

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
        final validator = StringEnumConstraint(['red', 'green', 'blue']);
        expect(validator.isValid('red'), isTrue);

        final result = validator.validate('yellow');
        expect(result?.message, contains('yellow'));
      });
    });

    group('NotEmptyValidator', () {
      final validator = StringNotEmptyValidator();

      test('Non-empty strings pass validation', () {
        expect(validator.isValid('hello'), isTrue);
        expect(validator.isValid(' '), isTrue);
        expect(validator.isValid('a'), isTrue);
      });

      test('Empty string fails validation', () {
        expect(validator.isValid(''), isFalse);
      });

      test('schema validation works with notEmpty validator', () {
        final validator = StringNotEmptyValidator();
        expect(validator.isValid('hello'), isTrue);

        final result = validator.validate('');
        expect(result?.message, contains(''));
      });
    });

    group('DateTimeValidator', () {
      final validator = StringDateTimeConstraint();

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
        final validator = StringDateTimeConstraint();
        expect(validator.isValid('2023-01-01T00:00:00.000Z'), isTrue);

        final result = validator.validate('not a datetime');
        expect(result?.message, contains('not a datetime'));
      });
    });
  });
}
