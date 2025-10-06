import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Optional/Nullable Semantics', () {
    group('Optional does NOT imply nullable', () {
      test('optional() allows missing fields but not null values', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().optional(),
        });

        // Test 1: Missing field should pass
        final missingField = {'name': 'John'};
        final result1 = schema.safeParse(missingField);
        expect(result1.isOk, isTrue, reason: 'Optional field can be missing');

        // Test 2: Present with value should pass
        final withValue = {'name': 'John', 'age': 30};
        final result2 = schema.safeParse(withValue);
        expect(result2.isOk, isTrue, reason: 'Optional field can have value');

        // Test 3: Present with null should FAIL (CORRECTED BEHAVIOR)
        final withNull = {'name': 'John', 'age': null};
        final result3 = schema.safeParse(withNull);
        expect(
          result3.isFail,
          isTrue,
          reason:
              'Optional field should reject null unless also marked nullable',
        );
      });

      test(
        'optional() schema should report isOptional true and isNullable false',
        () {
          final schema = Ack.string().optional();
          expect(
            schema.isOptional,
            isTrue,
            reason: 'optional() should mark the schema as optional',
          );
          expect(
            schema.isNullable,
            isFalse,
            reason: 'optional() should not imply nullable semantics',
          );
        },
      );

      test('optional(false) should reset optional flag', () {
        final schema = Ack.string().optional(value: false);
        expect(
          schema.isOptional,
          isFalse,
          reason: 'optional(value: false) should clear the optional flag',
        );
      });
    });

    group('Default values with optional', () {
      test(
        'optional field with default should apply default for missing field',
        () {
          final schema = Ack.object({
            'name': Ack.string(),
            'age': Ack.integer().optional().withDefault(40),
          });

          final result = schema.safeParse({'name': 'John'});
          expect(result.isOk, isTrue);
          final map = result.getOrNull();
          expect(map?['age'], equals(40));
        },
      );

      test('optional field default must satisfy constraints', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().min(10).optional().withDefault(5),
        });

        final result = schema.safeParse({'name': 'John'});
        expect(result.isFail, isTrue);
        expect(result.getError(), isA<SchemaNestedError>());
      });

      test('nullable field with default should apply default for null', () {
        final schema = Ack.string()
            .nullable()
            .minLength(5)
            .withDefault('default');

        final result = schema.safeParse(null);
        expect(
          result.isOk,
          isTrue,
          reason: 'Should apply default value even for nullable schema',
        );
        expect(
          result.getOrNull(),
          equals('default'),
          reason: 'Should return default value, not null',
        );
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
        final result1 = schema.safeParse(missingRequired);
        expect(
          result1.isFail,
          isTrue,
          reason: 'Should fail when required field is missing',
        );

        // Missing optional field should pass
        final missingOptional = {'required': 'value'};
        final result2 = schema.safeParse(missingOptional);
        expect(
          result2.isOk,
          isTrue,
          reason: 'Should pass when optional field is missing',
        );
      });
    });

    group('Edge cases', () {
      test('optional().nullable() should accept both missing and null', () {
        final objectSchema = Ack.object({
          'name': Ack.string(),
          'nickname': Ack.string().optional().nullable(),
        });

        final nicknameSchema = Ack.string().optional().nullable();
        expect(
          nicknameSchema.isNullable,
          isTrue,
          reason: 'Calling nullable() after optional() should make it nullable',
        );

        // Test 1: Missing field
        final result1 = objectSchema.safeParse({'name': 'John'});
        expect(result1.isOk, isTrue, reason: 'Optional field can be missing');

        // Test 2: Explicit null value
        final result2 = objectSchema.safeParse({
          'name': 'John',
          'nickname': null,
        });
        expect(
          result2.isOk,
          isTrue,
          reason: 'Nullable optional field should accept null',
        );

        // Test 3: Actual value
        final result3 = objectSchema.safeParse({
          'name': 'John',
          'nickname': 'Johnny',
        });
        expect(result3.isOk, isTrue);
      });

      test('transform should work with optional nullable', () {
        // The key issue being tested: transform must preserve isOptional and isNullable flags
        // so that ObjectSchema correctly recognizes the field as optional/nullable
        final transformedSchema = Ack.string().optional().nullable().transform(
          (val) => val ?? 'anonymous',
        );

        // Verify flags are preserved
        expect(
          transformedSchema.isOptional,
          isTrue,
          reason: 'Transform must preserve isOptional flag',
        );
        expect(
          transformedSchema.isNullable,
          isTrue,
          reason: 'Transform must preserve isNullable flag',
        );

        final objectSchema = Ack.object({
          'name': Ack.string(),
          'nickname': transformedSchema,
        });

        // Test 1: Missing field (optional) - field should not be present in result
        final result1 = objectSchema.safeParse({'name': 'John'});
        expect(
          result1.isOk,
          isTrue,
          reason: 'Optional field should allow missing value',
        );
        expect(
          result1.getOrThrow()?['nickname'],
          isNull,
          reason: 'Missing optional field should be null/absent in result',
        );

        // Test 2: Explicit null value (nullable) - transform should be called
        final result2 = objectSchema.safeParse({
          'name': 'John',
          'nickname': null,
        });
        expect(
          result2.isOk,
          isTrue,
          reason: 'Nullable field should accept null',
        );
        expect(
          result2.getOrThrow()?['nickname'],
          'anonymous',
          reason: 'Transform should convert null to default value',
        );

        // Test 3: Actual value - transform should pass through
        final result3 = objectSchema.safeParse({
          'name': 'John',
          'nickname': 'Johnny',
        });
        expect(result3.isOk, isTrue);
        expect(
          result3.getOrThrow()?['nickname'],
          'Johnny',
          reason: 'Transform should pass through non-null values',
        );
      });
    });

    group('JSON Schema output', () {
      test('optional field should NOT automatically emit nullable type', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().optional(),
        });

        final jsonSchema = schema.toJsonSchema();
        final properties = jsonSchema['properties'] as Map<String, Object?>;
        final ageSchema = properties['age'] as Map<String, Object?>;

        // The age field should NOT include null - optional ≠ nullable
        final ageType = ageSchema['type'];
        expect(
          ageType,
          equals('integer'),
          reason:
              'Optional field should NOT include "null" unless also marked nullable',
        );

        // But it should NOT be in the required array
        final required = jsonSchema['required'] as List?;
        expect(
          required,
          isNot(contains('age')),
          reason: 'Optional field should not be in required array',
        );
      });

      test('optional string field should NOT emit nullable type', () {
        final optionalString = Ack.string().optional();
        final jsonSchema = optionalString.toJsonSchema();

        expect(
          jsonSchema['type'],
          equals('string'),
          reason:
              'Optional schema should NOT include null type unless also nullable',
        );
      });

      test('optional with constraints should NOT emit nullable type', () {
        final schema = Ack.string().minLength(5).optional();
        final jsonSchema = schema.toJsonSchema();

        expect(
          jsonSchema['type'],
          equals('string'),
          reason: 'Optional with constraints should NOT include null type',
        );
        expect(
          jsonSchema['minLength'],
          equals(5),
          reason: 'Constraints should be preserved',
        );
      });

      test(
        'nullable().optional() should emit nullable type in JSON Schema',
        () {
          final schema = Ack.object({
            'name': Ack.string(),
            'nickname': Ack.string().nullable().optional(),
          });

          final jsonSchema = schema.toJsonSchema();
          final properties = jsonSchema['properties'] as Map<String, Object?>;
          final nicknameSchema = properties['nickname'] as Map<String, Object?>;

          // Nullable fields use anyOf pattern with null type
          expect(
            nicknameSchema.containsKey('anyOf'),
            isTrue,
            reason: 'Nullable optional field should use anyOf pattern',
          );
          final anyOfList = nicknameSchema['anyOf'] as List;
          expect(anyOfList.length, equals(2));
          final types = anyOfList.map((s) => (s as Map)['type']).toSet();
          expect(
            types,
            containsAll(['string', 'null']),
            reason: 'Nullable optional field should include "null" in anyOf',
          );

          // And it should NOT be in the required array
          final required = jsonSchema['required'] as List?;
          expect(
            required,
            isNot(contains('nickname')),
            reason: 'Optional field should not be in required array',
          );
        },
      );
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
        final result = schema.safeParse(email);
        expect(result.isOk, equals(shouldPass), reason: '$reason: $email');
      }
    });
  });

  group('Error types', () {
    test('should return SchemaNestedError for object validation', () {
      final schema = Ack.object({'password': Ack.string().minLength(8)});

      final result = schema.safeParse({'password': 'short'});

      expect(result.isFail, isTrue);
      expect(
        result.getError(),
        isA<SchemaNestedError>(),
        reason: 'Object validation should return SchemaNestedError',
      );
    });

    test(
      'should return SchemaConstraintsError for direct constraint violation',
      () {
        final schema = Ack.string().minLength(5);

        final result = schema.safeParse('hi');

        expect(result.isFail, isTrue);
        expect(
          result.getError(),
          isA<SchemaConstraintsError>(),
          reason:
              'Direct constraint violation should return SchemaConstraintsError',
        );
      },
    );
  });
}
