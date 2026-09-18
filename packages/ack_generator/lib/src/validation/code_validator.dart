import 'package:analyzer/dart/analysis/utilities.dart';

/// Validates that generated Dart code is syntactically correct.
///
/// Semantic errors are expected to resolve only after generated code is
/// combined with its source library, so this intentionally checks parsing only.
ValidationResult validateGeneratedDartCode(String dartCode) {
  try {
    final result = parseString(content: dartCode, throwIfDiagnostics: false);

    if (result.errors.isEmpty) {
      return ValidationResult.success();
    }

    final errorMessages = result.errors.map((error) {
      final location = result.lineInfo.getLocation(error.offset);
      return 'Line ${location.lineNumber}: ${error.message}';
    }).toList();

    return ValidationResult.failure(
      'Generated code contains syntax errors',
      errorMessages,
    );
  } catch (error) {
    return ValidationResult.failure('Failed to parse generated code', [
      'Parsing exception: $error',
    ]);
  }
}

class ValidationResult {
  final bool isSuccess;
  final String? errorSummary;
  final List<String> errorDetails;

  const ValidationResult.success()
    : isSuccess = true,
      errorSummary = null,
      errorDetails = const [];

  ValidationResult.failure(String summary, List<String> details)
    : isSuccess = false,
      errorSummary = summary,
      errorDetails = details;

  bool get isFailure => !isSuccess;

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
