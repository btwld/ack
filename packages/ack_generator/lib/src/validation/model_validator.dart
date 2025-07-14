import 'package:analyzer/dart/element/type.dart';
import '../models/model_info.dart';
import '../models/field_info.dart';

/// Validates model structures before code generation to prevent complex issues.
///
/// This validator checks for patterns that would result in broken generated code,
/// such as complex nested generics that the generator cannot handle properly.
class ModelValidator {
  /// Validates a model and all its fields before code generation.
  ///
  /// Returns a [ModelValidationResult] indicating success or containing error details.
  static ModelValidationResult validateModel(ModelInfo modelInfo) {
    final issues = <String>[];

    // Check for circular references
    final circularCheck = _checkCircularReferences(modelInfo);
    if (circularCheck != null) {
      issues.add(circularCheck);
    }

    // Validate each field
    for (final field in modelInfo.fields) {
      final fieldIssues = _validateField(field);
      issues.addAll(fieldIssues);
    }

    if (issues.isEmpty) {
      return ModelValidationResult.success();
    }

    return ModelValidationResult.failure(
      'Model ${modelInfo.className} has validation issues',
      issues,
    );
  }

  /// Checks for circular reference patterns that cause generation issues.
  static String? _checkCircularReferences(ModelInfo modelInfo) {
    // Look for self-referential fields that could cause cycles
    for (final field in modelInfo.fields) {
      if (field.isNestedSchema) {
        final fieldTypeName = field.type.getDisplayString().replaceAll('?', '');
        if (fieldTypeName == modelInfo.className) {
          // Direct self-reference is okay if it's nullable
          if (!field.isNullable) {
            return 'Field ${field.name} creates a non-nullable circular reference to ${modelInfo.className}';
          }
        }
      }
    }
    return null;
  }

  /// Validates individual field types for generation compatibility.
  static List<String> _validateField(FieldInfo field) {
    final issues = <String>[];

    // Check for complex nested generics that break generation
    if (_isComplexNestedGeneric(field.type)) {
      issues.add(
          'Field ${field.name} has complex nested generics (${field.type.getDisplayString()}) '
          'that may not generate correctly. Consider using simpler types or Map<String, dynamic>.');
    }

    // Check for unsupported collection nesting
    if (_hasUnsupportedNesting(field.type)) {
      issues.add(
          'Field ${field.name} has unsupported collection nesting (${field.type.getDisplayString()}). '
          'Deep nesting like List<Map<String, List<T>>> is not fully supported.');
    }

    return issues;
  }

  /// Checks if a type has complex nested generics that cause generation issues.
  static bool _isComplexNestedGeneric(DartType type) {
    if (type is! ParameterizedType) return false;

    // Count nesting depth of generic types
    var depth = 0;
    DartType currentType = type;

    while (currentType is ParameterizedType &&
        currentType.typeArguments.isNotEmpty) {
      depth++;
      if (depth > 2) {
        return true; // Too deep
      }
      currentType = currentType.typeArguments.first;
    }

    return false;
  }

  /// Checks for unsupported collection nesting patterns.
  static bool _hasUnsupportedNesting(DartType type) {
    // Look for patterns like List<Map<String, List<String>>>
    if (type is ParameterizedType) {
      final typeName = type.element?.name;

      // If it's a List or Set
      if (typeName == 'List' || typeName == 'Set') {
        if (type.typeArguments.isNotEmpty) {
          final innerType = type.typeArguments.first;

          // Check if the inner type is also a complex generic
          if (innerType is ParameterizedType) {
            final innerTypeName = innerType.element?.name;

            // List<Map<...>> or similar patterns
            if (innerTypeName == 'Map' && innerType.typeArguments.length >= 2) {
              final mapValueType = innerType.typeArguments[1];

              // Map value is also a generic? This gets complex
              if (mapValueType is ParameterizedType) {
                return true;
              }
            }
          }
        }
      }
    }

    return false;
  }
}

/// Result of model validation containing success status and issue details.
class ModelValidationResult {
  final bool isSuccess;
  final String? errorSummary;
  final List<String> issues;

  const ModelValidationResult._({
    required this.isSuccess,
    this.errorSummary,
    this.issues = const [],
  });

  /// Creates a successful validation result.
  factory ModelValidationResult.success() {
    return const ModelValidationResult._(isSuccess: true);
  }

  /// Creates a failed validation result with issue details.
  factory ModelValidationResult.failure(
    String summary,
    List<String> issues,
  ) {
    return ModelValidationResult._(
      isSuccess: false,
      errorSummary: summary,
      issues: issues,
    );
  }

  /// Returns true if validation failed.
  bool get isFailure => !isSuccess;

  /// Gets a formatted error message combining summary and issues.
  String get errorMessage {
    if (isSuccess) return '';

    final buffer = StringBuffer(errorSummary ?? 'Model validation failed');
    if (issues.isNotEmpty) {
      buffer.writeln(':');
      for (final issue in issues) {
        buffer.writeln('  • $issue');
      }
    }
    return buffer.toString();
  }
}
