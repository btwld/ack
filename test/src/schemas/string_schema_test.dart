import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

void main() {
  group('StringSchema Basic Validation', () {
    test('Non-nullable schema fails on null', () {
      final schema = StringSchema();
      final result = schema.validate(null);
      expect(result, isA<Fail>());
      expect(
          TestHelpers.isFail(result).error.type, equals('non_nullable_value'));
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
    test('Valid email passes', () {
      final schema = StringSchema().isEmail();
      final result = schema.validate("test@example.com");
      expect(result, isA<Ok>());
    });

    test('Invalid email fails', () {
      final schema = StringSchema().isEmail();
      final result = schema.validate("invalid-email");
      TestHelpers.expectConstraintErrorOfType(result, 'regex');
    });
  });

  group('HexColorValidator', () {
    test('Valid hex colors pass', () {
      final schema = StringSchema().isHexColor();
      final validColors = ['#fff', '#ffffff', 'fff', 'ffffff'];
      for (final color in validColors) {
        final result = schema.validate(color);
        expect(result, isA<Ok>(), reason: 'Color "$color" should be valid');
      }
    });

    test('Invalid hex colors fail', () {
      final schema = StringSchema().isHexColor();
      final invalidColors = ['#ff', 'red', '#ggg'];
      for (final color in invalidColors) {
        final result = schema.validate(color);
        expect(result, isA<Fail>(), reason: 'Color "$color" should be invalid');
      }
    });
  });

  group('IsEmptyValidator', () {
    test('Empty string passes', () {
      final schema = StringSchema().isEmpty();
      final result = schema.validate("");
      expect(result, isA<Ok>());
    });

    test('Non-empty string fails', () {
      final schema = StringSchema().isEmpty();
      final result = schema.validate("not empty");

      TestHelpers.expectConstraintErrorOfType(result, 'string_is_empty');
    });
  });

  group('MinLengthValidator', () {
    test('String meeting minimum length passes', () {
      final schema = StringSchema().minLength(3);
      final result = schema.validate("abc");
      expect(result, isA<Ok>());
    });

    test('String below minimum length fails', () {
      final schema = StringSchema().minLength(5);
      final result = schema.validate("abc");
      TestHelpers.expectConstraintErrorOfType(result, 'string_min_length');
    });
  });

  group('MaxLengthValidator', () {
    test('String within maximum length passes', () {
      final schema = StringSchema().maxLength(5);
      final result = schema.validate("abc");
      expect(result, isA<Ok>());
    });

    test('String exceeding maximum length fails', () {
      final schema = StringSchema().maxLength(3);
      final result = schema.validate("abcd");
      TestHelpers.expectConstraintErrorOfType(result, 'string_max_length');
    });
  });

  group('OneOfValidator', () {
    test('String in allowed values passes', () {
      final schema = StringSchema().oneOf(['apple', 'banana']);
      final result = schema.validate('apple');
      expect(result, isA<Ok>());
    });

    test('String not in allowed values fails', () {
      final schema = StringSchema().oneOf(['apple', 'banana']);
      final result = schema.validate('orange');
      TestHelpers.expectConstraintErrorOfType(result, 'string_one_of');
    });
  });

  group('NotOneOfValidator', () {
    test('String not in disallowed values passes', () {
      final schema = StringSchema().notOneOf(['apple', 'banana']);
      final result = schema.validate('orange');
      expect(result, isA<Ok>());
    });

    test('String in disallowed values fails', () {
      final schema = StringSchema().notOneOf(['apple', 'banana']);
      final result = schema.validate('apple');
      TestHelpers.expectConstraintErrorOfType(result, 'string_not_one_of');
    });
  });

  group('EnumValidator', () {
    test('String in enum passes', () {
      final schema = StringSchema().isEnum(['red', 'green', 'blue']);
      final result = schema.validate('red');
      expect(result, isA<Ok>());
    });

    test('String not in enum fails', () {
      final schema = StringSchema().isEnum(['red', 'green', 'blue']);
      final result = schema.validate('yellow');
      TestHelpers.expectConstraintErrorOfType(result, 'string_enum');
    });
  });

  group('UriValidator', () {
    test('Valid URI passes', () {
      final schema = StringSchema().isUri();
      final result = schema.validate('https://example.com');
      expect(result, isA<Ok>());
    });

    test('Invalid URI fails', () {
      final schema = StringSchema().isUri();
      final result = schema.validate('not a uri');
      TestHelpers.expectConstraintErrorOfType(result, 'string_uri');
    });
  });

  group('NotEmptyValidator', () {
    test('Non-empty string passes', () {
      final schema = StringSchema().isNotEmpty();
      final result = schema.validate('hello');
      expect(result, isA<Ok>());
    });

    test('Empty string fails', () {
      final schema = StringSchema().isNotEmpty();
      final result = schema.validate('');
      TestHelpers.expectConstraintErrorOfType(result, 'string_not_empty');
    });
  });

  group('DateTimeValidator', () {
    test('Valid datetime string passes', () {
      final schema = StringSchema().isDateTime();
      final result = schema.validate('2023-01-01T00:00:00.000Z');
      expect(result, isA<Ok>());
    });

    test('Invalid datetime string fails', () {
      final schema = StringSchema().isDateTime();
      final result = schema.validate('not a datetime');
      TestHelpers.expectConstraintErrorOfType(result, 'datetime');
    });
  });

  group('Chained Validators', () {
    test('Multiple constraints are applied', () {
      final schema = StringSchema().isNotEmpty().minLength(3).maxLength(5);
      // Too short.
      var result = schema.validate("hi");
      expect(result, isA<Fail>());
      // Too long.
      result = schema.validate("hellooo");
      expect(result, isA<Fail>());
      // Valid string.
      result = schema.validate("hey");
      expect(result, isA<Ok>());
    });
  });

  group('copyWith and toMap', () {
    test('copyWith changes nullable property', () {
      final schema = StringSchema(nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result, isA<Ok>());
    });

    test('toMap returns proper structure', () {
      final schema = StringSchema().isEmail().minLength(5);
      final map = schema.toMap();
      expect(map, isA<Map<String, Object?>>());
      expect(map['type'], equals('schema'));
      expect(map['constraints'], isA<Iterable>());
      expect((map['constraints'] as Iterable).length, equals(2));
    });
  });
}
