import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('NumSchemaExtensions', () {
    group('greaterThan', () {
      test('should pass if value is greater than', () {
        final schema = IntegerSchema().greaterThan(5);
        expect(schema.validate(6).isOk, isTrue);
      });

      test('should fail if value is equal', () {
        final schema = IntegerSchema().greaterThan(5);
        final result = schema.validate(5);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Must be greater than 5, got 5.');
      });

      test('should fail if value is less than', () {
        final schema = IntegerSchema().greaterThan(5);
        final result = schema.validate(4);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Must be greater than 5, got 4.');
      });
    });

    group('min', () {
      test('should pass if value is equal', () {
        final schema = IntegerSchema().min(5);
        expect(schema.validate(5).isOk, isTrue);
      });

      test('should pass if value is greater', () {
        final schema = IntegerSchema().min(5);
        expect(schema.validate(6).isOk, isTrue);
      });

      test('should fail if value is less', () {
        final schema = IntegerSchema().min(5);
        final result = schema.validate(4);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Must be at least 5, got 4.');
      });
    });

    group('lessThan', () {
      test('should pass if value is less than', () {
        final schema = IntegerSchema().lessThan(5);
        expect(schema.validate(4).isOk, isTrue);
      });

      test('should fail if value is equal', () {
        final schema = IntegerSchema().lessThan(5);
        final result = schema.validate(5);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Must be less than 5, got 5.');
      });

      test('should fail if value is greater than', () {
        final schema = IntegerSchema().lessThan(5);
        final result = schema.validate(6);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Must be less than 5, got 6.');
      });
    });

    group('max', () {
      test('should pass if value is equal', () {
        final schema = IntegerSchema().max(5);
        expect(schema.validate(5).isOk, isTrue);
      });

      test('should pass if value is less', () {
        final schema = IntegerSchema().max(5);
        expect(schema.validate(4).isOk, isTrue);
      });

      test('should fail if value is greater', () {
        final schema = IntegerSchema().max(5);
        final result = schema.validate(6);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Must be at most 5, got 6.');
      });
    });

    group('positive', () {
      test('should pass for positive number', () {
        final schema = IntegerSchema().positive();
        expect(schema.validate(1).isOk, isTrue);
      });

      test('should fail for zero', () {
        final schema = IntegerSchema().positive();
        final result = schema.validate(0);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Must be positive, but got 0.');
      });

      test('should fail for negative number', () {
        final schema = IntegerSchema().positive();
        final result = schema.validate(-1);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Must be positive, but got -1.');
      });
    });

    group('negative', () {
      test('should pass for negative number', () {
        final schema = IntegerSchema().negative();
        expect(schema.validate(-1).isOk, isTrue);
      });

      test('should fail for zero', () {
        final schema = IntegerSchema().negative();
        final result = schema.validate(0);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Must be negative, but got 0.');
      });

      test('should fail for positive number', () {
        final schema = IntegerSchema().negative();
        final result = schema.validate(1);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Must be negative, but got 1.');
      });
    });

    group('multipleOf', () {
      test('should pass for multiple', () {
        final schema = IntegerSchema().multipleOf(5);
        expect(schema.validate(10).isOk, isTrue);
      });

      test('should fail for non-multiple', () {
        final schema = IntegerSchema().multipleOf(5);
        final result = schema.validate(11);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Must be a multiple of 5. 11 is not.');
      });
    });
  });

  group('DoubleSchemaExtensions', () {
    group('finite', () {
      test('should pass for finite number', () {
        final schema = DoubleSchema().finite();
        expect(schema.validate(1.23).isOk, isTrue);
      });

      test('should fail for infinity', () {
        final schema = DoubleSchema().finite();
        final result = schema.validate(double.infinity);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Value must be finite, but was not.');
      });

      test('should fail for negative infinity', () {
        final schema = DoubleSchema().finite();
        final result = schema.validate(double.negativeInfinity);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Value must be finite, but was not.');
      });

      test('should fail for NaN', () {
        final schema = DoubleSchema().finite();
        final result = schema.validate(double.nan);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Value must be finite, but was not.');
      });
    });
  });

  group('IntegerSchemaExtensions', () {
    group('safe', () {
      const maxSafeInteger = 9007199254740991;

      test('should pass for safe integer', () {
        final schema = IntegerSchema().safe();
        expect(schema.validate(123).isOk, isTrue);
        expect(schema.validate(maxSafeInteger).isOk, isTrue);
        expect(schema.validate(-maxSafeInteger).isOk, isTrue);
      });

      test('should fail for unsafe integer', () {
        final schema = IntegerSchema().safe();
        final result = schema.validate(maxSafeInteger + 1);
        expect(result.isOk, isFalse);
        expect(
            (result.getError() as SchemaConstraintsError)
                .constraints
                .first
                .message,
            'Value must be between -$maxSafeInteger and $maxSafeInteger, but was ${maxSafeInteger + 1}.');
      });
    });
  });
}
