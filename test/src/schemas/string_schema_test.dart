import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

void main() {
  group('StringSchema', () {
    test('copyWith changes nullable property', () {
      final schema = StringSchema(nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result.isOk, isTrue);
    });

    test('copyWith changes constraints', () {
      final schema = StringSchema(constraints: [MaxLengthValidator(5)]);
      expect(schema.getConstraints().length, equals(1));
      expect(schema.getConstraints()[0], isA<MaxLengthValidator>());

      final newSchema = schema.copyWith(constraints: [MinLengthValidator(10)]);
      expect(newSchema.getConstraints().length, equals(1));
      expect(newSchema.getConstraints()[0], isA<MinLengthValidator>());
    });

    group('StringSchema Basic Validation', () {
      test('Non-nullable schema fails on null', () {
        final schema = StringSchema();
        final result = schema.validate(null);
        expect(result.isFail, isTrue);
        expect(result, hasOneSchemaError('non_nullable_value'));
      });

      test('Nullable schema passes on null', () {
        final schema = StringSchema(nullable: true);
        final result = schema.validate(null);
        expect(result.isOk, isTrue);
      });

      test('Invalid type returns invalid type error', () {
        final schema = StringSchema();
        final result = schema.validate(123); // Not a string.
        expect(result.isOk, isTrue);

        final strictSchema = StringSchema(strict: true);
        final strictResult = strictSchema.validate(123);
        expect(strictResult.isFail, isTrue);
        expect(strictResult, hasOneSchemaError('invalid_type'));
      });

      test('Valid string passes with no constraints', () {
        final schema = StringSchema();
        final result = schema.validate("hello");
        expect(result.isOk, isTrue);
      });
    });

    group('EmailValidator', () {
      const validator = EmailValidator();

      test('Valid emails pass validation', () {
        expect(validator.check('test@example.com'), isTrue);
        expect(validator.check('user.name@domain.com'), isTrue);
        expect(validator.check('user+tag@domain.com'), isTrue);
      });

      test('Invalid emails fail validation', () {
        expect(validator.check('not-an-email'), isFalse);
        expect(validator.check('missing@domain'), isFalse);
        expect(validator.check('@domain.com'), isFalse);
        expect(validator.check(''), isFalse);
      });

      test('schema validation works with email validator', () {
        final schema = StringSchema().isEmail();
        expect(schema.validate('test@example.com').isOk, isTrue);

        final result = schema.validate('not-an-email');
        expect(result, hasOneConstraintError('is_email'));
      });
    });

    group('HexColorValidator', () {
      const validator = HexColorValidator();

      test('Valid hex colors pass validation', () {
        expect(validator.check('#fff'), isTrue);
        expect(validator.check('#ffffff'), isTrue);
        expect(validator.check('fff'), isTrue);
        expect(validator.check('ffffff'), isTrue);
      });

      test('Invalid hex colors fail validation', () {
        expect(validator.check('#ff'), isFalse);
        expect(validator.check('red'), isFalse);
        expect(validator.check('#ggg'), isFalse);
        expect(validator.check(''), isFalse);
      });

      test('schema validation works with hex color validator', () {
        final schema = StringSchema().isHexColor();
        expect(schema.validate('#00ff55').isOk, isTrue);

        final result = schema.validate('not-a-color');
        expect(result, hasOneConstraintError('is_hex_color'));
      });
    });

    group('IsEmptyValidator', () {
      final validator = IsEmptyValidator();

      test('Empty string passes validation', () {
        expect(validator.check(''), isTrue);
      });

      test('Non-empty strings fail validation', () {
        expect(validator.check('not empty'), isFalse);
        expect(validator.check(' '), isFalse);
        expect(validator.check('a'), isFalse);
      });

      test('schema validation works with isEmpty validator', () {
        final schema = StringSchema().isEmpty();
        expect(schema.validate('').isOk, isTrue);

        final result = schema.validate('not empty');
        expect(result, hasOneConstraintError('string_is_empty'));
      });
    });

    group('MinLengthValidator', () {
      final validator = MinLengthValidator(3);

      test('Strings meeting minimum length pass validation', () {
        expect(validator.check('abc'), isTrue);
        expect(validator.check('abcd'), isTrue);
        expect(validator.check('12345'), isTrue);
      });

      test('Strings below minimum length fail validation', () {
        expect(validator.check('a'), isFalse);
        expect(validator.check('ab'), isFalse);
        expect(validator.check(''), isFalse);
      });

      test('schema validation works with minLength validator', () {
        final schema = StringSchema().minLength(3);
        expect(schema.validate('abc').isOk, isTrue);

        final result = schema.validate('ab');
        expect(result, hasOneConstraintError('string_min_length'));
      });
    });

    group('MaxLengthValidator', () {
      final validator = MaxLengthValidator(3);

      test('Strings within maximum length pass validation', () {
        expect(validator.check(''), isTrue);
        expect(validator.check('a'), isTrue);
        expect(validator.check('ab'), isTrue);
        expect(validator.check('abc'), isTrue);
      });

      test('Strings exceeding maximum length fail validation', () {
        expect(validator.check('abcd'), isFalse);
        expect(validator.check('12345'), isFalse);
      });

      test('schema validation works with maxLength validator', () {
        final schema = StringSchema().maxLength(3);
        expect(schema.validate('abc').isOk, isTrue);

        final result = schema.validate('abcd');
        expect(result, hasOneConstraintError('string_max_length'));
      });
    });

    group('OneOfValidator', () {
      final validator = OneOfValidator(['apple', 'banana']);

      test('Strings in allowed values pass validation', () {
        expect(validator.check('apple'), isTrue);
        expect(validator.check('banana'), isTrue);
      });

      test('Strings not in allowed values fail validation', () {
        expect(validator.check('orange'), isFalse);
        expect(validator.check(''), isFalse);
        expect(validator.check('APPLE'), isFalse);
      });

      test('schema validation works with oneOf validator', () {
        final schema = StringSchema().oneOf(['apple', 'banana']);
        expect(schema.validate('apple').isOk, isTrue);

        final result = schema.validate('orange');
        expect(result, hasOneConstraintError('string_one_of'));
      });
    });

    group('NotOneOfValidator', () {
      final validator = NotOneOfValidator(['apple', 'banana']);

      test('Strings not in disallowed values pass validation', () {
        expect(validator.check('orange'), isTrue);
        expect(validator.check(''), isTrue);
        expect(validator.check('APPLE'), isTrue);
      });

      test('Strings in disallowed values fail validation', () {
        expect(validator.check('apple'), isFalse);
        expect(validator.check('banana'), isFalse);
      });

      test('schema validation works with notOneOf validator', () {
        final schema = StringSchema().notOneOf(['apple', 'banana']);
        expect(schema.validate('orange').isOk, isTrue);

        final result = schema.validate('apple');
        expect(result, hasOneConstraintError('string_not_one_of'));
      });
    });

    group('EnumValidator', () {
      final validator = EnumValidator(['red', 'green', 'blue']);

      test('Strings in enum pass validation', () {
        expect(validator.check('red'), isTrue);
        expect(validator.check('green'), isTrue);
        expect(validator.check('blue'), isTrue);
      });

      test('Strings not in enum fail validation', () {
        expect(validator.check('yellow'), isFalse);
        expect(validator.check(''), isFalse);
        expect(validator.check('RED'), isFalse);
      });

      test('schema validation works with enum validator', () {
        final schema = StringSchema().isEnum(['red', 'green', 'blue']);
        expect(schema.validate('red').isOk, isTrue);

        final result = schema.validate('yellow');
        expect(result, hasOneConstraintError('string_enum'));
      });
    });

    group('NotEmptyValidator', () {
      final validator = NotEmptyValidator();

      test('Non-empty strings pass validation', () {
        expect(validator.check('hello'), isTrue);
        expect(validator.check(' '), isTrue);
        expect(validator.check('a'), isTrue);
      });

      test('Empty string fails validation', () {
        expect(validator.check(''), isFalse);
      });

      test('schema validation works with notEmpty validator', () {
        final schema = StringSchema().isNotEmpty();
        expect(schema.validate('hello').isOk, isTrue);

        final result = schema.validate('');
        expect(result, hasOneConstraintError('string_not_empty'));
      });
    });

    group('DateTimeValidator', () {
      final validator = DateTimeValidator();

      test('Valid datetime strings pass validation', () {
        expect(validator.check('2023-01-01T00:00:00.000Z'), isTrue);
        expect(validator.check('2023-12-31T23:59:59.999Z'), isTrue);
        expect(validator.check('2023-06-15T12:30:45Z'), isTrue);
      });

      test('Invalid datetime strings fail validation', () {
        expect(validator.check('not a datetime'), isFalse);
        expect(validator.check('32'), isFalse);
        expect(validator.check(''), isFalse);
      });

      test('schema validation works with datetime validator', () {
        final schema = StringSchema().isDateTime();
        expect(schema.validate('2023-01-01T00:00:00.000Z').isOk, isTrue);

        final result = schema.validate('not a datetime');
        expect(result, hasOneConstraintError('datetime'));
      });
    });
  });
}
