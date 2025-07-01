import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('API Documentation Examples', () {
    group('AckSchema class examples', () {
      test('validate method example', () {
        /// Example from validate() documentation
        final schema = Ack.string().email();

        // Valid input
        final result = schema.validate('user@example.com');
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals('user@example.com'));

        // Invalid input returns failure
        final invalidResult = schema.validate('not-an-email');
        expect(invalidResult.isFail, isTrue);
        expect(invalidResult.getError(), isA<SchemaError>());
      });

      test('parse method example', () {
        /// Example from parse() documentation
        final schema = Ack.string().email();

        // Valid input
        final email = schema.parse('user@example.com');
        expect(email, equals('user@example.com'));

        // Invalid input throws AckException
        expect(
          () => schema.parse('not-an-email'),
          throwsA(isA<AckException>()),
        );
      });

      test('tryParse method example', () {
        /// Example from tryParse() documentation
        final schema = Ack.integer().positive();

        final validResult = schema.tryParse(42);
        expect(validResult, equals(42));

        final invalidResult = schema.tryParse(-5);
        expect(invalidResult, isNull);
      });

      test('safeParse method example', () {
        /// Example from safeParse() documentation
        final schema = Ack.integer().positive();

        final validResult = schema.safeParse(42);
        expect(validResult.isOk, isTrue);
        expect(validResult.getOrThrow(), equals(42));

        final invalidResult = schema.safeParse(-5);
        expect(invalidResult.isFail, isTrue);
        expect(invalidResult.getError(), isA<SchemaError>());
      });

      test('nullable method example', () {
        /// Example from nullable() documentation
        final schema = Ack.string().nullable();

        expect(schema.parse('hello'), equals('hello'));
        expect(schema.parse(null), isNull);
      });
    });

    group('String schema examples', () {
      test('string constraint examples', () {
        // minLength example
        final minLengthSchema = Ack.string().minLength(3);
        expect(minLengthSchema.parse('hello'), equals('hello'));
        expect(
          () => minLengthSchema.parse('hi'),
          throwsA(isA<AckException>()),
        );

        // maxLength example
        final maxLengthSchema = Ack.string().maxLength(10);
        expect(maxLengthSchema.parse('short'), equals('short'));
        expect(
          () => maxLengthSchema.parse('this is too long'),
          throwsA(isA<AckException>()),
        );

        // length example
        final exactLengthSchema = Ack.string().length(5);
        expect(exactLengthSchema.parse('hello'), equals('hello'));
        expect(
          () => exactLengthSchema.parse('hi'),
          throwsA(isA<AckException>()),
        );
      });

      test('string format examples', () {
        // email example
        final emailSchema = Ack.string().email();
        expect(
            emailSchema.parse('user@example.com'), equals('user@example.com'));

        // Invalid email should throw
        expect(
          () => emailSchema.parse('invalid-email'),
          throwsA(isA<AckException>()),
        );
      });
    });

    group('Numeric schema examples', () {
      test('numeric constraint examples', () {
        // min/max example
        final rangeSchema = Ack.integer().min(1).max(100);
        expect(rangeSchema.parse(50), equals(50));
        expect(
          () => rangeSchema.parse(150),
          throwsA(isA<AckException>()),
        );

        // positive example
        final positiveSchema = Ack.integer().positive();
        expect(positiveSchema.parse(42), equals(42));
        expect(
          () => positiveSchema.parse(-5),
          throwsA(isA<AckException>()),
        );

        // double constraints
        final doubleSchema = Ack.double().positive();
        expect(doubleSchema.parse(3.14), equals(3.14));
        expect(
          () => doubleSchema.parse(-1.5),
          throwsA(isA<AckException>()),
        );
      });
    });

    group('Object schema examples', () {
      test('basic object schema example', () {
        final userSchema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().min(0),
        }, required: [
          'name'
        ]);

        final validUser = {
          'name': 'John Doe',
          'age': 30,
        };

        final result = userSchema.validate(validUser);
        expect(result.isOk, isTrue);

        final parsedData = result.getOrThrow()!;
        expect(parsedData['name'], equals('John Doe'));
        expect(parsedData['age'], equals(30));
      });

      test('nested object schema example', () {
        final addressSchema = Ack.object({
          'street': Ack.string(),
          'city': Ack.string(),
        });

        final userSchema = Ack.object({
          'name': Ack.string(),
          'address': addressSchema,
        });

        final validData = {
          'name': 'John Doe',
          'address': {
            'street': '123 Main St',
            'city': 'Anytown',
          },
        };

        final result = userSchema.validate(validData);
        expect(result.isOk, isTrue);

        final parsedData = result.getOrThrow()!;
        expect(parsedData['name'], equals('John Doe'));
        expect((parsedData['address'] as Map)['street'], equals('123 Main St'));
      });
    });

    group('List schema examples', () {
      test('basic list schema example', () {
        final tagsSchema = Ack.list(Ack.string());

        final result = tagsSchema.validate(['dart', 'flutter', 'validation']);
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals(['dart', 'flutter', 'validation']));
      });

      test('list with constraints example', () {
        final emailListSchema =
            Ack.list(Ack.string().email()).minItems(1).maxItems(5);

        final validEmails = ['user@example.com', 'admin@example.com'];
        final result = emailListSchema.validate(validEmails);
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals(validEmails));

        // Empty list should fail minItems constraint
        expect(
          () => emailListSchema.parse([]),
          throwsA(isA<AckException>()),
        );
      });
    });

    group('Enum schema examples', () {
      test('string enum example', () {
        final statusSchema = Ack.enumString(['active', 'inactive', 'pending']);

        expect(statusSchema.parse('active'), equals('active'));
        expect(statusSchema.parse('inactive'), equals('inactive'));

        expect(
          () => statusSchema.parse('unknown'),
          throwsA(isA<AckException>()),
        );
      });
    });

    group('Discriminated union examples', () {
      test('basic discriminated union example', () {
        final resultSchema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'success': Ack.object({
              'type': Ack.literal('success'),
              'data': Ack.string(),
            }),
            'error': Ack.object({
              'type': Ack.literal('error'),
              'message': Ack.string(),
              'code': Ack.string(),
            }),
          },
        );

        // Success case
        final successResult = resultSchema.validate({
          'type': 'success',
          'data': 'Operation completed',
        });
        expect(successResult.isOk, isTrue);

        // Error case
        final errorResult = resultSchema.validate({
          'type': 'error',
          'message': 'Not found',
          'code': 'NOT_FOUND',
        });
        expect(errorResult.isOk, isTrue);

        // Invalid discriminator should fail
        expect(
          () => resultSchema.parse({
            'type': 'unknown',
            'data': 'test',
          }),
          throwsA(isA<AckException>()),
        );
      });
    });

    group('Error handling examples', () {
      test('SchemaResult usage example', () {
        final schema = Ack.string().minLength(5);

        // Valid case
        final validResult = schema.validate('hello world');
        expect(validResult.isOk, isTrue);
        expect(validResult.isFail, isFalse);
        expect(validResult.getOrThrow(), equals('hello world'));
        expect(validResult.getOrNull(), equals('hello world'));
        expect(validResult.getOrElse(() => 'default'), equals('hello world'));

        // Invalid case
        final invalidResult = schema.validate('hi');
        expect(invalidResult.isOk, isFalse);
        expect(invalidResult.isFail, isTrue);
        expect(invalidResult.getOrNull(), isNull);
        expect(invalidResult.getOrElse(() => 'default'), equals('default'));
        expect(invalidResult.getError(), isA<SchemaError>());

        expect(
          () => invalidResult.getOrThrow(),
          throwsA(isA<AckException>()),
        );
      });
    });
  });
}
