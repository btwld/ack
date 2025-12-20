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
        // Use withNullability: false to get type name without '?' suffix
        final fieldTypeName = field.type.getDisplayString(withNullability: false);
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

    // Only validate what the generator truly can't handle
    // Let natural generation failures surface for edge cases
    if (field.isMap && field.type is ParameterizedType) {
      final mapType = field.type as ParameterizedType;
      if (mapType.typeArguments.length >= 2) {
        final keyType = mapType.typeArguments[0];
        if (!keyType.isDartCoreString) {
          issues.add(
            'Field ${field.name} has Map with non-String key type. '
            'JSON requires String keys.',
          );
        }
      }
    }

    return issues;
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
  factory ModelValidationResult.failure(String summary, List<String> issues) {
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
