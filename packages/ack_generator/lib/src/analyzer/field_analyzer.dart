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
    // If no annotation, use automatic detection
    if (annotation == null) {
      return field.type.nullabilitySuffix == NullabilitySuffix.none &&
          !field.firstFragment.hasInitializer;
    }

    // Check if the annotation explicitly sets required
    // We need to distinguish between @AckField(required: true/false)
    // and @AckField(jsonKey: 'something') where required is not explicitly set

    // For now, we'll use a heuristic: if the annotation only has jsonKey set,
    // fall back to automatic detection. This handles the common case where
    // @AckField is used only to customize the JSON key.
    final hasExplicitRequired = _hasExplicitRequiredValue(annotation);

    if (hasExplicitRequired) {
      return annotation.getField('required')!.toBoolValue()!;
    }

    // Fall back to automatic detection
    return field.type.nullabilitySuffix == NullabilitySuffix.none &&
        !field.firstFragment.hasInitializer;
  }

  bool _hasExplicitRequiredValue(DartObject annotation) {
    // Check if `required` was explicitly provided in the annotation.
    //
    // The AckField annotation has `required` with a default value of `false`.
    // We can detect explicit usage by checking if the value differs from default,
    // OR if the annotation ONLY contains `required` (meaning the user wrote it).
    //
    // Heuristic: If required=true, it was definitely explicitly set (differs from default).
    // If required=false and NO other fields are set, it was explicitly set.
    // If required=false and other fields ARE set (jsonKey, constraints, description),
    // we need to check if description is set (which has no default) - if it is,
    // we can't tell. For simplicity, we'll treat required=true as explicit,
    // and required=false as "use automatic detection" to avoid breaking changes.
    //
    // This is imperfect - ideally we'd inspect the annotation AST directly.
    // But it preserves backward compatibility: existing code using
    // @AckField(jsonKey: 'x') will continue to use auto-detection.

    final requiredValue = annotation.getField('required')?.toBoolValue();

    // If required is true, it was explicitly set (differs from default of false)
    if (requiredValue == true) {
      return true;
    }

    // If required is false (the default), check if it's the only field set.
    // If the annotation has no jsonKey, constraints, or description,
    // then the user wrote @AckField(required: false) explicitly.
    final hasJsonKey = annotation.getField('jsonKey')?.toStringValue() != null;
    final hasConstraints =
        annotation.getField('constraints')?.toListValue()?.isNotEmpty ?? false;
    final hasDescription =
        annotation.getField('description')?.toStringValue() != null;

    // If no other fields are set, required: false was explicit
    if (!hasJsonKey && !hasConstraints && !hasDescription) {
      return true;
    }

    // Otherwise, we can't tell - fall back to automatic detection
    return false;
  }

  List<ConstraintInfo> _extractConstraints(
    FieldElement2 field,
    DartObject? annotation,
  ) {
    final constraints = <ConstraintInfo>[];

    // Extract constraints from @AckField annotation (legacy support)
    if (annotation != null) {
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
    }

    // Extract constraints from decorator annotations
    constraints.addAll(_extractDecoratorConstraints(field));

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

    // STRING LENGTH CONSTRAINTS
    final minLengthAnnotation = TypeChecker.typeNamed(
      MinLength,
    ).firstAnnotationOf(field);
    if (minLengthAnnotation != null) {
      final length = minLengthAnnotation.getField('length')?.toIntValue();
      if (length != null) {
        constraints.add(
          ConstraintInfo(name: 'minLength', arguments: [length.toString()]),
        );
      }
    }

    final maxLengthAnnotation = TypeChecker.typeNamed(
      MaxLength,
    ).firstAnnotationOf(field);
    if (maxLengthAnnotation != null) {
      final length = maxLengthAnnotation.getField('length')?.toIntValue();
      if (length != null) {
        constraints.add(
          ConstraintInfo(name: 'maxLength', arguments: [length.toString()]),
        );
      }
    }

    // STRING FORMAT CONSTRAINTS
    if (TypeChecker.typeNamed(Email).hasAnnotationOfExact(field)) {
      constraints.add(ConstraintInfo(name: 'email', arguments: []));
    }

    if (TypeChecker.typeNamed(Url).hasAnnotationOfExact(field)) {
      constraints.add(ConstraintInfo(name: 'url', arguments: []));
    }

    // STRING PATTERN CONSTRAINTS
    final patternAnnotation = TypeChecker.typeNamed(
      Pattern,
    ).firstAnnotationOf(field);
    if (patternAnnotation != null) {
      final pattern = patternAnnotation.getField('pattern')?.toStringValue();
      if (pattern != null) {
        constraints.add(ConstraintInfo(name: 'matches', arguments: [pattern]));
      }
    }

    // NUMERIC CONSTRAINTS
    // Note: We try toIntValue() first, then toDoubleValue(), because
    // int literals like @Min(5) have toDoubleValue() return null
    final minAnnotation = TypeChecker.typeNamed(Min).firstAnnotationOf(field);
    if (minAnnotation != null) {
      final valueField = minAnnotation.getField('value');
      final intValue = valueField?.toIntValue();
      final doubleValue = valueField?.toDoubleValue();
      final valueStr = intValue != null
          ? intValue.toString()
          : doubleValue?.toString();
      if (valueStr != null) {
        constraints.add(
          ConstraintInfo(name: 'min', arguments: [valueStr]),
        );
      }
    }

    final maxAnnotation = TypeChecker.typeNamed(Max).firstAnnotationOf(field);
    if (maxAnnotation != null) {
      final valueField = maxAnnotation.getField('value');
      final intValue = valueField?.toIntValue();
      final doubleValue = valueField?.toDoubleValue();
      final valueStr = intValue != null
          ? intValue.toString()
          : doubleValue?.toString();
      if (valueStr != null) {
        constraints.add(
          ConstraintInfo(name: 'max', arguments: [valueStr]),
        );
      }
    }

    if (TypeChecker.typeNamed(Positive).hasAnnotationOfExact(field)) {
      constraints.add(ConstraintInfo(name: 'positive', arguments: []));
    }

    final multipleOfAnnotation = TypeChecker.typeNamed(
      MultipleOf,
    ).firstAnnotationOf(field);
    if (multipleOfAnnotation != null) {
      final valueField = multipleOfAnnotation.getField('value');
      final intValue = valueField?.toIntValue();
      final doubleValue = valueField?.toDoubleValue();
      final valueStr = intValue != null
          ? intValue.toString()
          : doubleValue?.toString();
      if (valueStr != null) {
        constraints.add(
          ConstraintInfo(name: 'multipleOf', arguments: [valueStr]),
        );
      }
    }

    // LIST CONSTRAINTS
    final minItemsAnnotation = TypeChecker.typeNamed(
      MinItems,
    ).firstAnnotationOf(field);
    if (minItemsAnnotation != null) {
      final count = minItemsAnnotation.getField('count')?.toIntValue();
      if (count != null) {
        constraints.add(
          ConstraintInfo(name: 'minItems', arguments: [count.toString()]),
        );
      }
    }

    final maxItemsAnnotation = TypeChecker.typeNamed(
      MaxItems,
    ).firstAnnotationOf(field);
    if (maxItemsAnnotation != null) {
      final count = maxItemsAnnotation.getField('count')?.toIntValue();
      if (count != null) {
        constraints.add(
          ConstraintInfo(name: 'maxItems', arguments: [count.toString()]),
        );
      }
    }

    // ENUM CONSTRAINTS
    final enumStringAnnotation = TypeChecker.typeNamed(
      EnumString,
    ).firstAnnotationOf(field);
    if (enumStringAnnotation != null) {
      final valuesList = enumStringAnnotation.getField('values')?.toListValue();
      if (valuesList != null) {
        final values = valuesList
            .map((v) => v.toStringValue())
            .where((v) => v != null)
            .cast<String>()
            .toList();
        if (values.isNotEmpty) {
          constraints.add(
            ConstraintInfo(name: 'enumString', arguments: values),
          );
        }
      }
    }

    return constraints;
  }
}
