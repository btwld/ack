import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../test_helpers.dart';

void main() {
  group('BooleanSchema', () {
    test('copyWith changes nullable property', () {
      final schema = BooleanSchema(nullable: false);
      final newSchema = schema.copyWith(nullable: true);
      final result = newSchema.validate(null);
      expect(result, isA<Ok>());
    });

    test('copyWith changes constraints', () {
      final schema = BooleanSchema();
      expect(schema.getConstraints().length, equals(0));

      final newSchema = schema.copyWith(constraints: []);
      expect(newSchema.getConstraints().length, equals(0));
    });

    group('BooleanSchema Basic Validation', () {
      test('Non-nullable schema fails on null', () {
        final schema = BooleanSchema();
        final result = schema.validate(null);
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type,
            equals('non_nullable_value'));
      });

      test('Nullable schema passes on null', () {
        final schema = BooleanSchema(nullable: true);
        final result = schema.validate(null);
        expect(result, isA<Ok>());
      });

      test('Invalid type returns invalid type error', () {
        final schema = BooleanSchema();
        final result = schema.validate(123); // Not a boolean
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type, equals('invalid_type'));
      });

      test('Valid boolean passes with no constraints', () {
        final schema = BooleanSchema();
        final result = schema.validate(true);
        expect(result, isA<Ok>());
        expect(TestHelpers.isOk(result).value, equals(true));
      });

      test('String "true" parses to boolean true', () {
        final schema = BooleanSchema();
        final result = schema.validate("true");
        expect(result, isA<Ok>());
        expect(TestHelpers.isOk(result).value, equals(true));
      });

      test('String "false" parses to boolean false', () {
        final schema = BooleanSchema();
        final result = schema.validate("false");
        expect(result, isA<Ok>());
        expect(TestHelpers.isOk(result).value, equals(false));
      });

      test('Invalid string fails to parse to boolean', () {
        final schema = BooleanSchema();
        final result = schema.validate("not a boolean");
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type, equals('invalid_type'));
      });
    });
    group('BooleanSchema Edge Cases', () {
      test('Valid string "true" parses to true', () {
        final schema = BooleanSchema();
        final result = schema.validate("true");
        expect(result, isA<Ok>());
        expect(TestHelpers.isOk(result).value, equals(true));
      });

      test('Valid string "false" parses to false', () {
        final schema = BooleanSchema();
        final result = schema.validate("false");
        expect(result, isA<Ok>());
        expect(TestHelpers.isOk(result).value, equals(false));
      });

      test('Mixed case string "True" fails validation', () {
        final schema = BooleanSchema();
        final result = schema.validate("True");
        // bool.tryParse("True") returns null, so this should fail unless handled differently.
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type, equals('invalid_type'));
      });

      test('String with whitespace " true " fails validation', () {
        final schema = BooleanSchema();
        final result = schema.validate(" true ");
        // Again, this should fail unless you choose to trim inputs.
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type, equals('invalid_type'));
      });
    });

    group('BooleanSchema Invalid Types', () {
      test('Passing an integer returns invalid type error', () {
        final schema = BooleanSchema();
        final result = schema.validate(123);
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type, equals('invalid_type'));
      });

      test('Passing an object returns invalid type error', () {
        final schema = BooleanSchema();
        final result = schema.validate({'key': 'value'});
        expect(result, isA<Fail>());
        expect(TestHelpers.isFail(result).error.type, equals('invalid_type'));
      });
    });
  });
}
