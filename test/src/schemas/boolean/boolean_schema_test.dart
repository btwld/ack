import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../../test_helpers.dart';

void main() {
  group('BooleanSchema', () {
    test('copyWith changes nullable property', () {
      final schema = BooleanSchema(nullable: false);
      expect(schema.validate(null).isFail, isTrue);
      final newSchema = schema.copyWith(nullable: true);
      expect(newSchema.validate(null).isOk, isTrue);
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

        expect(result, hasOneSchemaError('non_nullable_value'));
      });

      test('Nullable schema passes on null', () {
        final schema = BooleanSchema(nullable: true);
        final result = schema.validate(null);

        expect(result.isOk, isTrue);
      });

      test('Invalid type returns invalid type error', () {
        final schema = BooleanSchema();
        final result = schema.validate(123); // Not a boolean

        expect(result, hasOneSchemaError('invalid_type'));
      });

      test('Valid boolean passes with no constraints', () {
        final schema = BooleanSchema();
        final result = schema.validate(true);

        expect(result.isOk, isTrue);
      });

      test('String "true" parses to boolean true', () {
        final schema = BooleanSchema();
        final result = schema.validate("true");

        expect(result.isOk, isTrue);
      });

      test('String "false" parses to boolean false', () {
        final schema = BooleanSchema();
        final result = schema.validate("false");

        expect(result.isOk, isTrue);
      });

      test('Invalid string fails to parse to boolean', () {
        final schema = BooleanSchema();
        final result = schema.validate("not a boolean");

        expect(result, hasOneSchemaError('invalid_type'));
      });
    });
  });
}
