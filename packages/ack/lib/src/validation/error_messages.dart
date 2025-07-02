/// Centralized error message catalog for consistent validation error messages.
///
/// This class provides standardized error messages for all validation scenarios
/// in the Ack validation library. Using centralized messages ensures consistency
/// across the entire library and makes it easier to maintain and localize error messages.
class ErrorMessages {
  static const requiredValue = 'Value is required';

  static const cannotBeNull = 'Value cannot be null';

  static const invalidEmail = 'Invalid email format';
  static const invalidUrl = 'Invalid URL format';

  static const invalidUuid = 'Invalid UUID format';

  static const invalidDatetime = 'Invalid datetime format';

  static const invalidIp = 'Invalid IP address format';

  static const mustBePositive = 'Number must be positive';

  static const mustBeNegative = 'Number must be negative';
  static const mustBeFinite = 'Number must be finite';
  static const mustBeInteger = 'Number must be an integer';
  static const additionalPropertiesNotAllowed =
      'Additional properties are not allowed';
  static const uniqueItems = 'Array must contain unique items';

  // Nested validation errors
  static const nestedValidationFailed =
      'One or more nested schemas failed validation'; // Union type errors
  static const noUnionMatch =
      'Value does not match any of the union types'; // Intersection type errors
  static const intersectionFailed =
      'Value does not satisfy all intersection requirements'; // Format-specific error messages
  static const invalidPhoneNumber = 'Invalid phone number format';
  static const invalidCreditCard = 'Invalid credit card number';
  static const invalidPostalCode = 'Invalid postal code format';
  static const invalidCountryCode = 'Invalid country code';
  static const invalidLanguageCode = 'Invalid language code';
  static const invalidCurrencyCode = 'Invalid currency code';

  // Date and time specific errors
  static const invalidDate = 'Invalid date format';

  static const invalidTime = 'Invalid time format';

  static const invalidTimezone = 'Invalid timezone';

  static const invalidBase64 = 'Invalid Base64 encoding';

  static const invalidJson = 'Invalid JSON format';

  static const invalidXml = 'Invalid XML format';

  // Security validation errors
  static const weakPassword = 'Password does not meet security requirements';

  static const passwordMissingUppercase =
      'Password must contain at least one uppercase letter';

  static const passwordMissingLowercase =
      'Password must contain at least one lowercase letter';

  static const passwordMissingNumber =
      'Password must contain at least one number';

  static const passwordMissingSpecialChar =
      'Password must contain at least one special character';

  // Network and URL validation errors
  static const invalidDomain = 'Invalid domain name';

  static const invalidPort = 'Invalid port number';

  static const invalidProtocol = 'Invalid protocol';

  static const invalidHostname = 'Invalid hostname';

  // Business logic validation errors
  static const duplicateValue = 'Duplicate value not allowed';

  static const valueAlreadyExists = 'Value already exists';

  static const invalidReference = 'Invalid reference';

  static const circularReference =
      'Circular reference detected'; // Async validation errors
  static const asyncValidationFailed = 'Async validation failed';
  const // Private constructor to prevent instantiation
  ErrorMessages._();

  // Type errors
  static String expectedType(String expected, String actual) =>
      'Expected $expected but got $actual'; // String errors
  static String minLength(int min) =>
      'String must be at least $min character${min == 1 ? '' : 's'}';
  static String maxLength(int max) =>
      'String must be at most $max character${max == 1 ? '' : 's'}';

  static String exactLength(int length) =>
      'String must be exactly $length character${length == 1 ? '' : 's'}';
  static String pattern(String pattern) =>
      'String does not match pattern: $pattern'; // Number errors
  static String min(num min) => 'Number must be at least $min';
  static String max(num max) => 'Number must be at most $max';

  static String greaterThan(num value) => 'Number must be greater than $value';
  static String lessThan(num value) => 'Number must be less than $value';
  static String multipleOf(num factor) =>
      'Number must be a multiple of $factor'; // Object errors
  static String missingProperty(String property) =>
      'Required property "$property" is missing';
  static String additionalProperty(String property) =>
      'Additional property "$property" is not allowed';

  // Array errors
  static String minItems(int min) =>
      'Array must have at least $min item${min == 1 ? '' : 's'}';
  static String maxItems(int max) =>
      'Array must have at most $max item${max == 1 ? '' : 's'}'; // Discriminated union errors
  static String missingDiscriminator(String key) =>
      'Missing discriminator field "$key"';
  static String invalidDiscriminator(String value, List<String> expected) =>
      'Invalid discriminator value "$value". Expected one of: ${expected.join(', ')}'; // Enum errors
  static String invalidEnumValue(String value, List<String> validValues) =>
      'Invalid value "$value". Must be one of: ${validValues.join(', ')}'; // Custom validation errors
  static String customValidation(String message) => message;

  // Transformation errors
  static String transformationFailed(String error) =>
      'Transformation failed: $error'; // Refinement errors
  static String refinementFailed(String message) =>
      'Custom validation failed: $message';
  static String multipleErrors(int count) =>
      'Multiple validation errors occurred ($count errors)'; // Literal value errors
  static String literalMismatch(Object? expected, Object? actual) =>
      'Expected literal value "${expected ?? 'null'}" but got "${actual ?? 'null'}"';

  // Conditional validation errors
  static String conditionalFailed(String condition) =>
      'Conditional validation failed: $condition';
  static String dateOutOfRange(String min, String max) =>
      'Date must be between $min and $max'; // File and data validation errors
  static String fileSizeExceeded(int maxSize) =>
      'File size exceeds maximum allowed size of $maxSize bytes';
  static String invalidFileType(List<String> allowedTypes) =>
      'Invalid file type. Allowed types: ${allowedTypes.join(', ')}';

  static String passwordTooShort(int minLength) =>
      'Password must be at least $minLength characters long';
  static String asyncValidationTimeout(int timeoutMs) =>
      'Async validation timed out after ${timeoutMs}ms';

  // Utility methods for error message formatting
  static String formatFieldPath(List<String> path) {
    if (path.isEmpty) return 'root';

    return path.join('.');
  }

  static String formatErrorWithPath(String message, List<String> path) {
    final fieldPath = formatFieldPath(path);

    return 'At $fieldPath: $message';
  }

  static String formatMultipleErrors(List<String> errors) {
    if (errors.isEmpty) return 'No errors';
    if (errors.length == 1) return errors.first;

    final numbered = errors
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n');

    return 'Multiple validation errors:\n$numbered';
  }

  // Helper method to get user-friendly type names
  static String getTypeName(Type type) {
    switch (type.toString()) {
      case 'String':
        return 'string';
      case 'int':
        return 'integer';
      case 'double':
        return 'number';
      case 'bool':
        return 'boolean';
      case 'List<dynamic>':
      case 'List':
        return 'array';
      case 'Map<String, dynamic>':
      case 'Map':
        return 'object';
      default:
        return type.toString().toLowerCase();
    }
  }

  // Validation for error message parameters
  static void validateMessageParameters({
    int? min,
    int? max,
    String? pattern,
    List<String>? enumValues,
  }) {
    if (min != null && min < 0) {
      throw ArgumentError('Minimum value cannot be negative');
    }
    if (max != null && max < 0) {
      throw ArgumentError('Maximum value cannot be negative');
    }
    if (min != null && max != null && min > max) {
      throw ArgumentError('Minimum value cannot be greater than maximum value');
    }
    if (pattern != null && pattern.isEmpty) {
      throw ArgumentError('Pattern cannot be empty');
    }
    if (enumValues != null && enumValues.isEmpty) {
      throw ArgumentError('Enum values cannot be empty');
    }
  }
}
