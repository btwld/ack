import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:source_gen/source_gen.dart';
import 'package:ack_annotations/ack_annotations.dart';

import '../models/field_info.dart';
import '../models/constraint_info.dart';
import '../utils/doc_comment_utils.dart';

/// Analyzes individual fields in a model
class FieldAnalyzer {
  FieldInfo analyze(FieldElement2 field) {
    // Check for @AckField annotation
    final ackFieldAnnotation = TypeChecker.typeNamed(
      AckField,
    ).firstAnnotationOf(field);

    // Determine JSON key (from annotation or field name)
    final jsonKey = _getJsonKey(field, ackFieldAnnotation);

    // Determine if field is required
    final isRequired = _isRequired(field, ackFieldAnnotation);

    // Extract constraints
    final constraints = _extractConstraints(field, ackFieldAnnotation);

    // Extract description from annotation
    final description = _getDescription(field, ackFieldAnnotation);

    return FieldInfo(
      name: field.name3!,
      jsonKey: jsonKey,
      type: field.type,
      isRequired: isRequired,
      isNullable: field.type.nullabilitySuffix != NullabilitySuffix.none,
      constraints: constraints,
      description: description,
    );
  }

  String _getJsonKey(FieldElement2 field, DartObject? annotation) {
    if (annotation != null) {
      final jsonKeyField = annotation.getField('jsonKey');
      if (jsonKeyField != null && !jsonKeyField.isNull) {
        return jsonKeyField.toStringValue()!;
      }
    }
    return field.name3!;
  }

  String? _getDescription(FieldElement2 field, DartObject? annotation) {
    // Priority 1: Check annotation (explicit override takes precedence)
    if (annotation != null) {
      final descriptionField = annotation.getField('description');
      if (descriptionField != null && !descriptionField.isNull) {
        return descriptionField.toStringValue();
      }
    }

    // Priority 2: Fallback to doc comment
    return parseDocComment(field.documentationComment);
  }

  bool _isRequired(FieldElement2 field, DartObject? annotation) {
    // If no annotation, use automatic detection.
    if (annotation == null) {
      return _inferRequiredFromField(field);
    }

    // Tri-state mode is authoritative.
    return switch (_getRequiredMode(annotation)) {
      AckFieldRequiredMode.required => true,
      AckFieldRequiredMode.optional => false,
      AckFieldRequiredMode.auto => _inferRequiredFromField(field),
    };
  }

  bool _inferRequiredFromField(FieldElement2 field) {
    return field.type.nullabilitySuffix == NullabilitySuffix.none &&
        !field.firstFragment.hasInitializer;
  }

  AckFieldRequiredMode _getRequiredMode(DartObject annotation) {
    final modeIndex = annotation
        .getField('requiredMode')
        ?.getField('index')
        ?.toIntValue();
    return switch (modeIndex) {
      0 => AckFieldRequiredMode.auto,
      1 => AckFieldRequiredMode.required,
      2 => AckFieldRequiredMode.optional,
      _ => AckFieldRequiredMode.auto,
    };
  }

  List<ConstraintInfo> _extractConstraints(
    FieldElement2 field,
    DartObject? annotation,
  ) {
    final constraints = <ConstraintInfo>[];

    // Extract constraints from @AckField annotation.
    constraints.addAll(_extractAckFieldConstraints(annotation));

    // Extract constraints from decorator annotations
    constraints.addAll(_extractDecoratorConstraints(field));

    return constraints;
  }

  List<ConstraintInfo> _extractAckFieldConstraints(DartObject? annotation) {
    if (annotation == null) return const [];

    final constraints = <ConstraintInfo>[];
    final constraintsField = annotation.getField('constraints');
    if (constraintsField == null || constraintsField.isNull) {
      return constraints;
    }

    final constraintsList = constraintsField.toListValue();
    if (constraintsList == null) return constraints;

    for (final constraint in constraintsList) {
      // Parse constraint strings like "minLength(3)", "email()".
      final constraintStr = constraint.toStringValue();
      if (constraintStr == null) continue;

      final parsed = _parseConstraintString(constraintStr);
      if (parsed != null) {
        constraints.add(parsed);
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

  List<ConstraintInfo> _extractDecoratorConstraints(FieldElement2 field) {
    final constraints = <ConstraintInfo>[];

    _addStringConstraints(constraints, field);
    _addNumericConstraints(constraints, field);
    _addListConstraints(constraints, field);
    _addEnumConstraints(constraints, field);

    return constraints;
  }

  void _addStringConstraints(
    List<ConstraintInfo> constraints,
    FieldElement2 field,
  ) {
    _addIntConstraint(constraints, field, MinLength, 'length', 'minLength');
    _addIntConstraint(constraints, field, MaxLength, 'length', 'maxLength');

    if (TypeChecker.typeNamed(Email).hasAnnotationOfExact(field)) {
      constraints.add(ConstraintInfo(name: 'email', arguments: []));
    }

    if (TypeChecker.typeNamed(Url).hasAnnotationOfExact(field)) {
      constraints.add(ConstraintInfo(name: 'url', arguments: []));
    }

    final patternAnnotation = TypeChecker.typeNamed(
      Pattern,
    ).firstAnnotationOf(field);
    final pattern = patternAnnotation?.getField('pattern')?.toStringValue();
    if (pattern != null) {
      constraints.add(ConstraintInfo(name: 'matches', arguments: [pattern]));
    }
  }

  void _addNumericConstraints(
    List<ConstraintInfo> constraints,
    FieldElement2 field,
  ) {
    _addNumericConstraint(constraints, field, Min, 'min');
    _addNumericConstraint(constraints, field, Max, 'max');

    if (TypeChecker.typeNamed(Positive).hasAnnotationOfExact(field)) {
      constraints.add(ConstraintInfo(name: 'positive', arguments: []));
    }

    _addNumericConstraint(constraints, field, MultipleOf, 'multipleOf');
  }

  void _addListConstraints(
    List<ConstraintInfo> constraints,
    FieldElement2 field,
  ) {
    _addIntConstraint(constraints, field, MinItems, 'count', 'minItems');
    _addIntConstraint(constraints, field, MaxItems, 'count', 'maxItems');
  }

  void _addEnumConstraints(
    List<ConstraintInfo> constraints,
    FieldElement2 field,
  ) {
    final enumStringAnnotation = TypeChecker.typeNamed(
      EnumString,
    ).firstAnnotationOf(field);
    if (enumStringAnnotation == null) return;

    final valuesList = enumStringAnnotation.getField('values')?.toListValue();
    if (valuesList == null) return;

    final values = valuesList
        .map((v) => v.toStringValue())
        .where((v) => v != null)
        .cast<String>()
        .toList();
    if (values.isNotEmpty) {
      constraints.add(ConstraintInfo(name: 'enumString', arguments: values));
    }
  }

  void _addIntConstraint(
    List<ConstraintInfo> constraints,
    FieldElement2 field,
    Type annotationType,
    String valueFieldName,
    String constraintName,
  ) {
    final annotation = TypeChecker.typeNamed(
      annotationType,
    ).firstAnnotationOf(field);
    final value = annotation?.getField(valueFieldName)?.toIntValue();
    if (value != null) {
      constraints.add(
        ConstraintInfo(name: constraintName, arguments: [value.toString()]),
      );
    }
  }

  /// Extracts a numeric value from an annotation and adds it as a constraint.
  ///
  /// Tries toIntValue() first, then toDoubleValue(), because int literals
  /// like @Min(5) have toDoubleValue() return null in the analyzer.
  void _addNumericConstraint(
    List<ConstraintInfo> constraints,
    FieldElement2 field,
    Type annotationType,
    String constraintName,
  ) {
    final annotation = TypeChecker.typeNamed(
      annotationType,
    ).firstAnnotationOf(field);
    if (annotation == null) return;

    final valueField = annotation.getField('value');
    final valueStr =
        valueField?.toIntValue()?.toString() ??
        valueField?.toDoubleValue()?.toString();
    if (valueStr != null) {
      constraints.add(
        ConstraintInfo(name: constraintName, arguments: [valueStr]),
      );
    }
  }
}
