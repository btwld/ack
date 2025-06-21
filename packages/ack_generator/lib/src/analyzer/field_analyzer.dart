import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:source_gen/source_gen.dart';
import 'package:ack_annotations/ack_annotations.dart';

import '../models/field_info.dart';
import '../models/constraint_info.dart';

/// Analyzes individual fields in a model
class FieldAnalyzer {
  FieldInfo analyze(FieldElement field) {
    // Check for @AckField annotation
    final ackFieldAnnotation = _getAckFieldAnnotation(field);
    
    // Determine JSON key (from annotation or field name)
    final jsonKey = _getJsonKey(field, ackFieldAnnotation);
    
    // Determine if field is required
    final isRequired = _isRequired(field, ackFieldAnnotation);
    
    // Extract constraints
    final constraints = _extractConstraints(field, ackFieldAnnotation);
    
    // Get default value if any
    final defaultValue = _getDefaultValue(field);

    return FieldInfo(
      name: field.name,
      jsonKey: jsonKey,
      type: field.type,
      isRequired: isRequired,
      isNullable: field.type.nullabilitySuffix != NullabilitySuffix.none,
      constraints: constraints,
      defaultValue: defaultValue,
    );
  }

  DartObject? _getAckFieldAnnotation(FieldElement field) {
    final annotation = TypeChecker.fromRuntime(AckField).firstAnnotationOf(field);
    return annotation;
  }

  String _getJsonKey(FieldElement field, DartObject? annotation) {
    if (annotation != null) {
      final jsonKeyField = annotation.getField('jsonKey');
      if (jsonKeyField != null && !jsonKeyField.isNull) {
        return jsonKeyField.toStringValue()!;
      }
    }
    return field.name;
  }

  bool _isRequired(FieldElement field, DartObject? annotation) {
    // First check annotation
    if (annotation != null) {
      final requiredField = annotation.getField('required');
      if (requiredField != null && !requiredField.isNull) {
        return requiredField.toBoolValue()!;
      }
    }
    
    // If not nullable and no default value, it's required
    return field.type.nullabilitySuffix == NullabilitySuffix.none && 
           !field.hasInitializer;
  }

  List<ConstraintInfo> _extractConstraints(FieldElement field, DartObject? annotation) {
    final constraints = <ConstraintInfo>[];
    
    if (annotation == null) return constraints;
    
    final constraintsField = annotation.getField('constraints');
    if (constraintsField != null && !constraintsField.isNull) {
      final constraintsList = constraintsField.toListValue();
      if (constraintsList != null) {
        for (final constraint in constraintsList) {
          // Parse constraint strings like "minLength(3)", "email()"
          final constraintStr = constraint.toStringValue();
          if (constraintStr != null) {
            final parsed = _parseConstraintString(constraintStr);
            if (parsed != null) {
              constraints.add(parsed);
            }
          }
        }
      }
    }
    
    return constraints;
  }

  ConstraintInfo? _parseConstraintString(String constraint) {
    // Match patterns like "minLength(3)" or "email()"
    final match = RegExp(r'(\w+)\((.*)\)').firstMatch(constraint);
    if (match != null) {
      final name = match.group(1)!;
      final argsStr = match.group(2)!;
      final args = argsStr.isEmpty 
          ? <String>[]
          : argsStr.split(',').map((a) => a.trim()).toList();
      
      return ConstraintInfo(name: name, arguments: args);
    }
    
    // Simple constraint without parentheses
    return ConstraintInfo(name: constraint, arguments: []);
  }

  String? _getDefaultValue(FieldElement field) {
    // For now, return null - extracting default values is complex
    // and may not be needed for initial implementation
    return null;
  }
}
