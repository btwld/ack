import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('NumSchemaExtensions', () {
    group('greaterThan', () {
      test('should pass if value is greater than', () {
        final schema = IntegerSchema().greaterThan(5);
        expect(schema.safeParse(6).isOk, isTrue);
      });

      test('should fail if value is equal', () {
        final schema = IntegerSchema().greaterThan(5);
        final result = schema.safeParse(5);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Must be greater than 5, got 5.',
        );
      });

      test('should fail if value is less than', () {
        final schema = IntegerSchema().greaterThan(5);
        final result = schema.safeParse(4);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Must be greater than 5, got 4.',
        );
      });
    });

    group('min', () {
      test('should pass if value is equal', () {
        final schema = IntegerSchema().min(5);
        expect(schema.safeParse(5).isOk, isTrue);
      });

      test('should pass if value is greater', () {
        final schema = IntegerSchema().min(5);
        expect(schema.safeParse(6).isOk, isTrue);
      });

      test('should fail if value is less', () {
        final schema = IntegerSchema().min(5);
        final result = schema.safeParse(4);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Must be at least 5, got 4.',
        );
      });
    });

    group('lessThan', () {
      test('should pass if value is less than', () {
        final schema = IntegerSchema().lessThan(5);
        expect(schema.safeParse(4).isOk, isTrue);
      });

      test('should fail if value is equal', () {
        final schema = IntegerSchema().lessThan(5);
        final result = schema.safeParse(5);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Must be less than 5, got 5.',
        );
      });

      test('should fail if value is greater than', () {
        final schema = IntegerSchema().lessThan(5);
        final result = schema.safeParse(6);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Must be less than 5, got 6.',
        );
      });
    });

    group('max', () {
      test('should pass if value is equal', () {
        final schema = IntegerSchema().max(5);
        expect(schema.safeParse(5).isOk, isTrue);
      });

      test('should pass if value is less', () {
        final schema = IntegerSchema().max(5);
        expect(schema.safeParse(4).isOk, isTrue);
      });

      test('should fail if value is greater', () {
        final schema = IntegerSchema().max(5);
        final result = schema.safeParse(6);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Must be at most 5, got 6.',
        );
      });
    });

    group('positive', () {
      test('should pass for positive number', () {
        final schema = IntegerSchema().positive();
        expect(schema.safeParse(1).isOk, isTrue);
      });

      test('should fail for zero', () {
        final schema = IntegerSchema().positive();
        final result = schema.safeParse(0);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Must be positive, but got 0.',
        );
      });

      test('should fail for negative number', () {
        final schema = IntegerSchema().positive();
        final result = schema.safeParse(-1);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Must be positive, but got -1.',
        );
      });
    });

    group('negative', () {
      test('should pass for negative number', () {
        final schema = IntegerSchema().negative();
        expect(schema.safeParse(-1).isOk, isTrue);
      });

      test('should fail for zero', () {
        final schema = IntegerSchema().negative();
        final result = schema.safeParse(0);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Must be negative, but got 0.',
        );
      });

      test('should fail for positive number', () {
        final schema = IntegerSchema().negative();
        final result = schema.safeParse(1);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Must be negative, but got 1.',
        );
      });
    });

    group('multipleOf', () {
      test('should pass for multiple', () {
        final schema = IntegerSchema().multipleOf(5);
        expect(schema.safeParse(10).isOk, isTrue);
      });

      test('should fail for non-multiple', () {
        final schema = IntegerSchema().multipleOf(5);
        final result = schema.safeParse(11);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Must be a multiple of 5. 11 is not.',
        );
      });

      test('should throw ArgumentError when multipleOf is zero', () {
        expect(
          () => IntegerSchema().multipleOf(0),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'multipleOf value cannot be zero',
            ),
          ),
        );
      });

      test(
        'should throw ArgumentError when multipleOf is zero for doubles',
        () {
          expect(
            () => DoubleSchema().multipleOf(0.0),
            throwsA(
              isA<ArgumentError>().having(
                (e) => e.message,
                'message',
                'multipleOf value cannot be zero',
              ),
            ),
          );
        },
      );
    });
  });

  group('DoubleSchemaExtensions', () {
    group('finite', () {
      test('should pass for finite number', () {
        final schema = DoubleSchema().finite();
        expect(schema.safeParse(1.23).isOk, isTrue);
      });

      test('should fail for infinity', () {
        final schema = DoubleSchema().finite();
        final result = schema.safeParse(double.infinity);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Value must be finite, but was not.',
        );
      });

      test('should fail for negative infinity', () {
        final schema = DoubleSchema().finite();
        final result = schema.safeParse(double.negativeInfinity);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Value must be finite, but was not.',
        );
      });

      test('should fail for NaN', () {
        final schema = DoubleSchema().finite();
        final result = schema.safeParse(double.nan);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Value must be finite, but was not.',
        );
      });
    });
  });

  group('NumberSchemaExtensions', () {
    test('min and max validate int and double values', () {
      final schema = NumberSchema().min(1).max(3.5);

      expect(schema.safeParse(1).isOk, isTrue);
      expect(schema.safeParse(2.5).isOk, isTrue);
      expect(schema.safeParse(0).isFail, isTrue);
      expect(schema.safeParse(4).isFail, isTrue);
    });

    test('exclusive bounds validate numeric values', () {
      final schema = NumberSchema().greaterThan(1).lessThan(3);

      expect(schema.safeParse(2).isOk, isTrue);
      expect(schema.safeParse(1).isFail, isTrue);
      expect(schema.safeParse(3).isFail, isTrue);
    });

    test('positive and negative validate numeric values', () {
      expect(NumberSchema().positive().safeParse(1).isOk, isTrue);
      expect(NumberSchema().positive().safeParse(0).isFail, isTrue);
      expect(NumberSchema().negative().safeParse(-1).isOk, isTrue);
      expect(NumberSchema().negative().safeParse(0).isFail, isTrue);
    });

    test('multipleOf validates numeric values', () {
      final schema = NumberSchema().multipleOf(0.5);

      expect(schema.safeParse(1).isOk, isTrue);
      expect(schema.safeParse(1.5).isOk, isTrue);
      expect(schema.safeParse(1.25).isFail, isTrue);
    });

    test('finite rejects non-finite values', () {
      final schema = NumberSchema().finite();

      expect(schema.safeParse(1).isOk, isTrue);
      expect(schema.safeParse(1.5).isOk, isTrue);
      expect(schema.safeParse(double.nan).isFail, isTrue);
      expect(schema.safeParse(double.infinity).isFail, isTrue);
    });

    test('constraints emit JSON Schema keywords', () {
      expect(NumberSchema().min(1).toJsonSchema(), {
        'type': 'number',
        'minimum': 1,
      });
      expect(NumberSchema().max(2.5).toJsonSchema(), {
        'type': 'number',
        'maximum': 2.5,
      });
      expect(NumberSchema().greaterThan(1).toJsonSchema(), {
        'type': 'number',
        'exclusiveMinimum': 1,
      });
      expect(NumberSchema().lessThan(2).toJsonSchema(), {
        'type': 'number',
        'exclusiveMaximum': 2,
      });
      expect(NumberSchema().multipleOf(0.5).toJsonSchema(), {
        'type': 'number',
        'multipleOf': 0.5,
      });
      expect(NumberSchema().positive().toJsonSchema(), {
        'type': 'number',
        'exclusiveMinimum': 0,
      });
      expect(NumberSchema().negative().toJsonSchema(), {
        'type': 'number',
        'exclusiveMaximum': 0,
      });
      expect(NumberSchema().finite().toJsonSchema(), {'type': 'number'});
    });
  });

  group('IntegerSchemaExtensions', () {
    group('safe', () {
      const maxSafeInteger = 9007199254740991;

      test('should pass for safe integer', () {
        final schema = IntegerSchema().safe();
        expect(schema.safeParse(123).isOk, isTrue);
        expect(schema.safeParse(maxSafeInteger).isOk, isTrue);
        expect(schema.safeParse(-maxSafeInteger).isOk, isTrue);
      });

      test('should fail for unsafe integer', () {
        final schema = IntegerSchema().safe();
        final result = schema.safeParse(maxSafeInteger + 1);
        expect(result.isOk, isFalse);
        expect(
          (result.getError() as SchemaConstraintsError)
              .constraints
              .first
              .message,
          'Value must be between -$maxSafeInteger and $maxSafeInteger, but was ${maxSafeInteger + 1}.',
        );
      });
    });
  });
}
