import 'package:ack/src/validation/error_messages.dart';
import 'package:test/test.dart';

void main() {
  group('ErrorMessages', () {
    group('Type Errors', () {
      test('should format expected type messages correctly', () {
        expect(
          ErrorMessages.expectedType('string', 'number'),
          equals('Expected string but got number'),
        );
        expect(
          ErrorMessages.expectedType('object', 'array'),
          equals('Expected object but got array'),
        );
      });

      test('should provide standard required value messages', () {
        expect(ErrorMessages.requiredValue, equals('Value is required'));
        expect(ErrorMessages.cannotBeNull, equals('Value cannot be null'));
      });
    });

    group('String Errors', () {
      test('should format length constraint messages correctly', () {
        expect(
          ErrorMessages.minLength(1),
          equals('String must be at least 1 character'),
        );
        expect(
          ErrorMessages.minLength(5),
          equals('String must be at least 5 characters'),
        );
        expect(
          ErrorMessages.maxLength(1),
          equals('String must be at most 1 character'),
        );
        expect(
          ErrorMessages.maxLength(10),
          equals('String must be at most 10 characters'),
        );
        expect(
          ErrorMessages.exactLength(1),
          equals('String must be exactly 1 character'),
        );
        expect(
          ErrorMessages.exactLength(8),
          equals('String must be exactly 8 characters'),
        );
      });

      test('should provide format validation messages', () {
        expect(ErrorMessages.invalidEmail, equals('Invalid email format'));
        expect(ErrorMessages.invalidUrl, equals('Invalid URL format'));
        expect(ErrorMessages.invalidUuid, equals('Invalid UUID format'));
        expect(ErrorMessages.invalidDatetime, equals('Invalid datetime format'));
        expect(ErrorMessages.invalidIp, equals('Invalid IP address format'));
      });

      test('should format pattern messages correctly', () {
        expect(
          ErrorMessages.pattern(r'^\d+$'),
          equals(r'String does not match pattern: ^\d+$'),
        );
      });
    });

    group('Number Errors', () {
      test('should format range constraint messages correctly', () {
        expect(ErrorMessages.min(0), equals('Number must be at least 0'));
        expect(ErrorMessages.min(18), equals('Number must be at least 18'));
        expect(ErrorMessages.max(100), equals('Number must be at most 100'));
        expect(ErrorMessages.max(1), equals('Number must be at most 1'));
        
        expect(
          ErrorMessages.greaterThan(0),
          equals('Number must be greater than 0'),
        );
        expect(
          ErrorMessages.lessThan(100),
          equals('Number must be less than 100'),
        );
      });

      test('should provide sign validation messages', () {
        expect(ErrorMessages.mustBePositive, equals('Number must be positive'));
        expect(ErrorMessages.mustBeNegative, equals('Number must be negative'));
        expect(ErrorMessages.mustBeFinite, equals('Number must be finite'));
        expect(ErrorMessages.mustBeInteger, equals('Number must be an integer'));
      });

      test('should format multiple constraint messages correctly', () {
        expect(
          ErrorMessages.multipleOf(5),
          equals('Number must be a multiple of 5'),
        );
        expect(
          ErrorMessages.multipleOf(0.5),
          equals('Number must be a multiple of 0.5'),
        );
      });
    });

    group('Object Errors', () {
      test('should format property validation messages correctly', () {
        expect(
          ErrorMessages.missingProperty('name'),
          equals('Required property "name" is missing'),
        );
        expect(
          ErrorMessages.additionalProperty('extra'),
          equals('Additional property "extra" is not allowed'),
        );
        expect(
          ErrorMessages.additionalPropertiesNotAllowed,
          equals('Additional properties are not allowed'),
        );
      });
    });

    group('Array Errors', () {
      test('should format item constraint messages correctly', () {
        expect(
          ErrorMessages.minItems(1),
          equals('Array must have at least 1 item'),
        );
        expect(
          ErrorMessages.minItems(3),
          equals('Array must have at least 3 items'),
        );
        expect(
          ErrorMessages.maxItems(1),
          equals('Array must have at most 1 item'),
        );
        expect(
          ErrorMessages.maxItems(5),
          equals('Array must have at most 5 items'),
        );
        expect(
          ErrorMessages.uniqueItems,
          equals('Array must contain unique items'),
        );
      });
    });

    group('Discriminated Union Errors', () {
      test('should format discriminator messages correctly', () {
        expect(
          ErrorMessages.missingDiscriminator('type'),
          equals('Missing discriminator field "type"'),
        );
        expect(
          ErrorMessages.invalidDiscriminator('unknown', ['a', 'b', 'c']),
          equals('Invalid discriminator value "unknown". Expected one of: a, b, c'),
        );
      });
    });

    group('Enum Errors', () {
      test('should format enum validation messages correctly', () {
        expect(
          ErrorMessages.invalidEnumValue('yellow', ['red', 'green', 'blue']),
          equals('Invalid value "yellow". Must be one of: red, green, blue'),
        );
      });
    });

    group('Complex Validation Errors', () {
      test('should provide nested validation messages', () {
        expect(
          ErrorMessages.nestedValidationFailed,
          equals('One or more nested schemas failed validation'),
        );
        expect(
          ErrorMessages.multipleErrors(3),
          equals('Multiple validation errors occurred (3 errors)'),
        );
      });

      test('should format literal mismatch messages correctly', () {
        expect(
          ErrorMessages.literalMismatch('success', 'error'),
          equals('Expected literal value "success" but got "error"'),
        );
      });

      test('should provide union and intersection messages', () {
        expect(
          ErrorMessages.noUnionMatch,
          equals('Value does not match any of the union types'),
        );
        expect(
          ErrorMessages.intersectionFailed,
          equals('Value does not satisfy all intersection requirements'),
        );
      });
    });

    group('Utility Methods', () {
      test('should format field paths correctly', () {
        expect(ErrorMessages.formatFieldPath([]), equals('root'));
        expect(ErrorMessages.formatFieldPath(['user']), equals('user'));
        expect(
          ErrorMessages.formatFieldPath(['user', 'profile', 'name']),
          equals('user.profile.name'),
        );
      });

      test('should format errors with paths correctly', () {
        expect(
          ErrorMessages.formatErrorWithPath('Invalid email', ['user', 'email']),
          equals('At user.email: Invalid email'),
        );
        expect(
          ErrorMessages.formatErrorWithPath('Required field', []),
          equals('At root: Required field'),
        );
      });

      test('should format multiple errors correctly', () {
        expect(ErrorMessages.formatMultipleErrors([]), equals('No errors'));
        expect(
          ErrorMessages.formatMultipleErrors(['Single error']),
          equals('Single error'),
        );
        expect(
          ErrorMessages.formatMultipleErrors(['Error 1', 'Error 2', 'Error 3']),
          equals('Multiple validation errors:\n1. Error 1\n2. Error 2\n3. Error 3'),
        );
      });

      test('should get user-friendly type names', () {
        expect(ErrorMessages.getTypeName(String), equals('string'));
        expect(ErrorMessages.getTypeName(int), equals('integer'));
        expect(ErrorMessages.getTypeName(double), equals('number'));
        expect(ErrorMessages.getTypeName(bool), equals('boolean'));
      });
    });

    group('Parameter Validation', () {
      test('should validate message parameters correctly', () {
        // Valid parameters should not throw
        expect(
          () => ErrorMessages.validateMessageParameters(
            min: 0,
            max: 10,
            pattern: r'^\d+$',
            enumValues: ['a', 'b'],
          ),
          returnsNormally,
        );

        // Invalid parameters should throw
        expect(
          () => ErrorMessages.validateMessageParameters(min: -1),
          throwsArgumentError,
        );
        expect(
          () => ErrorMessages.validateMessageParameters(max: -1),
          throwsArgumentError,
        );
        expect(
          () => ErrorMessages.validateMessageParameters(min: 10, max: 5),
          throwsArgumentError,
        );
        expect(
          () => ErrorMessages.validateMessageParameters(pattern: ''),
          throwsArgumentError,
        );
        expect(
          () => ErrorMessages.validateMessageParameters(enumValues: []),
          throwsArgumentError,
        );
      });
    });

    group('Security and Business Logic Errors', () {
      test('should provide password validation messages', () {
        expect(
          ErrorMessages.weakPassword,
          equals('Password does not meet security requirements'),
        );
        expect(
          ErrorMessages.passwordTooShort(8),
          equals('Password must be at least 8 characters long'),
        );
        expect(
          ErrorMessages.passwordMissingUppercase,
          equals('Password must contain at least one uppercase letter'),
        );
      });

      test('should provide business logic validation messages', () {
        expect(
          ErrorMessages.duplicateValue,
          equals('Duplicate value not allowed'),
        );
        expect(
          ErrorMessages.valueAlreadyExists,
          equals('Value already exists'),
        );
        expect(
          ErrorMessages.circularReference,
          equals('Circular reference detected'),
        );
      });
    });
  });
}
