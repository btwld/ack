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
    final docComment = field.documentationComment;
    if (docComment != null && docComment.isNotEmpty) {
      return parseDocComment(docComment);
    }

    return null;
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
    // This is a workaround: we check if only jsonKey or constraints are set
    // If so, we assume required was not explicitly set
    // This isn't perfect but works for the common cases

    // Check the source to see if 'required' was explicitly mentioned
    // For now, we'll assume that if required=false and there's a jsonKey,
    // then required was not explicitly set (using the default)

    final requiredValue = annotation.getField('required')?.toBoolValue();
    final hasJsonKey = annotation.getField('jsonKey')?.toStringValue() != null;
    final hasConstraints =
        annotation.getField('constraints')?.toListValue()?.isNotEmpty ?? false;

    // If required is false and we have jsonKey or constraints,
    // assume required was not explicitly set
    if (requiredValue == false && (hasJsonKey || hasConstraints)) {
      return false;
    }

    // Otherwise, assume it was explicitly set
    return true;
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
    final minAnnotation = TypeChecker.typeNamed(Min).firstAnnotationOf(field);
    if (minAnnotation != null) {
      final value = minAnnotation.getField('value')?.toDoubleValue();
      if (value != null) {
        constraints.add(
          ConstraintInfo(name: 'min', arguments: [value.toString()]),
        );
      }
    }

    final maxAnnotation = TypeChecker.typeNamed(Max).firstAnnotationOf(field);
    if (maxAnnotation != null) {
      final value = maxAnnotation.getField('value')?.toDoubleValue();
      if (value != null) {
        constraints.add(
          ConstraintInfo(name: 'max', arguments: [value.toString()]),
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
      final value = multipleOfAnnotation.getField('value')?.toDoubleValue();
      if (value != null) {
        constraints.add(
          ConstraintInfo(name: 'multipleOf', arguments: [value.toString()]),
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
