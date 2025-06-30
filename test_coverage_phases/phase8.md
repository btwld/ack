# Phase 8: Documentation Tests 📚

## Overview
This phase ensures all documentation examples are tested and working, creating an error catalog, and validating best practices demonstrated in docs.

## Current Status
- Documentation exists without systematic validation
- No tests for README code samples
- No error message catalog
- Examples may be outdated or broken

## Implementation Plan

### 8.1 Example Validation

#### Extract and test all code examples from README
```dart
// File: packages/ack/test/documentation/readme_examples_test.dart

import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('README Examples', () {
    group('Getting Started Example', () {
      test('basic validation example should work', () {
        // Example from README
        final userSchema = Ack.object({
          'name': Ack.string().minLength(3),
          'age': Ack.int().positive(),
          'email': Ack.string().email(),
        });

        final validUser = {
          'name': 'John Doe',
          'age': 25,
          'email': 'john@example.com',
        };

        final result = userSchema.parse(validUser);
        expect(result['name'], equals('John Doe'));
        expect(result['age'], equals(25));
        expect(result['email'], equals('john@example.com'));

        // Invalid example should throw
        final invalidUser = {
          'name': 'Jo', // Too short
          'age': -5, // Negative
          'email': 'not-an-email',
        };

        expect(
          () => userSchema.parse(invalidUser),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('Schema Types Examples', () {
      test('string schema examples', () {
        // Basic string
        final nameSchema = Ack.string();
        expect(nameSchema.parse('Hello'), equals('Hello'));

        // String with constraints
        final usernameSchema = Ack.string()
          .minLength(3)
          .maxLength(20)
          .pattern(RegExp(r'^[a-zA-Z0-9_]+$'));

        expect(usernameSchema.parse('john_doe'), equals('john_doe'));
        expect(
          () => usernameSchema.parse('jo'),
          throwsA(isA<ValidationException>()),
        );

        // String formats
        final emailSchema = Ack.string().email();
        final urlSchema = Ack.string().url();
        final uuidSchema = Ack.string().uuid();

        expect(emailSchema.parse('test@example.com'), equals('test@example.com'));
        expect(urlSchema.parse('https://example.com'), equals('https://example.com'));
        expect(
          uuidSchema.parse('550e8400-e29b-41d4-a716-446655440000'),
          equals('550e8400-e29b-41d4-a716-446655440000'),
        );
      });

      test('numeric schema examples', () {
        // Integer
        final ageSchema = Ack.int().min(0).max(150);
        expect(ageSchema.parse(25), equals(25));

        // Double
        final priceSchema = Ack.double().positive();
        expect(priceSchema.parse(19.99), equals(19.99));

        // Numeric constraints
        final scoreSchema = Ack.int()
          .min(0)
          .max(100)
          .multipleOf(5);

        expect(scoreSchema.parse(85), equals(85));
        expect(
          () => scoreSchema.parse(87),
          throwsA(isA<ValidationException>()),
        );
      });

      test('object schema examples', () {
        // Basic object
        final personSchema = Ack.object({
          'name': Ack.string(),
          'age': Ack.int(),
        });

        expect(
          personSchema.parse({'name': 'John', 'age': 30}),
          equals({'name': 'John', 'age': 30}),
        );

        // Nested objects
        final userSchema = Ack.object({
          'id': Ack.string().uuid(),
          'profile': Ack.object({
            'firstName': Ack.string(),
            'lastName': Ack.string(),
            'avatar': Ack.string().url().optional(),
          }),
          'settings': Ack.object({
            'theme': Ack.string().enum(['light', 'dark']),
            'notifications': Ack.bool(),
          }).partial(), // All fields optional
        });

        final user = userSchema.parse({
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'profile': {
            'firstName': 'John',
            'lastName': 'Doe',
          },
          'settings': {
            'theme': 'dark',
          },
        });

        expect(user['profile']['firstName'], equals('John'));
        expect(user['settings']['theme'], equals('dark'));
      });

      test('list schema examples', () {
        // Basic list
        final tagsSchema = Ack.list(Ack.string());
        expect(
          tagsSchema.parse(['dart', 'flutter', 'validation']),
          equals(['dart', 'flutter', 'validation']),
        );

        // List with constraints
        final emailListSchema = Ack.list(Ack.string().email())
          .minItems(1)
          .maxItems(5)
          .unique();

        expect(
          emailListSchema.parse(['user@example.com', 'admin@example.com']),
          equals(['user@example.com', 'admin@example.com']),
        );

        expect(
          () => emailListSchema.parse(['user@example.com', 'user@example.com']),
          throwsA(isA<ValidationException>()), // Duplicate
        );
      });
    });

    group('Advanced Features Examples', () {
      test('transformation example', () {
        // Transform string to int
        final stringToIntSchema = Ack.string()
          .pattern(RegExp(r'^\d+$'))
          .transform<int>((value) => int.parse(value));

        expect(stringToIntSchema.parse('42'), equals(42));

        // Transform and validate
        final percentageSchema = Ack.string()
          .pattern(RegExp(r'^\d+%$'))
          .transform<double>((value) => double.parse(value.replaceAll('%', '')) / 100)
          .refine((value) => value >= 0 && value <= 1, 'Invalid percentage');

        expect(percentageSchema.parse('75%'), equals(0.75));
      });

      test('discriminated union example', () {
        final resultSchema = Ack.discriminated(
          discriminatorKey: 'status',
          schemas: {
            'success': Ack.object({
              'status': Ack.literal('success'),
              'data': Ack.any(),
            }),
            'error': Ack.object({
              'status': Ack.literal('error'),
              'message': Ack.string(),
              'code': Ack.string(),
            }),
          },
        );

        final success = resultSchema.parse({
          'status': 'success',
          'data': {'id': 1, 'name': 'Test'},
        });

        expect(success['status'], equals('success'));

        final error = resultSchema.parse({
          'status': 'error',
          'message': 'Not found',
          'code': 'NOT_FOUND',
        });

        expect(error['status'], equals('error'));
      });

      test('object extension methods example', () {
        final baseUserSchema = Ack.object({
          'id': Ack.string(),
          'name': Ack.string(),
        });

        // Extend
        final extendedSchema = baseUserSchema.extend({
          'email': Ack.string().email(),
          'role': Ack.string().enum(['user', 'admin']),
        });

        // Pick
        final publicSchema = extendedSchema.pick(['id', 'name']);

        // Omit
        final withoutIdSchema = extendedSchema.omit(['id']);

        // Partial
        final updateSchema = extendedSchema.partial();

        // Merge
        final mergedSchema = baseUserSchema.merge(Ack.object({
          'email': Ack.string().email(),
          'createdAt': Ack.string().datetime(),
        }));

        // Test each variation
        expect(
          publicSchema.parse({'id': '123', 'name': 'John'}),
          equals({'id': '123', 'name': 'John'}),
        );

        expect(
          updateSchema.parse({'name': 'Jane'}),
          equals({'name': 'Jane'}),
        );
      });

      test('refinement example', () {
        final passwordSchema = Ack.string()
          .minLength(8)
          .refine(
            (password) => RegExp(r'[A-Z]').hasMatch(password),
            'Password must contain at least one uppercase letter',
          )
          .refine(
            (password) => RegExp(r'[0-9]').hasMatch(password),
            'Password must contain at least one number',
          );

        expect(passwordSchema.parse('SecurePass123'), equals('SecurePass123'));

        expect(
          () => passwordSchema.parse('weakpass'),
          throwsA(isA<ValidationException>()),
        );

        // Object-level refinement
        final signupSchema = Ack.object({
          'password': Ack.string(),
          'confirmPassword': Ack.string(),
        }).refine(
          (data) => data['password'] == data['confirmPassword'],
          'Passwords do not match',
        );

        expect(
          () => signupSchema.parse({
            'password': 'pass123',
            'confirmPassword': 'pass456',
          }),
          throwsA(isA<ValidationException>()
            .having((e) => e.message, 'message', contains('Passwords do not match'))),
        );
      });
    });

    group('Error Handling Examples', () {
      test('try-parse example', () {
        final schema = Ack.int().positive();

        final result1 = schema.tryParse(42);
        expect(result1.isValid, isTrue);
        expect(result1.value, equals(42));

        final result2 = schema.tryParse(-5);
        expect(result2.isValid, isFalse);
        expect(result2.error, isA<ValidationException>());
      });

      test('error details example', () {
        final schema = Ack.object({
          'name': Ack.string().minLength(3),
          'age': Ack.int().positive(),
          'email': Ack.string().email(),
        });

        try {
          schema.parse({
            'name': 'Jo',
            'age': -5,
            'email': 'invalid',
          });
        } catch (e) {
          final error = e as ValidationException;
          
          expect(error.errors.length, greaterThanOrEqualTo(3));
          
          final nameError = error.errors.firstWhere((e) => e.path.contains('name'));
          expect(nameError.message, contains('at least 3'));
          
          final ageError = error.errors.firstWhere((e) => e.path.contains('age'));
          expect(ageError.message, contains('positive'));
          
          final emailError = error.errors.firstWhere((e) => e.path.contains('email'));
          expect(emailError.message, contains('email'));
        }
      });
    });
  });
}
```

#### Extract and test all code examples from API docs
```dart
// File: packages/ack/test/documentation/api_docs_examples_test.dart

void main() {
  group('API Documentation Examples', () {
    group('AckSchema class examples', () {
      test('parse method example', () {
        /// Example from parse() documentation
        final schema = Ack.string().email();
        
        // Valid input
        final email = schema.parse('user@example.com');
        expect(email, equals('user@example.com'));
        
        // Invalid input throws ValidationException
        expect(
          () => schema.parse('not-an-email'),
          throwsA(isA<ValidationException>()),
        );
      });

      test('tryParse method example', () {
        /// Example from tryParse() documentation
        final schema = Ack.int().positive();
        
        final result = schema.tryParse(42);
        if (result.isValid) {
          expect(result.value, equals(42));
        } else {
          fail('Should be valid');
        }
        
        final invalidResult = schema.tryParse(-5);
        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.error, isA<ValidationException>());
      });

      test('nullable method example', () {
        /// Example from nullable() documentation
        final schema = Ack.string().nullable();
        
        expect(schema.parse('hello'), equals('hello'));
        expect(schema.parse(null), isNull);
      });

      test('withDefault method example', () {
        /// Example from withDefault() documentation
        final schema = Ack.string().withDefault('anonymous');
        
        expect(schema.parse(null), equals('anonymous'));
        expect(schema.parse('John'), equals('John'));
      });

      test('optional method example', () {
        /// Example from optional() documentation
        final userSchema = Ack.object({
          'name': Ack.string(),
          'nickname': Ack.string().optional(),
        });
        
        expect(
          userSchema.parse({'name': 'John'}),
          equals({'name': 'John'}),
        );
        
        expect(
          userSchema.parse({'name': 'John', 'nickname': 'Johnny'}),
          equals({'name': 'John', 'nickname': 'Johnny'}),
        );
      });
    });

    group('String schema examples', () {
      test('string constraint examples', () {
        // minLength example
        final minLengthSchema = Ack.string().minLength(3);
        expect(minLengthSchema.parse('hello'), equals('hello'));
        expect(
          () => minLengthSchema.parse('hi'),
          throwsA(isA<ValidationException>()),
        );

        // maxLength example
        final maxLengthSchema = Ack.string().maxLength(10);
        expect(maxLengthSchema.parse('short'), equals('short'));
        expect(
          () => maxLengthSchema.parse('this is too long'),
          throwsA(isA<ValidationException>()),
        );

        // length example
        final exactLengthSchema = Ack.string().length(5);
        expect(exactLengthSchema.parse('hello'), equals('hello'));
        expect(
          () => exactLengthSchema.parse('hi'),
          throwsA(isA<ValidationException>()),
        );

        // pattern example
        final patternSchema = Ack.string().pattern(RegExp(r'^[A-Z][a-z]+$'));
        expect(patternSchema.parse('Hello'), equals('Hello'));
        expect(
          () => patternSchema.parse('hello'),
          throwsA(isA<ValidationException>()),
        );
      });

      test('string format examples', () {
        // email example
        final emailSchema = Ack.string().email();
        expect(emailSchema.parse('user@example.com'), equals('user@example.com'));

        // url example
        final urlSchema = Ack.string().url();
        expect(urlSchema.parse('https://example.com'), equals('https://example.com'));

        // uuid example
        final uuidSchema = Ack.string().uuid();
        expect(
          uuidSchema.parse('550e8400-e29b-41d4-a716-446655440000'),
          equals('550e8400-e29b-41d4-a716-446655440000'),
        );

        // datetime example
        final datetimeSchema = Ack.string().datetime();
        expect(
          datetimeSchema.parse('2024-01-01T00:00:00Z'),
          equals('2024-01-01T00:00:00Z'),
        );

        // ip example
        final ipSchema = Ack.string().ip();
        expect(ipSchema.parse('192.168.1.1'), equals('192.168.1.1'));
        expect(ipSchema.parse('::1'), equals('::1'));
      });
    });

    group('Numeric schema examples', () {
      test('numeric constraint examples', () {
        // min/max example
        final rangeSchema = Ack.int().min(1).max(100);
        expect(rangeSchema.parse(50), equals(50));

        // greaterThan/lessThan example
        final gtLtSchema = Ack.double().greaterThan(0).lessThan(1);
        expect(gtLtSchema.parse(0.5), equals(0.5));

        // positive/negative example
        final positiveSchema = Ack.int().positive();
        expect(positiveSchema.parse(42), equals(42));

        final negativeSchema = Ack.int().negative();
        expect(negativeSchema.parse(-42), equals(-42));

        // multipleOf example
        final multipleSchema = Ack.int().multipleOf(5);
        expect(multipleSchema.parse(15), equals(15));

        // finite example
        final finiteSchema = Ack.double().finite();
        expect(finiteSchema.parse(3.14), equals(3.14));
        expect(
          () => finiteSchema.parse(double.infinity),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('Complex type examples', () {
      test('union type example', () {
        /// Example of union types from docs
        final stringOrNumberSchema = Ack.union([
          Ack.string(),
          Ack.int(),
        ]);

        expect(stringOrNumberSchema.parse('hello'), equals('hello'));
        expect(stringOrNumberSchema.parse(42), equals(42));
        expect(
          () => stringOrNumberSchema.parse(true),
          throwsA(isA<ValidationException>()),
        );
      });

      test('literal type example', () {
        /// Example of literal types from docs
        final statusSchema = Ack.literal('active');
        expect(statusSchema.parse('active'), equals('active'));
        expect(
          () => statusSchema.parse('inactive'),
          throwsA(isA<ValidationException>()),
        );

        // Enum-like behavior
        final colorSchema = Ack.union([
          Ack.literal('red'),
          Ack.literal('green'),
          Ack.literal('blue'),
        ]);

        expect(colorSchema.parse('red'), equals('red'));
        expect(colorSchema.parse('blue'), equals('blue'));
      });
    });
  });
}
```

#### Create example test suite
```dart
// File: packages/ack/test/documentation/example_test_suite.dart

void main() {
  group('Documentation Example Test Suite', () {
    // Automatically find and test all examples
    final exampleFiles = [
      'basic_validation.dart',
      'schema_types.dart',
      'transformations.dart',
      'discriminated_unions.dart',
      'object_extensions.dart',
      'error_handling.dart',
      'advanced_patterns.dart',
    ];

    for (final file in exampleFiles) {
      test('examples in $file should compile and run', () async {
        final examplePath = 'example/$file';
        
        // Check if example file exists
        final exampleFile = File(examplePath);
        if (!exampleFile.existsSync()) {
          skip('Example file $examplePath not found');
        }

        // Run the example
        final result = await Process.run('dart', ['run', examplePath]);
        
        expect(result.exitCode, equals(0), 
          reason: 'Example should run without errors:\n${result.stderr}');
      });
    }
  });
}
```

#### Ensure examples follow best practices
```dart
// File: packages/ack/test/documentation/best_practices_test.dart

void main() {
  group('Best Practices Examples', () {
    test('schema reuse pattern', () {
      // Best practice: Define reusable schemas
      final emailSchema = Ack.string().email();
      final uuidSchema = Ack.string().uuid();
      final timestampSchema = Ack.string().datetime();

      final userSchema = Ack.object({
        'id': uuidSchema,
        'email': emailSchema,
        'createdAt': timestampSchema,
        'updatedAt': timestampSchema,
      });

      final postSchema = Ack.object({
        'id': uuidSchema,
        'authorId': uuidSchema,
        'title': Ack.string().minLength(1).maxLength(200),
        'createdAt': timestampSchema,
      });

      // Schemas are reusable
      expect(userSchema.parse({
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'email': 'user@example.com',
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-01T00:00:00Z',
      }), isA<Map>());
    });

    test('error handling pattern', () {
      // Best practice: Structured error handling
      final schema = Ack.object({
        'name': Ack.string().minLength(3),
        'age': Ack.int().min(18).max(100),
      });

      ValidationResult<Map<String, dynamic>> validateUser(dynamic data) {
        try {
          return ValidationResult.valid(schema.parse(data));
        } catch (e) {
          if (e is ValidationException) {
            // Convert to user-friendly messages
            final messages = e.errors.map((error) {
              final field = error.path.join('.');
              return '$field: ${error.message}';
            }).toList();
            
            return ValidationResult.invalid(messages.join(', '));
          }
          return ValidationResult.invalid('Unexpected error');
        }
      }

      final result = validateUser({'name': 'Jo', 'age': 150});
      expect(result.isValid, isFalse);
      expect(result.error, contains('name:'));
      expect(result.error, contains('age:'));
    });

    test('type-safe parsing pattern', () {
      // Best practice: Use type parameters for safety
      T parseConfig<T>(String json, AckSchema schema) {
        final data = jsonDecode(json);
        return schema.parse(data) as T;
      }

      final configSchema = Ack.object({
        'apiUrl': Ack.string().url(),
        'timeout': Ack.int().positive(),
        'retries': Ack.int().min(0).max(5),
      });

      final config = parseConfig<Map<String, dynamic>>(
        '{"apiUrl": "https://api.example.com", "timeout": 5000, "retries": 3}',
        configSchema,
      );

      expect(config['apiUrl'], equals('https://api.example.com'));
      expect(config['timeout'], equals(5000));
      expect(config['retries'], equals(3));
    });

    test('gradual validation pattern', () {
      // Best practice: Progressive validation
      class UserValidator {
        static final basicSchema = Ack.object({
          'email': Ack.string().email(),
        });

        static final profileSchema = basicSchema.extend({
          'name': Ack.string().minLength(1),
          'bio': Ack.string().maxLength(500).optional(),
        });

        static final completeSchema = profileSchema.extend({
          'verified': Ack.bool(),
          'role': Ack.string().enum(['user', 'admin']),
        });

        static Map<String, dynamic> validateSignup(dynamic data) {
          return basicSchema.parse(data);
        }

        static Map<String, dynamic> validateProfile(dynamic data) {
          return profileSchema.parse(data);
        }

        static Map<String, dynamic> validateComplete(dynamic data) {
          return completeSchema.parse(data);
        }
      }

      // Start with basic
      final step1 = UserValidator.validateSignup({
        'email': 'user@example.com',
      });
      expect(step1['email'], equals('user@example.com'));

      // Add profile
      final step2 = UserValidator.validateProfile({
        'email': 'user@example.com',
        'name': 'John Doe',
      });
      expect(step2['name'], equals('John Doe'));
    });
  });
}

class ValidationResult<T> {
  final bool isValid;
  final T? value;
  final String? error;

  ValidationResult.valid(this.value) : isValid = true, error = null;
  ValidationResult.invalid(this.error) : isValid = false, value = null;
}
```

### 8.2 Error Message Documentation

#### Document all possible error types
```dart
// File: packages/ack/test/documentation/error_catalog_test.dart

void main() {
  group('Error Message Catalog', () {
    final errorCatalog = <String, List<ErrorExample>>{};

    setUp(() {
      // Build comprehensive error catalog
      errorCatalog.clear();
    });

    test('type validation errors', () {
      final examples = <ErrorExample>[];

      // String type error
      examples.add(ErrorExample(
        schema: Ack.string(),
        input: 123,
        expectedError: 'Expected string but got int',
        description: 'Wrong type provided',
      ));

      // Number type error
      examples.add(ErrorExample(
        schema: Ack.int(),
        input: '123',
        expectedError: 'Expected integer but got string',
        description: 'String instead of number',
      ));

      // Object type error
      examples.add(ErrorExample(
        schema: Ack.object({'id': Ack.string()}),
        input: 'not an object',
        expectedError: 'Expected object but got string',
        description: 'Non-object value',
      ));

      errorCatalog['Type Validation'] = examples;
      
      // Verify all examples
      for (final example in examples) {
        try {
          example.schema.parse(example.input);
          fail('Should have thrown for: ${example.description}');
        } catch (e) {
          expect(e, isA<ValidationException>());
          final error = e as ValidationException;
          expect(error.message, contains(example.expectedError.split(' ').first));
        }
      }
    });

    test('constraint validation errors', () {
      final examples = <ErrorExample>[];

      // String length
      examples.add(ErrorExample(
        schema: Ack.string().minLength(5),
        input: 'hi',
        expectedError: 'String must be at least 5 characters',
        description: 'String too short',
      ));

      // Number range
      examples.add(ErrorExample(
        schema: Ack.int().min(0).max(100),
        input: 150,
        expectedError: 'Number must be at most 100',
        description: 'Number too large',
      ));

      // Pattern mismatch
      examples.add(ErrorExample(
        schema: Ack.string().pattern(RegExp(r'^\d+$')),
        input: 'abc',
        expectedError: 'String does not match pattern',
        description: 'Pattern validation failure',
      ));

      // Email format
      examples.add(ErrorExample(
        schema: Ack.string().email(),
        input: 'not-an-email',
        expectedError: 'Invalid email format',
        description: 'Invalid email',
      ));

      errorCatalog['Constraint Validation'] = examples;

      for (final example in examples) {
        try {
          example.schema.parse(example.input);
          fail('Should have thrown for: ${example.description}');
        } catch (e) {
          expect(e, isA<ValidationException>());
        }
      }
    });

    test('complex validation errors', () {
      final examples = <ErrorExample>[];

      // Missing required field
      examples.add(ErrorExample(
        schema: Ack.object({
          'id': Ack.string(),
          'name': Ack.string(),
        }),
        input: {'id': '123'},
        expectedError: 'Required property "name" is missing',
        description: 'Missing required field',
      ));

      // Additional properties in strict mode
      examples.add(ErrorExample(
        schema: Ack.object({'id': Ack.string()}).strict(),
        input: {'id': '123', 'extra': 'field'},
        expectedError: 'Additional properties are not allowed',
        description: 'Extra fields in strict mode',
      ));

      // Discriminated union error
      examples.add(ErrorExample(
        schema: Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'a': Ack.object({'type': Ack.literal('a')}),
            'b': Ack.object({'type': Ack.literal('b')}),
          },
        ),
        input: {'type': 'c'},
        expectedError: 'Invalid discriminator value "c". Expected one of: a, b',
        description: 'Invalid discriminator',
      ));

      errorCatalog['Complex Validation'] = examples;
    });

    test('generate error documentation', () {
      // Generate markdown documentation
      final doc = StringBuffer();
      doc.writeln('# Ack Validation Error Catalog\n');
      doc.writeln('This document lists all possible validation errors.\n');

      for (final category in errorCatalog.entries) {
        doc.writeln('## ${category.key}\n');
        
        for (final example in category.value) {
          doc.writeln('### ${example.description}');
          doc.writeln('**Schema:**');
          doc.writeln('```dart');
          doc.writeln(example.schemaCode ?? 'N/A');
          doc.writeln('```');
          doc.writeln('**Invalid Input:**');
          doc.writeln('```dart');
          doc.writeln(example.input.toString());
          doc.writeln('```');
          doc.writeln('**Error Message:**');
          doc.writeln('```');
          doc.writeln(example.expectedError);
          doc.writeln('```\n');
        }
      }

      // Save to file
      final file = File('docs/error_catalog.md');
      // In real implementation, would write to file
      expect(doc.toString(), contains('Error Catalog'));
    });
  });
}

class ErrorExample {
  final AckSchema schema;
  final dynamic input;
  final String expectedError;
  final String description;
  final String? schemaCode;

  ErrorExample({
    required this.schema,
    required this.input,
    required this.expectedError,
    required this.description,
    this.schemaCode,
  });
}
```

#### Create error message catalog
```dart
// File: packages/ack/lib/src/errors/error_messages.dart

/// Centralized error message catalog
class ErrorMessages {
  // Type errors
  static String expectedType(String expected, String actual) =>
      'Expected $expected but got $actual';
  
  static const String requiredValue = 'Value is required';
  static const String cannotBeNull = 'Value cannot be null';
  
  // String errors
  static String minLength(int min) =>
      'String must be at least $min character${min == 1 ? '' : 's'}';
  
  static String maxLength(int max) =>
      'String must be at most $max character${max == 1 ? '' : 's'}';
  
  static String exactLength(int length) =>
      'String must be exactly $length character${length == 1 ? '' : 's'}';
  
  static String pattern(String pattern) =>
      'String does not match pattern: $pattern';
  
  static const String invalidEmail = 'Invalid email format';
  static const String invalidUrl = 'Invalid URL format';
  static const String invalidUuid = 'Invalid UUID format';
  static const String invalidDatetime = 'Invalid datetime format';
  static const String invalidIp = 'Invalid IP address format';
  
  // Number errors
  static String min(num min) => 'Number must be at least $min';
  static String max(num max) => 'Number must be at most $max';
  static String greaterThan(num value) => 'Number must be greater than $value';
  static String lessThan(num value) => 'Number must be less than $value';
  static const String mustBePositive = 'Number must be positive';
  static const String mustBeNegative = 'Number must be negative';
  static String multipleOf(num factor) => 'Number must be a multiple of $factor';
  static const String mustBeFinite = 'Number must be finite';
  static const String mustBeInteger = 'Number must be an integer';
  
  // Object errors
  static String missingProperty(String property) =>
      'Required property "$property" is missing';
  
  static String additionalProperty(String property) =>
      'Additional property "$property" is not allowed';
  
  static const String additionalPropertiesNotAllowed = 
      'Additional properties are not allowed';
  
  // Array errors
  static String minItems(int min) =>
      'Array must have at least $min item${min == 1 ? '' : 's'}';
  
  static String maxItems(int max) =>
      'Array must have at most $max item${max == 1 ? '' : 's'}';
  
  static const String uniqueItems = 'Array must contain unique items';
  
  // Discriminated union errors
  static String missingDiscriminator(String key) =>
      'Missing discriminator field "$key"';
  
  static String invalidDiscriminator(String value, List<String> expected) =>
      'Invalid discriminator value "$value". Expected one of: ${expected.join(', ')}';
  
  // Custom validation errors
  static String customValidation(String message) => message;
  
  // Transformation errors
  static String transformationFailed(String error) =>
      'Transformation failed: $error';
}
```

#### Test error message clarity
```dart
// File: packages/ack/test/documentation/error_clarity_test.dart

void main() {
  group('Error Message Clarity', () {
    test('error messages should be helpful and actionable', () {
      final testCases = <ErrorClarityTest>[
        ErrorClarityTest(
          name: 'Type mismatch',
          schema: Ack.string(),
          input: 123,
          checks: [
            (error) => error.contains('Expected string'),
            (error) => error.contains('got int'),
          ],
        ),
        ErrorClarityTest(
          name: 'Missing required field',
          schema: Ack.object({
            'id': Ack.string(),
            'name': Ack.string(),
          }),
          input: {'id': '123'},
          checks: [
            (error) => error.contains('name'),
            (error) => error.contains('required'),
          ],
        ),
        ErrorClarityTest(
          name: 'Invalid format with suggestion',
          schema: Ack.string().email(),
          input: 'user@',
          checks: [
            (error) => error.contains('email'),
            (error) => error.contains('format') || error.contains('invalid'),
          ],
        ),
      ];

      for (final test in testCases) {
        try {
          test.schema.parse(test.input);
          fail('Should have thrown for: ${test.name}');
        } catch (e) {
          final error = e.toString().toLowerCase();
          
          for (final check in test.checks) {
            expect(check(error), isTrue,
              reason: 'Error message for "${test.name}" should be clear');
          }
        }
      }
    });

    test('error paths should be clear in nested structures', () {
      final schema = Ack.object({
        'user': Ack.object({
          'profile': Ack.object({
            'age': Ack.int().positive(),
          }),
        }),
      });

      try {
        schema.parse({
          'user': {
            'profile': {
              'age': -5,
            },
          },
        });
        fail('Should have thrown');
      } catch (e) {
        final error = e as ValidationException;
        
        expect(error.errors.first.path, equals(['user', 'profile', 'age']));
        expect(error.toString(), contains('user.profile.age'));
      }
    });
  });
}

class ErrorClarityTest {
  final String name;
  final AckSchema schema;
  final dynamic input;
  final List<bool Function(String)> checks;

  ErrorClarityTest({
    required this.name,
    required this.schema,
    required this.input,
    required this.checks,
  });
}
```

#### Add error recovery examples
```dart
// File: packages/ack/test/documentation/error_recovery_test.dart

void main() {
  group('Error Recovery Examples', () {
    test('provide fallback values on validation failure', () {
      T parseWithFallback<T>(
        dynamic input,
        AckSchema schema,
        T fallback,
      ) {
        final result = schema.tryParse(input);
        return result.isValid ? result.value as T : fallback;
      }

      final ageSchema = Ack.int().min(0).max(150);
      
      expect(parseWithFallback(25, ageSchema, 0), equals(25));
      expect(parseWithFallback(-5, ageSchema, 0), equals(0));
      expect(parseWithFallback('invalid', ageSchema, 0), equals(0));
    });

    test('collect all errors before failing', () {
      Map<String, List<String>> validateForm(Map<String, dynamic> data) {
        final errors = <String, List<String>>{};
        
        final schema = Ack.object({
          'username': Ack.string().minLength(3).maxLength(20),
          'email': Ack.string().email(),
          'age': Ack.int().min(18),
          'password': Ack.string().minLength(8),
        });

        final result = schema.tryParse(data);
        
        if (!result.isValid) {
          for (final error in result.error!.errors) {
            final field = error.path.last?.toString() ?? 'general';
            errors.putIfAbsent(field, () => []).add(error.message);
          }
        }
        
        return errors;
      }

      final errors = validateForm({
        'username': 'ab', // Too short
        'email': 'invalid', // Invalid format
        'age': 16, // Too young
        'password': '123', // Too short
      });

      expect(errors['username'], contains('at least 3'));
      expect(errors['email'], contains('email'));
      expect(errors['age'], contains('at least 18'));
      expect(errors['password'], contains('at least 8'));
    });

    test('progressive validation with partial data', () {
      class ProgressiveValidator {
        static final stages = {
          'basic': Ack.object({
            'email': Ack.string().email(),
          }).partial(),
          
          'profile': Ack.object({
            'email': Ack.string().email(),
            'name': Ack.string(),
            'bio': Ack.string().optional(),
          }).partial(),
          
          'complete': Ack.object({
            'email': Ack.string().email(),
            'name': Ack.string(),
            'bio': Ack.string().optional(),
            'verified': Ack.bool(),
          }),
        };

        static ValidationProgress validate(
          Map<String, dynamic> data,
          String stage,
        ) {
          final schema = stages[stage]!;
          final result = schema.tryParse(data);
          
          return ValidationProgress(
            stage: stage,
            isValid: result.isValid,
            errors: result.isValid ? [] : result.error!.errors,
            completeness: _calculateCompleteness(data, stage),
          );
        }

        static double _calculateCompleteness(
          Map<String, dynamic> data,
          String stage,
        ) {
          final requiredFields = {
            'basic': ['email'],
            'profile': ['email', 'name'],
            'complete': ['email', 'name', 'verified'],
          };

          final required = requiredFields[stage]!;
          final present = required.where((f) => data.containsKey(f)).length;
          
          return present / required.length;
        }
      }

      final progress1 = ProgressiveValidator.validate(
        {'email': 'user@example.com'},
        'basic',
      );
      expect(progress1.isValid, isTrue);
      expect(progress1.completeness, equals(1.0));

      final progress2 = ProgressiveValidator.validate(
        {'email': 'user@example.com'},
        'profile',
      );
      expect(progress2.isValid, isTrue); // Partial schema
      expect(progress2.completeness, equals(0.5));
    });
  });
}

class ValidationProgress {
  final String stage;
  final bool isValid;
  final List<ValidationError> errors;
  final double completeness;

  ValidationProgress({
    required this.stage,
    required this.isValid,
    required this.errors,
    required this.completeness,
  });
}
```

## Validation Checklist

- [ ] All README examples tested
- [ ] All API documentation examples tested
- [ ] Example test suite created
- [ ] Best practices documented and tested
- [ ] Error catalog created
- [ ] Error messages documented
- [ ] Error clarity verified
- [ ] Error recovery patterns demonstrated
- [ ] 100% of documentation examples working
- [ ] No outdated examples

## Success Metrics

- Zero broken examples in documentation
- Comprehensive error message catalog
- Clear, actionable error messages
- Best practices demonstrated with code
- All examples follow consistent patterns
- Documentation stays in sync with code