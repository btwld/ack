import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Optional/Nullable Semantics', () {
    group('Optional implies nullable', () {
      test('optional() should make field nullable by default', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().optional(),
        });

        // Test 1: Missing field should pass
        final missingField = {'name': 'John'};
        final result1 = schema.validate(missingField);
        expect(result1.isOk, isTrue, reason: 'Optional field can be missing');

        // Test 2: Present with value should pass
        final withValue = {'name': 'John', 'age': 30};
        final result2 = schema.validate(withValue);
        expect(result2.isOk, isTrue, reason: 'Optional field can have value');

        // Test 3: Present with null should pass (THIS IS THE KEY TEST)
        final withNull = {'name': 'John', 'age': null};
        final result3 = schema.validate(withNull);
        expect(result3.isOk, isTrue,
            reason: 'Optional field should accept null when present');
      });

      test('optional() schema should report isNullable as true', () {
        final schema = Ack.string().optional();
        expect(schema.isNullable, isTrue,
            reason: 'OptionalSchema should always be nullable');
      });
    });

    group('Default values with optional', () {
      test('optional field with default should apply default for null', () {
        final schema =
            Ack.string().minLength(5).optional().withDefault('default');

        // When validating null, should apply default
        final result = schema.validate(null);
        expect(result.isOk, isTrue,
            reason: 'Should apply default value for null');
        expect(result.getOrNull(), equals('default'),
            reason: 'Should return default value');
      });

      test('optional field default must satisfy constraints', () {
        final schema = Ack.string()
            .minLength(5)
            .optional()
            .withDefault('tiny'); // Too short!

        final result = schema.validate(null);
        expect(result.isFail, isTrue,
            reason: 'Default value should be validated against constraints');

        if (result.isFail) {
          final error = result.getError();
          expect(error.toString(), contains('Minimum 5 characters'),
              reason: 'Should show constraint violation for default value');
        }
      });

      test('nullable field with default should apply default for null', () {
        final schema =
            Ack.string().nullable().minLength(5).withDefault('default');

        final result = schema.validate(null);
        expect(result.isOk, isTrue,
            reason: 'Should apply default value even for nullable schema');
        expect(result.getOrNull(), equals('default'),
            reason: 'Should return default value, not null');
      });
    });

    group('ObjectSchema field validation', () {
      test('should correctly identify optional vs required fields', () {
        final schema = Ack.object({
          'required': Ack.string(),
          'optional': Ack.string().optional(),
        });

        // Missing required field should fail
        final missingRequired = {'optional': 'value'};
        final result1 = schema.validate(missingRequired);
        expect(result1.isFail, isTrue,
            reason: 'Should fail when required field is missing');

        // Missing optional field should pass
        final missingOptional = {'required': 'value'};
        final result2 = schema.validate(missingOptional);
        expect(result2.isOk, isTrue,
            reason: 'Should pass when optional field is missing');
      });
    });

    group('Edge cases', () {
      test('optional().nullable() should be redundant but valid', () {
        final schema = Ack.string().optional().nullable();

        expect(schema.isNullable, isTrue);

        final result = schema.validate(null);
        expect(result.isOk, isTrue,
            reason: 'Double nullable should still work');
      });

      test('transform should work with optional nullable', () {
        final schema = Ack.string()
            .optional()
            .transform((value) => value?.toUpperCase() ?? 'DEFAULT');

        final result1 = schema.validate(null);
        expect(result1.isOk, isTrue);
        expect(result1.getOrNull(), equals('DEFAULT'));

        final result2 = schema.validate('hello');
        expect(result2.isOk, isTrue);
        expect(result2.getOrNull(), equals('HELLO'));
      });
    });
  });

  group('Email validation', () {
    test('should reject incomplete domain names', () {
      final schema = Ack.string().email();

      final testCases = [
        ('user@example', false, 'Missing TLD'),
        ('user@example.com', true, 'Valid email'),
        ('user@sub.example.com', true, 'Valid with subdomain'),
        ('user@.com', false, 'Missing domain'),
        ('user@', false, 'Missing domain and TLD'),
        ('@example.com', false, 'Missing local part'),
      ];

      for (final (email, shouldPass, reason) in testCases) {
        final result = schema.validate(email);
        expect(result.isOk, equals(shouldPass), reason: '$reason: $email');
      }
    });
  });

  group('Error types', () {
    test('should return SchemaNestedError for object validation', () {
      final schema = Ack.object({
        'password': Ack.string().minLength(8),
      });

      final result = schema.validate({
        'password': 'short',
      });

      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaNestedError>(),
          reason: 'Object validation should return SchemaNestedError');
    });

    test('should return SchemaConstraintsError for direct constraint violation',
        () {
      final schema = Ack.string().minLength(5);

      final result = schema.validate('hi');

      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaConstraintsError>(),
          reason:
              'Direct constraint violation should return SchemaConstraintsError');
    });
  });
}
