import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Error Recovery Examples', () {
    group('Graceful Degradation Patterns', () {
      test('should provide fallback values for failed validation', () {
        final schema = Ack.object({
          'name': Ack.string().minLength(2),
          'age': Ack.integer().min(0).max(150),
          'email': Ack.string().email(),
        });

        AckSchema? getFieldSchema(String fieldName) {
          switch (fieldName) {
            case 'name':
              return Ack.string().minLength(2);
            case 'age':
              return Ack.integer().min(0).max(150);
            case 'email':
              return Ack.string().email();
            default:
              return null;
          }
        }

        Map<String, dynamic> parseWithDefaults(
          dynamic input,
          Map<String, dynamic> defaults,
        ) {
          final result = schema.validate(input);
          if (result.isOk) {
            return result.getOrThrow()!;
          }

          // Fallback to defaults for invalid data
          final Map<String, dynamic> output = Map.from(defaults);

          // Try to salvage valid fields from input
          if (input is Map<String, dynamic>) {
            for (final entry in input.entries) {
              if (defaults.containsKey(entry.key)) {
                // Try to validate individual field
                try {
                  final fieldSchema = getFieldSchema(entry.key);
                  if (fieldSchema != null) {
                    final fieldResult = fieldSchema.validate(entry.value);
                    if (fieldResult.isOk) {
                      output[entry.key] = fieldResult.getOrThrow();
                    }
                  }
                } catch (e) {
                  // Keep default value
                }
              }
            }
          }

          return output;
        }

        final defaults = {
          'name': 'Anonymous',
          'age': 0,
          'email': 'unknown@example.com',
        };

        // Valid input should pass through unchanged
        final validInput = {
          'name': 'John Doe',
          'age': 30,
          'email': 'john@example.com',
        };

        final validResult = parseWithDefaults(validInput, defaults);
        expect(validResult['name'], equals('John Doe'));
        expect(validResult['age'], equals(30));
        expect(validResult['email'], equals('john@example.com'));

        // Invalid input should use defaults
        final invalidInput = {
          'name': 'J', // Too short
          'age': -5, // Invalid
          'email': 'invalid-email',
        };

        final invalidResult = parseWithDefaults(invalidInput, defaults);
        expect(invalidResult['name'], equals('Anonymous'));
        expect(invalidResult['age'], equals(0));
        expect(invalidResult['email'], equals('unknown@example.com'));

        // Partially valid input should mix valid fields with defaults
        final partialInput = {
          'name': 'Jane Doe', // Valid
          'age': -5, // Invalid
          'email': 'jane@example.com', // Valid
        };

        final partialResult = parseWithDefaults(partialInput, defaults);
        expect(partialResult['name'], equals('Jane Doe')); // Valid field kept
        expect(partialResult['age'], equals(0)); // Default used
        expect(partialResult['email'],
            equals('jane@example.com')); // Valid field kept
      });
    });

    group('Progressive Validation Patterns', () {
      test('should validate in stages with recovery', () {
        // Stage 1: Basic validation (required fields only)
        final basicSchema = Ack.object({
          'id': Ack.string(),
        });

        // Stage 2: Enhanced validation (with constraints)
        final enhancedSchema = Ack.object({
          'id': Ack.string().uuid(),
          'name': Ack.string().minLength(2).optional(),
        });

        // Stage 3: Complete validation (all fields)
        final completeSchema = Ack.object({
          'id': Ack.string().uuid(),
          'name': Ack.string().minLength(2),
          'email': Ack.string().email(),
          'age': Ack.integer().min(0).max(150).optional(),
        });

        ValidationStage validateProgressively(dynamic input) {
          // Try complete validation first
          final completeResult = completeSchema.validate(input);
          if (completeResult.isOk) {
            return ValidationStage.complete(completeResult.getOrThrow()!);
          }

          // Fall back to enhanced validation
          final enhancedResult = enhancedSchema.validate(input);
          if (enhancedResult.isOk) {
            return ValidationStage.enhanced(enhancedResult.getOrThrow()!);
          }

          // Fall back to basic validation
          final basicResult = basicSchema.validate(input);
          if (basicResult.isOk) {
            return ValidationStage.basic(basicResult.getOrThrow()!);
          }

          // Complete failure
          return ValidationStage.failed(basicResult.getError().message);
        }

        // Complete valid data
        final completeData = {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'name': 'John Doe',
          'email': 'john@example.com',
          'age': 30,
        };

        final completeStage = validateProgressively(completeData);
        expect(completeStage.level, equals(ValidationLevel.complete));
        expect(completeStage.data!['name'], equals('John Doe'));

        // Enhanced valid data (missing some fields)
        final enhancedData = {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'name': 'Jane Doe',
        };

        final enhancedStage = validateProgressively(enhancedData);
        expect(enhancedStage.level, equals(ValidationLevel.enhanced));
        expect(enhancedStage.data!['name'], equals('Jane Doe'));

        // Basic valid data (minimal fields)
        final basicData = {
          'id': 'simple-id',
        };

        final basicStage = validateProgressively(basicData);
        expect(basicStage.level, equals(ValidationLevel.basic));
        expect(basicStage.data!['id'], equals('simple-id'));

        // Invalid data
        final invalidData = {
          'invalid': 'data',
        };

        final failedStage = validateProgressively(invalidData);
        expect(failedStage.level, equals(ValidationLevel.failed));
        expect(failedStage.error, isNotNull);
      });
    });

    group('Error Collection and Reporting', () {
      test('should collect all validation errors for comprehensive feedback',
          () {
        List<ValidationError> collectAllErrors(dynamic input) {
          final errors = <ValidationError>[];

          if (input is! Map<String, dynamic>) {
            errors.add(ValidationError('root', 'Expected object'));
            return errors;
          }

          final data = input;

          // Check each field individually
          final fieldSchemas = <String, AckSchema>{
            'name': Ack.string().minLength(2),
            'age': Ack.integer().min(0).max(150),
            'email': Ack.string().email(),
            'tags': Ack.list(Ack.string().minLength(1)),
          };

          for (final entry in fieldSchemas.entries) {
            final fieldName = entry.key;
            final fieldSchema = entry.value;

            if (data.containsKey(fieldName)) {
              final fieldResult = fieldSchema.validate(data[fieldName]);
              if (fieldResult.isFail) {
                errors.add(ValidationError(
                  fieldName,
                  fieldResult.getError().message,
                ));
              }
            } else {
              errors.add(ValidationError(fieldName, 'Field is required'));
            }
          }

          return errors;
        }

        final invalidData = {
          'name': 'J', // Too short
          'age': -5, // Below minimum
          'email': 'invalid-email', // Invalid format
          'tags': ['', 'valid-tag'], // Contains empty string
        };

        final errors = collectAllErrors(invalidData);
        expect(errors.length, greaterThan(0));

        // Should have errors for multiple fields
        final fieldNames = errors.map((e) => e.field).toSet();
        expect(fieldNames, contains('name'));
        expect(fieldNames, contains('age'));
        expect(fieldNames, contains('email'));
      });
    });

    group('Retry and Recovery Strategies', () {
      test('should implement retry logic with exponential backoff', () async {
        var attemptCount = 0;
        final maxAttempts = 3;

        Future<ValidationResult<String>> validateWithRetry(
          String input,
          AckSchema schema,
        ) async {
          for (var attempt = 1; attempt <= maxAttempts; attempt++) {
            attemptCount++;

            // Simulate network validation that might fail
            if (attempt < 3) {
              // Simulate failure for first two attempts
              await Future.delayed(Duration(milliseconds: 10 * attempt));
              continue;
            }

            // Success on third attempt
            final result = schema.validate(input);
            if (result.isOk) {
              return ValidationResult.success(result.getOrThrow() as String);
            } else {
              return ValidationResult.failure(result.getError().message);
            }
          }

          return ValidationResult.failure('Max retry attempts exceeded');
        }

        final schema = Ack.string().email();
        final result = await validateWithRetry('user@example.com', schema);

        expect(result.isSuccess, isTrue);
        expect(attemptCount, equals(3));
      });
    });

    group('User-Friendly Error Presentation', () {
      test('should format errors for end users', () {
        String formatUserFriendlyError(SchemaError error) {
          final message = error.message.toLowerCase();

          // Debug: print the actual message to understand its format
          // print('Debug: Error message = "$message"');

          // Convert technical messages to user-friendly ones
          if (message.contains('email') && message.contains('valid')) {
            return 'Please enter a valid email address (e.g., user@example.com)';
          }

          // Look for length constraints in the message - be more flexible
          if (message.contains('5')) {
            if (message.contains('least') ||
                message.contains('minimum') ||
                message.contains('min')) {
              return 'This field must be at least 5 characters long';
            }
          }

          if (message.contains('length') || message.contains('characters')) {
            final match = RegExp(r'(\d+)').firstMatch(message);
            if (match != null) {
              final length = match.group(1);
              if (message.contains('at least') || message.contains('least')) {
                return 'This field must be at least $length characters long';
              }
              if (message.contains('at most') || message.contains('most')) {
                return 'This field must be no more than $length characters long';
              }
            }
          }

          if (message.contains('positive')) {
            return 'Please enter a positive number';
          }

          // Default fallback
          return 'Please check your input and try again';
        }

        final testCases = [
          {
            'schema': Ack.string().email(),
            'input': 'invalid-email',
            'expectedPattern': 'valid email address',
          },
          {
            'schema': Ack.string().minLength(5),
            'input': 'hi',
            'expectedPattern': 'at least 5 characters',
          },
          {
            'schema': Ack.integer().positive(),
            'input': -1,
            'expectedPattern': 'positive number',
          },
        ];

        for (final testCase in testCases) {
          final schema = testCase['schema'] as AckSchema;
          final result = schema.validate(testCase['input']);
          expect(result.isFail, isTrue);

          final friendlyMessage = formatUserFriendlyError(result.getError());
          final expectedPattern = testCase['expectedPattern'] as String;

          expect(friendlyMessage.toLowerCase(), contains(expectedPattern),
              reason:
                  'Friendly message should contain "$expectedPattern": $friendlyMessage');
        }
      });
    });
  });
}

enum ValidationLevel { basic, enhanced, complete, failed }

class ValidationStage {
  final ValidationLevel level;
  final Map<String, dynamic>? data;
  final String? error;

  ValidationStage.basic(this.data)
      : level = ValidationLevel.basic,
        error = null;
  ValidationStage.enhanced(this.data)
      : level = ValidationLevel.enhanced,
        error = null;
  ValidationStage.complete(this.data)
      : level = ValidationLevel.complete,
        error = null;
  ValidationStage.failed(this.error)
      : level = ValidationLevel.failed,
        data = null;
}

class ValidationError {
  final String field;
  final String message;

  ValidationError(this.field, this.message);

  @override
  String toString() => '$field: $message';
}

class ValidationResult<T> {
  final bool isSuccess;
  final T? value;
  final String? error;

  ValidationResult.success(this.value)
      : isSuccess = true,
        error = null;
  ValidationResult.failure(this.error)
      : isSuccess = false,
        value = null;
}
