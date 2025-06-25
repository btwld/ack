import 'package:ack/ack.dart';
import 'package:ack/src/constraints/validators.dart';
import 'package:test/test.dart';

void main() {
  group('Core Schema Features', () {
    group('isNullable', () {
      test('non-nullable StringSchema should fail on null', () {
        final schema = StringSchema(isNullable: false);
        final result = schema.validate(null);
        expect(result.isOk, isFalse);
        final error = result.getError() as SchemaConstraintsError;
        expect(error.getConstraint<NonNullableConstraint>(), isNotNull);
        expect(error.constraints.first.message,
            'Value is required and cannot be null.');
      });

      test('nullable StringSchema should pass on null', () {
        final schema = StringSchema(isNullable: true);
        final result = schema.validate(null);
        expect(result.isOk, isTrue);
        expect(result.getOrNull(), isNull);
      });

      test('non-nullable IntegerSchema should fail on null', () {
        final schema = IntegerSchema(isNullable: false);
        final result = schema.validate(null);
        expect(result.isOk, isFalse);
      });

      test('nullable IntegerSchema should pass on null', () {
        final schema = IntegerSchema(isNullable: true);
        final result = schema.validate(null);
        expect(result.isOk, isTrue);
      });
    });

    group('defaultValue', () {
      test('should apply default value for null input', () {
        final schema = StringSchema(defaultValue: 'default');
        final result = schema.validate(null);
        expect(result.isOk, isTrue);
        expect(result.getOrNull(), 'default');
      });

      test('should not apply default value for non-null input', () {
        final schema = StringSchema(defaultValue: 'default');
        final result = schema.validate('actual');
        expect(result.isOk, isTrue);
        expect(result.getOrNull(), 'actual');
      });

      test('default value is still validated against constraints', () {
        final schema = StringSchema(defaultValue: 'short').minLength(10);
        final result = schema.validate(null);
        expect(result.isOk, isFalse);
        final error = result.getError() as SchemaConstraintsError;
        // The default value should be validated against constraints.
        // This was fixed in the refactor - now default values are properly validated.
        expect(error.constraints.first.message,
            'Too short. Minimum 10 characters, got 5.');
      });
    });

    group('Type Conversion', () {
      test('StringSchema should fail for non-string input with strict parsing',
          () {
        final schema = StringSchema().strictParsing();
        final result = schema.validate(123);
        expect(result.isOk, isFalse);
        final error = result.getError() as SchemaConstraintsError;
        expect(error.getConstraint<InvalidTypeConstraint>(), isNotNull);
        expect(error.constraints.first.message,
            'Invalid type. Expected String, but got int.');
      });

      test('IntegerSchema should fail for non-integer input', () {
        final schema = IntegerSchema();
        final result = schema.validate('not-a-number');
        expect(result.isOk, isFalse);
        final error = result.getError() as SchemaConstraintsError;
        expect(error.getConstraint<InvalidTypeConstraint>(), isNotNull);
        expect(error.constraints.first.message,
            'Invalid type. Expected int, but got String.');
      });

      test('BooleanSchema should fail for non-boolean input', () {
        final schema = BooleanSchema();
        final result = schema.validate(1);
        expect(result.isOk, isFalse);
        final error = result.getError() as SchemaConstraintsError;
        expect(error.getConstraint<InvalidTypeConstraint>(), isNotNull);
        expect(error.constraints.first.message,
            'Invalid type. Expected bool, but got int.');
      });
    });
  });
}
