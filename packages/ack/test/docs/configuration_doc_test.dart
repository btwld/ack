import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Configuration Documentation Examples', () {
    group('Nullable Values', () {
      test('Basic nullable string', () {
        // Basic nullable string - accepts both strings and null
        final nameSchema = Ack.string.nullable();

        // Validate null value
        final nullResult = nameSchema.validate(null);
        expect(nullResult.isOk, isTrue);

        // Validate string value
        final stringResult = nameSchema.validate('Alice');
        expect(stringResult.isOk, isTrue);
      });
    });

    group('Default Values', () {
      test('Using getOrElse with null', () {
        // Basic approach with getOrElse
        final schema = Ack.string.nullable();
        final result = schema.validate(null);
        final valueWithDefault = result.getOrElse(() => 'Guest');
        expect(valueWithDefault, equals('Guest'));
      });

      test('Pipeline approach', () {
        // Pipeline approach
        final pipelinedValue =
            Ack.string.nullable().validate(null).getOrElse(() => 'Guest');
        expect(pipelinedValue, equals('Guest'));
      });

      test('Using with validation logic', () {
        // Using with validation logic
        String? getDataFromSource() => null; // Simulating null data

        final validatedData = Ack.string
            .minLength(3)
            .nullable()
            .validate(getDataFromSource())
            .getOrElse(() => 'Default Value');

        expect(validatedData, equals('Default Value'));
      });
    });

    group('Strict Type Checking', () {
      test('Default behavior vs strict behavior', () {
        // Default behavior: converts "123" to integer 123
        final looseSchema = Ack.int;
        expect(looseSchema.validate("123").isOk, isTrue);

        // Strict behavior: requires actual int type
        final strictSchema = Ack.int.strict();
        expect(strictSchema.validate("123").isOk, isFalse);
        expect(strictSchema.validate(123).isOk, isTrue);
      });
    });

    group('Custom Constraints', () {
      test('Reference to custom validation page', () {
        // This section now refers to the custom-validation.mdx page
        // for detailed examples and best practices
        expect(true, isTrue);
      });
    });

    group('Schema Composition', () {
      test('Multiple constraints', () {
        // Multiple constraints (all conditions must be met)
        final nameSchema = Ack.string.minLength(2).maxLength(50).isNotEmpty();

        expect(nameSchema.validate('John').isOk, isTrue);
        expect(nameSchema.validate('J').isOk, isFalse); // Too short
        expect(nameSchema.validate('A' * 51).isOk, isFalse); // Too long
      });

      test('Union types', () {
        // For a string ID with specific format
        final uuidSchema = Ack.string.constrain(StringRegexConstraint(
            patternName: 'uuid',
            pattern:
                r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            example: '123e4567-e89b-12d3-a456-426614174000'));

        // For an integer ID
        final intIdSchema = Ack.int.min(1);

        // Test string ID
        expect(uuidSchema.validate('123e4567-e89b-12d3-a456-426614174000').isOk,
            isTrue);
        expect(uuidSchema.validate('not-a-uuid').isOk, isFalse);

        // Test int ID
        expect(intIdSchema.validate(42).isOk, isTrue);
        expect(intIdSchema.validate(0).isOk, isFalse);
      });
    });
  });
}

// Custom constraint for regex pattern matching
class StringRegexConstraint extends Constraint<String> with Validator<String> {
  final String patternName;
  final String pattern;
  final String example;
  late final RegExp _regex;

  StringRegexConstraint({
    required this.patternName,
    required this.pattern,
    required this.example,
  }) : super(
          constraintKey: 'regex_$patternName',
          description: 'Must match pattern: $pattern',
        ) {
    _regex = RegExp(pattern);
  }

  @override
  bool isValid(String value) => _regex.hasMatch(value);

  @override
  String buildMessage(String value) =>
      'Value must match $patternName pattern (e.g., $example)';
}
