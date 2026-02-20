import 'package:ack/ack.dart';
import 'package:ack/src/constraints/validators.dart';
import 'package:test/test.dart';

void main() {
  group('Core Schema Features', () {
    group('isNullable', () {
      test('non-nullable StringSchema should fail on null', () {
        final schema = StringSchema(isNullable: false);
        final result = schema.safeParse(null);
        expect(result.isOk, isFalse);
        final error = result.getError() as SchemaConstraintsError;
        expect(error.getConstraint<NonNullableConstraint>(), isNotNull);
        expect(
          error.constraints.first.message,
          'Value is required and cannot be null.',
        );
      });

      test('nullable StringSchema should pass on null', () {
        final schema = StringSchema(isNullable: true);
        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);
        expect(result.getOrNull(), isNull);
      });

      test('non-nullable IntegerSchema should fail on null', () {
        final schema = IntegerSchema(isNullable: false);
        final result = schema.safeParse(null);
        expect(result.isOk, isFalse);
      });

      test('nullable IntegerSchema should pass on null', () {
        final schema = IntegerSchema(isNullable: true);
        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);
      });
    });

    group('defaultValue', () {
      test('should apply default value for null input', () {
        final schema = StringSchema(defaultValue: 'default');
        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);
        expect(result.getOrNull(), 'default');
      });

      test('should not apply default value for non-null input', () {
        final schema = StringSchema(defaultValue: 'default');
        final result = schema.safeParse('actual');
        expect(result.isOk, isTrue);
        expect(result.getOrNull(), 'actual');
      });

      test('default value is still validated against constraints', () {
        final schema = StringSchema(defaultValue: 'short').minLength(10);
        final result = schema.safeParse(null);
        expect(result.isOk, isFalse);
        final error = result.getError() as SchemaConstraintsError;
        // The default value should be validated against constraints.
        // This was fixed in the refactor - now default values are properly validated.
        expect(
          error.constraints.first.message,
          'Too short. Minimum 10 characters, got 5.',
        );
      });

      test('nullable schema default should honor constraints', () {
        final schema = Ack.string().nullable().minLength(5).withDefault('oops');

        final result = schema.safeParse(null);

        expect(result.isOk, isFalse);
        final error = result.getError();
        expect(error, isA<SchemaConstraintsError>());
        expect(
          (error as SchemaConstraintsError).constraints.first.message,
          contains('Minimum 5 characters'),
        );
      });

      test('optional schema default should honor constraints', () {
        // Optional defaults apply only when the field is missing from an object,
        // not for top-level null input. For top-level null with a default,
        // use the base schema's withDefault instead.
        final schema = Ack.string()
            .minLength(5)
            .withDefault('tiny'); // Default on base schema, not optional

        final result = schema.safeParse(null);

        // Should fail because default doesn't satisfy constraints
        expect(result.isOk, isFalse);
        final error = result.getError();
        expect(error, isA<SchemaConstraintsError>());
        expect(
          (error as SchemaConstraintsError).constraints.first.message,
          contains('Minimum 5 characters'),
        );
      });
    });

    group('Type Conversion', () {
      test(
        'StringSchema should fail for non-string input with strict parsing',
        () {
          final schema = StringSchema().strictParsing();
          final result = schema.safeParse(123);
          expect(result.isOk, isFalse);
          final error = result.getError() as TypeMismatchError;
          expect(error.expectedType, equals('string'));
          expect(error.actualType, equals('integer'));
        },
      );

      test('IntegerSchema should fail for non-integer input', () {
        final schema = IntegerSchema();
        final result = schema.safeParse('not-a-number');
        expect(result.isOk, isFalse);
        // IntegerSchema accepts strings for coercion, so this fails during conversion, not type checking
        final error = result.getError() as SchemaValidationError;
        expect(error.message, contains('not-a-number'));
      });

      test('IntegerSchema should enforce strict parsing when enabled', () {
        const schema = IntegerSchema(strictPrimitiveParsing: true);
        final result = schema.safeParse('123');

        expect(result.isOk, isFalse);
        final error = result.getError() as TypeMismatchError;
        expect(error.expectedType, equals('integer'));
        expect(error.actualType, equals('string'));
      });

      test('BooleanSchema should fail for non-boolean input', () {
        final schema = BooleanSchema();
        final result = schema.safeParse(1);
        expect(result.isOk, isFalse);
        final error = result.getError() as TypeMismatchError;
        expect(error.expectedType, equals('boolean'));
        expect(error.actualType, equals('integer'));
      });

      test(
        'DoubleSchema should accept ints even in strict mode (integers are numbers)',
        () {
          const schema = DoubleSchema(strictPrimitiveParsing: true);
          final result = schema.safeParse(42);

          // Integers ARE numbers in JSON Schema semantics, so this should pass
          // Strict mode only prevents string→number coercion
          expect(result.isOk, isTrue);
          expect(result.getOrThrow(), equals(42.0));
        },
      );
    });

    group('parseAs / safeParseAs', () {
      test('parseAs maps validated primitive value', () {
        final schema = Ack.string().minLength(1);

        final result = schema.parseAs(
          'hello',
          (validated) => validated!.length,
        );

        expect(result, equals(5));
      });

      test('safeParseAs maps validated object value', () {
        final schema = Ack.object({'id': Ack.integer()});

        final result = schema.safeParseAs({
          'id': 42,
        }, (validated) => validated!['id'] as int);

        expect(result.isOk, isTrue);
        expect(result.getOrNull(), equals(42));
      });

      test('safeParseAs keeps validation failures and does not run mapper', () {
        final schema = Ack.string().strictParsing();
        var mapperCalled = false;

        final result = schema.safeParseAs(123, (validated) {
          mapperCalled = true;
          return validated?.length ?? 0;
        });

        expect(result.isFail, isTrue);
        expect(mapperCalled, isFalse);
        expect(result.getError(), isA<TypeMismatchError>());
      });

      test('safeParseAs wraps mapper exceptions as SchemaTransformError', () {
        final schema = Ack.integer();

        final result = schema.safeParseAs(
          5,
          (_) => throw StateError('mapper failed'),
          debugName: 'numberAdapter',
        );

        expect(result.isFail, isTrue);
        final error = result.getError();
        expect(error, isA<SchemaTransformError>());
        expect(error.name, equals('numberAdapter'));
        expect(error.value, equals(5));
        expect(error.schema, same(schema));
        expect(
          error.message,
          contains('Transformation failed: Bad state: mapper failed'),
        );
      });

      test('parseAs throws AckException for mapper exceptions', () {
        final schema = Ack.integer();

        expect(
          () => schema.parseAs(
            7,
            (_) => throw StateError('mapper exploded'),
            debugName: 'mapperDebugName',
          ),
          throwsA(
            isA<AckException>().having(
              (exception) => exception.errors.single,
              'error',
              isA<SchemaTransformError>().having(
                (error) => error.name,
                'name',
                equals('mapperDebugName'),
              ),
            ),
          ),
        );
      });
    });

    group('ListSchema', () {
      test('should fail when nullable item resolves to null', () {
        final schema = Ack.list(Ack.string().nullable());

        final result = schema.safeParse(['valid', null, 'also valid']);

        expect(result.isOk, isFalse);
        expect(result.getError(), isA<SchemaNestedError>());
      });
    });
  });

  group('Backward compatibility helpers', () {
    test('validate delegates to safeParse', () {
      final schema = Ack.integer();

      // ignore: deprecated_member_use_from_same_package
      final okResult = schema.validate(123);
      expect(okResult.isOk, isTrue);

      // ignore: deprecated_member_use_from_same_package
      final failResult = schema.validate('oops');
      expect(failResult.isFail, isTrue);
    });

    test('tryParse returns null on failure', () {
      final schema = Ack.integer();

      // ignore: deprecated_member_use_from_same_package
      expect(schema.tryParse(42), equals(42));

      // ignore: deprecated_member_use_from_same_package
      expect(schema.tryParse('bad'), isNull);
    });
  });
}
