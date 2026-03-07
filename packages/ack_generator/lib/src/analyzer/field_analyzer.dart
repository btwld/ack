import 'package:ack_annotations/ack_annotations.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:source_gen/source_gen.dart';

import '../models/constraint_info.dart';
import '../models/field_info.dart';
import '../utils/annotation_utils.dart';
import '../utils/case_style_utils.dart';
import '../utils/doc_comment_utils.dart';

/// Analyzes constructor parameters in a schemable model.
class FieldAnalyzer {
  FieldInfo analyze(
    FormalParameterElement parameter, {
    required CaseStyle caseStyle,
  }) {
    final jsonKey = _getJsonKey(parameter, caseStyle);
    final constraints = _extractDecoratorConstraints(parameter);
    final description = _getDescription(parameter);

    return FieldInfo(
      name: parameter.name3!,
      jsonKey: jsonKey,
      type: parameter.type,
      isRequired: parameter.isRequiredNamed,
      isNullable: parameter.type.nullabilitySuffix != NullabilitySuffix.none,
      constraints: constraints,
      description: description,
    );
  }

  String _getJsonKey(FormalParameterElement parameter, CaseStyle caseStyle) {
    final annotation = schemaKeyChecker.firstAnnotationOf(parameter);
    if (annotation != null) {
      final keyName = annotation.getField('name')?.toStringValue();
      if (keyName != null && keyName.isNotEmpty) {
        return keyName;
      }
    }

    return applyCaseStyle(caseStyle, parameter.name3!);
  }

  String? _getDescription(FormalParameterElement parameter) {
    final annotation = descriptionChecker.firstAnnotationOf(parameter);
    if (annotation != null) {
      final value = annotation.getField('value')?.toStringValue();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return parseDocComment(parameter.documentationComment);
  }

  List<ConstraintInfo> _extractDecoratorConstraints(
    FormalParameterElement parameter,
  ) {
    final constraints = <ConstraintInfo>[];

    _addStringConstraints(constraints, parameter);
    _addNumericConstraints(constraints, parameter);
    _addListConstraints(constraints, parameter);
    _addEnumConstraints(constraints, parameter);

    final hasEnumString = constraints.any((c) => c.name == 'enumString');
    final hasOtherStringConstraints = constraints.any(
      (c) => const {
        'minLength',
        'maxLength',
        'email',
        'url',
        'matches',
      }.contains(c.name),
    );
    if (hasEnumString && hasOtherStringConstraints) {
      throw ArgumentError(
        '@EnumString cannot be combined with other string constraints '
        '(@MinLength, @MaxLength, @Email, @Url, @Pattern) on parameter '
        '"${parameter.name3}".',
      );
    }

    return constraints;
  }

  void _addStringConstraints(
    List<ConstraintInfo> constraints,
    FormalParameterElement parameter,
  ) {
    _addIntConstraint(constraints, parameter, MinLength, 'length', 'minLength');
    _addIntConstraint(constraints, parameter, MaxLength, 'length', 'maxLength');

    if (TypeChecker.typeNamed(Email).hasAnnotationOfExact(parameter)) {
      constraints.add(constraint('email'));
    }

    if (TypeChecker.typeNamed(Url).hasAnnotationOfExact(parameter)) {
      constraints.add(constraint('url'));
    }

    final patternAnnotation = TypeChecker.typeNamed(
      Pattern,
    ).firstAnnotationOf(parameter);
    final pattern = patternAnnotation?.getField('pattern')?.toStringValue();
    if (pattern != null) {
      constraints.add(ConstraintInfo(name: 'matches', arguments: [pattern]));
    }
  }

  void _addNumericConstraints(
    List<ConstraintInfo> constraints,
    FormalParameterElement parameter,
  ) {
    _addNumericConstraint(constraints, parameter, Min, 'min');
    _addNumericConstraint(constraints, parameter, Max, 'max');

    if (TypeChecker.typeNamed(Positive).hasAnnotationOfExact(parameter)) {
      constraints.add(constraint('positive'));
    }

    _addNumericConstraint(constraints, parameter, MultipleOf, 'multipleOf');
  }

  void _addListConstraints(
    List<ConstraintInfo> constraints,
    FormalParameterElement parameter,
  ) {
    _addIntConstraint(constraints, parameter, MinItems, 'count', 'minItems');
    _addIntConstraint(constraints, parameter, MaxItems, 'count', 'maxItems');
  }

  void _addEnumConstraints(
    List<ConstraintInfo> constraints,
    FormalParameterElement parameter,
  ) {
    final annotation = TypeChecker.typeNamed(
      EnumString,
    ).firstAnnotationOf(parameter);
    if (annotation == null) return;

    final valuesList = annotation.getField('values')?.toListValue();
    if (valuesList == null) return;

    final values = valuesList
        .map((value) => value.toStringValue())
        .where((value) => value != null)
        .cast<String>()
        .toList();

    if (values.isNotEmpty) {
      constraints.add(ConstraintInfo(name: 'enumString', arguments: values));
    }
  }

  void _addIntConstraint(
    List<ConstraintInfo> constraints,
    FormalParameterElement parameter,
    Type annotationType,
    String valueFieldName,
    String constraintName,
  ) {
    final annotation = TypeChecker.typeNamed(
      annotationType,
    ).firstAnnotationOf(parameter);
    final value = annotation?.getField(valueFieldName)?.toIntValue();
    if (value != null) {
      constraints.add(
        ConstraintInfo(name: constraintName, arguments: [value.toString()]),
      );
    }
  }

  void _addNumericConstraint(
    List<ConstraintInfo> constraints,
    FormalParameterElement parameter,
    Type annotationType,
    String constraintName,
  ) {
    final annotation = TypeChecker.typeNamed(
      annotationType,
    ).firstAnnotationOf(parameter);
    if (annotation == null) return;

    final rawValue = annotation.getField('value');
    final value = _readNumericValue(rawValue);
    if (value == null) return;

    constraints.add(ConstraintInfo(name: constraintName, arguments: [value]));
  }

  String? _readNumericValue(DartObject? value) {
    if (value == null || value.isNull) return null;

    final intValue = value.toIntValue();
    if (intValue != null) {
      return intValue.toString();
    }

    final doubleValue = value.toDoubleValue();
    if (doubleValue != null) {
      return doubleValue.toString();
    }

    return null;
  }

  ConstraintInfo constraint(String name) {
    return ConstraintInfo(name: name, arguments: const []);
  }
}
