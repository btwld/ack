import 'package:analyzer/dart/analysis/utilities.dart';

/// Standard validation utility for generated Dart code using analyzer API.
///
/// This follows Dart ecosystem best practices by using the official analyzer
/// package to validate syntax before writing generated files.
///
/// Note: This validator only checks for SYNTAX errors (parsing issues like
/// missing braces, invalid tokens). It does NOT check for SEMANTIC errors
/// (undefined identifiers, missing imports) as those are expected in generated
/// code that will be resolved when combined with the main source file.
class CodeValidator {
  /// Validates that the given Dart code is syntactically correct.
  ///
  /// Returns a [ValidationResult] indicating success or containing error details.
  /// Uses the standard `parseString` function from the analyzer package.
  static ValidationResult validate(String dartCode) {
    try {
      // Use parseString with throwIfDiagnostics: false to capture errors
      final result = parseString(content: dartCode, throwIfDiagnostics: false);

      // Check if there are any parsing errors
      if (result.errors.isEmpty) {
        return ValidationResult.success();
      }

      // Convert analyzer errors to readable format
      final errorMessages = result.errors.map((error) {
        final lineInfo = result.lineInfo;
        final location = lineInfo.getLocation(error.offset);
        return 'Line ${location.lineNumber}: ${error.message}';
      }).toList();

      return ValidationResult.failure(
        'Generated code contains syntax errors',
        errorMessages,
      );
    } catch (e) {
      // If parseString throws an exception, treat it as a validation failure
      return ValidationResult.failure('Failed to parse generated code', [
        'Parsing exception: $e',
      ]);
    }
  }
}

/// Result of code validation containing success status and error details.
class ValidationResult {
  final bool isSuccess;
  final String? errorSummary;
  final List<String> errorDetails;

  const ValidationResult._({
    required this.isSuccess,
    this.errorSummary,
    this.errorDetails = const [],
  });

  /// Creates a successful validation result.
  factory ValidationResult.success() {
    return const ValidationResult._(isSuccess: true);
  }

  /// Creates a failed validation result with error details.
  factory ValidationResult.failure(String summary, List<String> details) {
    return ValidationResult._(
      isSuccess: false,
      errorSummary: summary,
      errorDetails: details,
    );
  }

  /// Returns true if validation failed.
  bool get isFailure => !isSuccess;

  /// Gets a formatted error message combining summary and details.
  String get errorMessage {
    if (isSuccess) return '';

    final buffer = StringBuffer(errorSummary ?? 'Validation failed');
    if (errorDetails.isNotEmpty) {
      buffer.writeln(':');
      for (final detail in errorDetails) {
        buffer.writeln('  • $detail');
      }
    }
    return buffer.toString();
  }
}
