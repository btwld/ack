import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

void main() {
  group('StringSchema', () {
    //copy with
    test('copyWith changes nullable property', () {
      final schema = StringSchema(nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result, isA<Ok>());
    });

    test('copyWith changes constraints', () {
      final schema = StringSchema(constraints: [MaxLengthValidator(5)]);

      // Check there is one constraint
      expect(schema.getConstraints().length, equals(1));

      // Check the constraint is the old one
      expect(schema.getConstraints()[0], isA<MaxLengthValidator>());

      final newSchema = schema.copyWith(constraints: [MinLengthValidator(10)]);

      // Check there is one constraint
      expect(newSchema.getConstraints().length, equals(1));

      // Check the constraint is the new one
      expect(newSchema.getConstraints()[0], isA<MinLengthValidator>());
    });

    group('StringSchema Basic Validation', () {
      test('Non-nullable schema fails on null', () {
        final schema = StringSchema();
        final result = schema.validate(null);
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type,
            equals('non_nullable_value'));
      });

      test('Nullable schema passes on null', () {
        final schema = StringSchema(nullable: true);
        final result = schema.validate(null);
        expect(result, isA<Ok>());
      });

      test('Invalid type returns invalid type error', () {
        final schema = StringSchema();
        final result = schema.validate(123); // Not a string.
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type, equals('invalid_type'));
      });

      test('Valid string passes with no constraints', () {
        final schema = StringSchema();
        final result = schema.validate("hello");
        expect(result, isA<Ok>());
        expect(TestHelpers.isOk(result).value, equals("hello"));
      });
    });

    group('EmailValidator', () {
      const validator = EmailValidator();

      bool isValid(String email) => validator.validate(email) == null;

      test('Valid emails pass validation', () {
        expect(isValid('test@example.com'), isTrue);
        expect(isValid('user.name@domain.com'), isTrue);
        expect(isValid('user+tag@domain.com'), isTrue);
      });

      test('Invalid emails fail validation', () {
        expect(isValid('not-an-email'), isFalse);
        expect(isValid('missing@domain'), isFalse);
        expect(isValid('@domain.com'), isFalse);
        expect(isValid(''), isFalse);
      });

      test('schema validation works with email validator', () {
        final schema = StringSchema().isEmail();
        expect(schema.validate('test@example.com'), isA<Ok>());

        final result = schema.validate('not-an-email');
        TestHelpers.expectConstraintErrorOfType(result, 'regex');
      });
    });

    group('HexColorValidator', () {
      const validator = HexColorValidator();

      bool isValid(String color) => validator.validate(color) == null;

      test('Valid hex colors pass validation', () {
        expect(isValid('#fff'), isTrue);
        expect(isValid('#ffffff'), isTrue);
        expect(isValid('fff'), isTrue);
        expect(isValid('ffffff'), isTrue);
      });

      test('Invalid hex colors fail validation', () {
        expect(isValid('#ff'), isFalse);
        expect(isValid('red'), isFalse);
        expect(isValid('#ggg'), isFalse);
        expect(isValid(''), isFalse);
      });

      test('schema validation works with hex color validator', () {
        final schema = StringSchema().isHexColor();
        expect(schema.validate('#ff0000'), isA<Ok>());

        final result = schema.validate('not-a-color');
        TestHelpers.expectConstraintErrorOfType(result, 'regex');
      });
    });

    group('IsEmptyValidator', () {
      final validator = IsEmptyValidator();

      bool isValid(String value) => validator.validate(value) == null;

      test('Empty string passes validation', () {
        expect(isValid(''), isTrue);
      });

      test('Non-empty strings fail validation', () {
        expect(isValid('not empty'), isFalse);
        expect(isValid(' '), isFalse);
        expect(isValid('a'), isFalse);
      });

      test('schema validation works with isEmpty validator', () {
        final schema = StringSchema().isEmpty();
        expect(schema.validate(''), isA<Ok>());

        final result = schema.validate('not empty');
        TestHelpers.expectConstraintErrorOfType(result, 'string_is_empty');
      });
    });

    group('MinLengthValidator', () {
      final validator = MinLengthValidator(3);

      bool isValid(String value) => validator.validate(value) == null;

      test('Strings meeting minimum length pass validation', () {
        expect(isValid('abc'), isTrue);
        expect(isValid('abcd'), isTrue);
        expect(isValid('12345'), isTrue);
      });

      test('Strings below minimum length fail validation', () {
        expect(isValid('a'), isFalse);
        expect(isValid('ab'), isFalse);
        expect(isValid(''), isFalse);
      });

      test('schema validation works with minLength validator', () {
        final schema = StringSchema().minLength(3);
        expect(schema.validate('abc'), isA<Ok>());

        final result = schema.validate('ab');
        TestHelpers.expectConstraintErrorOfType(result, 'string_min_length');
      });
    });

    group('MaxLengthValidator', () {
      final validator = MaxLengthValidator(3);

      bool isValid(String value) => validator.validate(value) == null;

      test('Strings within maximum length pass validation', () {
        expect(isValid(''), isTrue);
        expect(isValid('a'), isTrue);
        expect(isValid('ab'), isTrue);
        expect(isValid('abc'), isTrue);
      });

      test('Strings exceeding maximum length fail validation', () {
        expect(isValid('abcd'), isFalse);
        expect(isValid('12345'), isFalse);
      });

      test('schema validation works with maxLength validator', () {
        final schema = StringSchema().maxLength(3);
        expect(schema.validate('abc'), isA<Ok>());

        final result = schema.validate('abcd');
        TestHelpers.expectConstraintErrorOfType(result, 'string_max_length');
      });
    });

    group('OneOfValidator', () {
      final validator = OneOfValidator(['apple', 'banana']);

      bool isValid(String value) => validator.validate(value) == null;

      test('Strings in allowed values pass validation', () {
        expect(isValid('apple'), isTrue);
        expect(isValid('banana'), isTrue);
      });

      test('Strings not in allowed values fail validation', () {
        expect(isValid('orange'), isFalse);
        expect(isValid(''), isFalse);
        expect(isValid('APPLE'), isFalse);
      });

      test('schema validation works with oneOf validator', () {
        final schema = StringSchema().oneOf(['apple', 'banana']);
        expect(schema.validate('apple'), isA<Ok>());

        final result = schema.validate('orange');
        TestHelpers.expectConstraintErrorOfType(result, 'string_one_of');
      });
    });

    group('NotOneOfValidator', () {
      final validator = NotOneOfValidator(['apple', 'banana']);

      bool isValid(String value) => validator.validate(value) == null;

      test('Strings not in disallowed values pass validation', () {
        expect(isValid('orange'), isTrue);
        expect(isValid(''), isTrue);
        expect(isValid('APPLE'), isTrue);
      });

      test('Strings in disallowed values fail validation', () {
        expect(isValid('apple'), isFalse);
        expect(isValid('banana'), isFalse);
      });

      test('schema validation works with notOneOf validator', () {
        final schema = StringSchema().notOneOf(['apple', 'banana']);
        expect(schema.validate('orange'), isA<Ok>());

        final result = schema.validate('apple');
        TestHelpers.expectConstraintErrorOfType(result, 'string_not_one_of');
      });
    });

    group('EnumValidator', () {
      final validator = EnumValidator(['red', 'green', 'blue']);

      bool isValid(String value) => validator.validate(value) == null;

      test('Strings in enum pass validation', () {
        expect(isValid('red'), isTrue);
        expect(isValid('green'), isTrue);
        expect(isValid('blue'), isTrue);
      });

      test('Strings not in enum fail validation', () {
        expect(isValid('yellow'), isFalse);
        expect(isValid(''), isFalse);
        expect(isValid('RED'), isFalse);
      });

      test('schema validation works with enum validator', () {
        final schema = StringSchema().isEnum(['red', 'green', 'blue']);
        expect(schema.validate('red'), isA<Ok>());

        final result = schema.validate('yellow');
        TestHelpers.expectConstraintErrorOfType(result, 'string_enum');
      });
    });

    group('NotEmptyValidator', () {
      final validator = NotEmptyValidator();

      bool isValid(String value) => validator.validate(value) == null;

      test('Non-empty strings pass validation', () {
        expect(isValid('hello'), isTrue);
        expect(isValid(' '), isTrue);
        expect(isValid('a'), isTrue);
      });

      test('Empty string fails validation', () {
        expect(isValid(''), isFalse);
      });

      test('schema validation works with notEmpty validator', () {
        final schema = StringSchema().isNotEmpty();
        expect(schema.validate('hello'), isA<Ok>());

        final result = schema.validate('');
        TestHelpers.expectConstraintErrorOfType(result, 'string_not_empty');
      });
    });

    group('DateTimeValidator', () {
      final validator = DateTimeValidator();

      bool isValid(String value) => validator.validate(value) == null;

      test('Valid datetime strings pass validation', () {
        expect(isValid('2023-01-01T00:00:00.000Z'), isTrue);
        expect(isValid('2023-12-31T23:59:59.999Z'), isTrue);
        expect(isValid('2023-06-15T12:30:45Z'), isTrue);
      });

      test('Invalid datetime strings fail validation', () {
        expect(isValid('not a datetime'), isFalse);
        expect(isValid('32'), isFalse);
        expect(isValid(''), isFalse);
      });

      test('schema validation works with datetime validator', () {
        final schema = StringSchema().isDateTime();
        expect(schema.validate('2023-01-01T00:00:00.000Z'), isA<Ok>());

        final result = schema.validate('not a datetime');
        TestHelpers.expectConstraintErrorOfType(result, 'datetime');
      });
    });
  });
}
