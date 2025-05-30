# Ack Development Roadmap

This document outlines planned features and improvements for future versions of Ack.

## Recently Implemented

### String Validation Extensions

- **✅ Added `matches` Method for String Schema**
  - Simplifies regex validation without requiring custom constraints
  - Checks if a string contains a pattern anywhere within it
  - Example: `Ack.string.matches(r'[A-Z]')` (checks if string contains uppercase letters)
  - Implementation:
    ```dart
    extension StringSchemaExtensions on StringSchema {
      StringSchema matches(String pattern, {String? example}) {
        final cleanPattern = pattern.replaceAll(r'^', '').replaceAll(r'$', '');
        final wrappedPattern = '^.*$cleanPattern.*\$';

        return constrain(
          StringRegexConstraint(
            patternName: 'matches',
            pattern: wrappedPattern,
            example: example ?? 'Example matching $pattern',
          ),
        );
      }
    }
    ```

- **✅ Added `pattern` Method for String Schema**
  - For validating that the entire string matches a pattern
  - Example: `Ack.string.pattern(r'[a-zA-Z0-9]+')` (validates entire string format)
  - Implementation:
    ```dart
    extension StringSchemaExtensions on StringSchema {
      StringSchema pattern(String regex, {String? example}) {
        final cleanPattern = regex.replaceAll(r'^', '').replaceAll(r'$', '');
        final completePattern = '^$cleanPattern\$';

        return constrain(
          StringRegexConstraint(
            patternName: 'pattern',
            pattern: completePattern,
            example: example ?? 'Example matching $regex',
          ),
        );
      }
    }
    ```

## Short-term Goals

### Built-in Validation Enhancements

- **Add `preprocess` Method**
  - Allow transforming values before validation
  - Example implementation:
    ```dart
    extension PreprocessExtension<T> on Schema<T> {
      Schema<T> preprocess(T Function(T value) preprocessor) {
        return transform(
          (value) {
            if (value == null) return SchemaResult.ok(null);
            final processed = preprocessor(value);
            return SchemaResult.ok(processed);
          },
          // Apply the transformation before validation
          applyBeforeValidation: true,
        );
      }
    }
    ```
  - Use cases:
    - Trimming whitespace: `Ack.string.preprocess((value) => value.trim()).email()`
    - Normalizing case: `Ack.string.preprocess((value) => value.toLowerCase())`
    - Format conversion: `Ack.string.preprocess((value) => value.replaceAll('-', ''))`

- **Add Exclusive Range Parameters**
  - Add `exclusive` parameter to `min` and `max` methods
  - Example: `Ack.double.min(0.0, exclusive: true)` (must be greater than 0, not equal)

### Error Handling Improvements

- **Structured Error Messages**
  - Improve error message formatting for nested objects
  - Add localization support for error messages

- **Custom Error Messages**
  - Allow custom error messages for all validators
  - Example: `Ack.string.minLength(3, message: 'Username must be at least 3 characters')`

## Medium-term Goals

### Schema Composition

- **Enhance `oneOf` and `allOf` Methods**
  - Improve type inference for union types
  - Add better error messages for composition failures

- **Add `anyOf` Method**
  - Validate that the input matches at least one of the provided schemas
  - Example: `Ack.anyOf([Ack.string, Ack.int])`

### Code Generation

- **Improve Generated Code**
  - Reduce boilerplate in generated code
  - Add support for more complex validation scenarios

- **Add Support for More Annotations**
  - Create annotations for common validation patterns
  - Example: `@Pattern(r'^[a-zA-Z0-9]+$')` for regex validation

## Long-term Goals

### Integration Enhancements

- **Improved OpenAPI Integration**
  - Support for OpenAPI 3.1 features
  - Better handling of complex schemas

- **GraphQL Schema Generation**
  - Generate GraphQL schemas from Ack schemas
  - Support for GraphQL input validation

### Performance Optimizations

- **Lazy Validation**
  - Stop validation on first error for better performance
  - Add option to collect all errors

- **Caching**
  - Cache validation results for frequently validated values
  - Optimize schema compilation

## Community Feedback

We welcome feedback and suggestions from the community. Please open an issue on GitHub if you have ideas for improving Ack.
