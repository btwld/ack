import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('README Examples', () {
    group('Core Library Examples', () {
      test('basic user schema example should work', () {
        // Example from README - corrected API
        final userSchema = Ack.object({
          'name': Ack.string().minLength(2).maxLength(50),
          'email': Ack.string().email(),
          'age': Ack.integer().min(0).max(120).optional().nullable(),
        });

        // Valid data test
        final validData = {
          'name': 'John Doe',
          'email': 'john@example.com',
          'age': 30
        };

        final result = userSchema.validate(validData);
        expect(result.isOk, isTrue);

        final parsedData = result.getOrThrow()!;
        expect(parsedData['name'], equals('John Doe'));
        expect(parsedData['email'], equals('john@example.com'));
        expect(parsedData['age'], equals(30));
      });

      test('validation with missing optional field should work', () {
        final userSchema = Ack.object({
          'name': Ack.string().minLength(2).maxLength(50),
          'email': Ack.string().email(),
          'age': Ack.integer().min(0).max(120).optional().nullable(),
        });

        // Valid data without age
        final validDataNoAge = {
          'name': 'Jane Doe',
          'email': 'jane@example.com',
        };

        final result = userSchema.validate(validDataNoAge);
        expect(result.isOk, isTrue);

        final parsedData = result.getOrThrow()!;
        expect(parsedData['name'], equals('Jane Doe'));
        expect(parsedData['email'], equals('jane@example.com'));
        expect(parsedData.containsKey('age'), isFalse);
      });

      test('validation failure should provide error details', () {
        final userSchema = Ack.object({
          'name': Ack.string().minLength(2).maxLength(50),
          'email': Ack.string().email(),
          'age': Ack.integer().min(0).max(120).optional().nullable(),
        });

        // Invalid data - name too short
        final invalidData = {
          'name': 'J', // Too short
          'email': 'john@example.com',
          'age': 30
        };

        final result = userSchema.validate(invalidData);
        expect(result.isFail, isTrue);

        final error = result.getError();
        // For nested validation errors, the message is generic
        expect(
            error.message,
            anyOf([
              contains('nested'),
              contains('validation'),
              contains('failed'),
            ]));
      });

      test('validation failure with missing required field', () {
        final userSchema = Ack.object({
          'name': Ack.string().minLength(2).maxLength(50),
          'email': Ack.string().email(),
          'age': Ack.integer().min(0).max(120).optional().nullable(),
        });

        // Invalid data - missing required field
        final invalidData = {
          'name': 'John Doe',
          // Missing email
          'age': 30
        };

        final result = userSchema.validate(invalidData);
        expect(result.isFail, isTrue);

        final error = result.getError();
        // For nested validation errors, the message is generic
        expect(
            error.message,
            anyOf([
              contains('nested'),
              contains('validation'),
              contains('failed'),
            ]));
      });

      test('parse method should work as documented', () {
        final userSchema = Ack.object({
          'name': Ack.string().minLength(2).maxLength(50),
          'email': Ack.string().email(),
          'age': Ack.integer().min(0).max(120).optional().nullable(),
        });

        final validData = {
          'name': 'John Doe',
          'email': 'john@example.com',
          'age': 30
        };

        // Using parse method (throws on failure)
        final parsedData = userSchema.parse(validData);
        expect(parsedData, isNotNull);
        expect(parsedData!['name'], equals('John Doe'));
        expect(parsedData['email'], equals('john@example.com'));
        expect(parsedData['age'], equals(30));
      });

      test('parse method should throw on invalid data', () {
        final userSchema = Ack.object({
          'name': Ack.string().minLength(2).maxLength(50),
          'email': Ack.string().email(),
          'age': Ack.integer().min(0).max(120).optional().nullable(),
        });

        final invalidData = {
          'name': 'J', // Too short
          'email': 'invalid-email',
          'age': 30
        };

        // Should throw AckException
        expect(
          () => userSchema.parse(invalidData),
          throwsA(isA<AckException>()),
        );
      });
    });

    group('Schema Types Examples', () {
      test('string schema examples', () {
        // Basic string
        final nameSchema = Ack.string();
        final nameResult = nameSchema.validate('Hello');
        expect(nameResult.isOk, isTrue);
        expect(nameResult.getOrThrow(), equals('Hello'));

        // String with constraints
        final usernameSchema = Ack.string().minLength(3).maxLength(20);

        final usernameResult = usernameSchema.validate('john_doe');
        expect(usernameResult.isOk, isTrue);
        expect(usernameResult.getOrThrow(), equals('john_doe'));

        // Too short username should fail
        final shortResult = usernameSchema.validate('jo');
        expect(shortResult.isFail, isTrue);
      });

      test('string format validations', () {
        // Email validation
        final emailSchema = Ack.string().email();
        final emailResult = emailSchema.validate('test@example.com');
        expect(emailResult.isOk, isTrue);
        expect(emailResult.getOrThrow(), equals('test@example.com'));

        // Invalid email should fail
        final invalidEmailResult = emailSchema.validate('invalid-email');
        expect(invalidEmailResult.isFail, isTrue);
      });

      test('numeric schema examples', () {
        // Integer validation
        final ageSchema = Ack.integer().min(0).max(150);
        final ageResult = ageSchema.validate(25);
        expect(ageResult.isOk, isTrue);
        expect(ageResult.getOrThrow(), equals(25));

        // Double validation
        final priceSchema = Ack.double().positive();
        final priceResult = priceSchema.validate(19.99);
        expect(priceResult.isOk, isTrue);
        expect(priceResult.getOrThrow(), equals(19.99));
      });

      test('boolean schema examples', () {
        final boolSchema = Ack.boolean();

        final trueResult = boolSchema.validate(true);
        expect(trueResult.isOk, isTrue);
        expect(trueResult.getOrThrow(), equals(true));

        final falseResult = boolSchema.validate(false);
        expect(falseResult.isOk, isTrue);
        expect(falseResult.getOrThrow(), equals(false));
      });

      test('list schema examples', () {
        // Basic list
        final tagsSchema = Ack.list(Ack.string());
        final tagsResult =
            tagsSchema.validate(['dart', 'flutter', 'validation']);
        expect(tagsResult.isOk, isTrue);
        expect(
            tagsResult.getOrThrow(), equals(['dart', 'flutter', 'validation']));

        // List with constraints
        final emailListSchema =
            Ack.list(Ack.string().email()).minItems(1).maxItems(5);

        final emailListResult =
            emailListSchema.validate(['user@example.com', 'admin@example.com']);
        expect(emailListResult.isOk, isTrue);
        expect(emailListResult.getOrThrow(),
            equals(['user@example.com', 'admin@example.com']));
      });
    });

    group('Advanced Features Examples', () {
      test('nullable schema examples', () {
        final nullableStringSchema = Ack.string().nullable();

        // Valid string
        final stringResult = nullableStringSchema.validate('hello');
        expect(stringResult.isOk, isTrue);
        expect(stringResult.getOrThrow(), equals('hello'));

        // Valid null
        final nullResult = nullableStringSchema.validate(null);
        expect(nullResult.isOk, isTrue);
        expect(nullResult.getOrThrow(), isNull);
      });

      test('enum schema examples', () {
        // String enum
        final statusSchema = Ack.enumString(['active', 'inactive', 'pending']);

        final validResult = statusSchema.validate('active');
        expect(validResult.isOk, isTrue);
        expect(validResult.getOrThrow(), equals('active'));

        final invalidResult = statusSchema.validate('unknown');
        expect(invalidResult.isFail, isTrue);
      });

      test('discriminated union examples', () {
        final resultSchema = Ack.discriminated(
          discriminatorKey: 'status',
          schemas: {
            'success': Ack.object({
              'status': Ack.literal('success'),
              'data': Ack.string(),
            }),
            'error': Ack.object({
              'status': Ack.literal('error'),
              'message': Ack.string(),
              'code': Ack.string(),
            }),
          },
        );

        // Success case
        final successResult = resultSchema.validate({
          'status': 'success',
          'data': 'Operation completed',
        });
        expect(successResult.isOk, isTrue);

        // Error case
        final errorResult = resultSchema.validate({
          'status': 'error',
          'message': 'Not found',
          'code': 'NOT_FOUND',
        });
        expect(errorResult.isOk, isTrue);
      });
    });
  });
}
