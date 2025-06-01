import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import '../models/property_constraint_info.dart';

/// Analyzes constraint annotations and extracts constraint information
class ConstraintAnalyzer {
  /// Single method to extract constraint and apply it to expression
  static String processConstraint(
    ElementAnnotation metadata,
    String expression,
  ) {
    final constraint = _extractConstraint(metadata);
    if (constraint == null) return expression;

    return applyConstraint(expression, constraint);
  }

  /// Extract constraint from annotation (simplified approach)
  static PropertyConstraintInfo? _extractConstraint(
    ElementAnnotation metadata,
  ) {
    final name = metadata.element?.displayName;
    if (name == null) return null;

    // Handle special cases
    if (name == 'IsRequired' || name == 'Required') return RequiredConstraint();
    if (name == 'IsNullable' || name == 'Nullable') return NullableConstraint();

    final reader = ConstantReader(metadata.computeConstantValue());

    // Direct mapping based on annotation name (more reliable than trying to read constraintKey)
    final constraintKey = _getConstraintKeyFromAnnotationName(name);
    if (constraintKey != null) {
      return PropertyConstraintInfo(
        constraintKey: constraintKey,
        parameters: _extractParameters(reader),
      );
    }

    return null;
  }

  /// Map annotation names to constraint keys
  static String? _getConstraintKeyFromAnnotationName(String annotationName) {
    const mapping = {
      // New 'Is' prefix annotations
      'IsRequired': 'required',
      'IsNullable': 'nullable',
      'IsEmail': 'email',
      'IsNotEmpty': 'notEmpty',
      'IsMinLength': 'minLength',
      'IsMaxLength': 'maxLength',
      'IsPattern': 'pattern',
      'IsEnumValues': 'enumValues',
      'IsDate': 'date',
      'IsDateTime': 'dateTime',
      'IsMin': 'min',
      'IsMax': 'max',
      'IsMultipleOf': 'multipleOf',
      'IsPositive': 'positive',
      'IsNegative': 'negative',
      'IsMinItems': 'minItems',
      'IsMaxItems': 'maxItems',
      'IsUniqueItems': 'uniqueItems',

      // Legacy annotations (for backward compatibility)
      'Required': 'required',
      'Nullable': 'nullable',
      'MinLength': 'minLength',
      'MaxLength': 'maxLength',
      'Pattern': 'pattern',
      'EnumValues': 'enumValues',
      'Min': 'min',
      'Max': 'max',
      'MultipleOf': 'multipleOf',
      'MinItems': 'minItems',
      'MaxItems': 'maxItems',
      'UniqueItems': 'uniqueItems',

      // Special annotations
      'Description': 'description',
      'FieldType': 'fieldType',
    };

    return mapping[annotationName];
  }

  /// Extract parameters using simple, direct approach
  static Map<String, Object?> _extractParameters(ConstantReader reader) {
    final parameters = <String, Object?>{};

    // Extract common parameters directly
    final length = reader.peek('length')?.intValue;
    if (length != null) parameters['length'] = length;

    final value = reader.peek('value');
    if (value != null) {
      parameters['value'] =
          value.isInt ? value.intValue.toDouble() : value.doubleValue;
    }

    final pattern = reader.peek('pattern')?.stringValue;
    if (pattern != null) parameters['pattern'] = pattern;

    final text = reader.peek('text')?.stringValue;
    if (text != null) parameters['text'] = text;

    final count = reader.peek('count')?.intValue;
    if (count != null) parameters['count'] = count;

    final description = reader.peek('description')?.stringValue;
    if (description != null) parameters['description'] = description;

    // Handle enum values
    final valuesReader = reader.peek('values');
    if (valuesReader?.isList == true) {
      final values =
          valuesReader!.listValue
              .map((v) => ConstantReader(v).stringValue)
              .toList();
      parameters['values'] = values;
    }

    // Handle type
    final typeReader = reader.peek('type');
    if (typeReader?.isType == true) {
      parameters['type'] = typeReader!.typeValue.toString();
    }

    return parameters;
  }

  /// Apply constraint to expression using direct mapping
  static String applyConstraint(
    String expr,
    PropertyConstraintInfo constraint,
  ) {
    final key = constraint.constraintKey;
    final params = constraint.parameters;

    // Direct mapping without function abstractions
    switch (key) {
      // String constraints
      case 'email':
        return '$expr.email()';
      case 'notEmpty':
        return '$expr.notEmpty()';
      case 'minLength':
        return '$expr.minLength(${params['length']})';
      case 'maxLength':
        return '$expr.maxLength(${params['length']})';
      case 'pattern':
        final pattern = params['pattern'] as String;
        // Escape the pattern for Dart string literal
        final escapedPattern = pattern
            .replaceAll(r'\', r'\\')
            .replaceAll("'", r"\'")
            .replaceAll(r'$', r'\$');
        return "$expr.matches('$escapedPattern')";
      case 'enumValues':
        final values = (params['values'] as List).cast<String>();
        final enumList = values.map((v) => "'$v'").join(', ');
        return '$expr.enumValues([$enumList])';
      case 'date':
        return '$expr.date()';
      case 'dateTime':
        return '$expr.dateTime()';

      // Number constraints
      case 'min':
        return '$expr.min(${params['value']})';
      case 'max':
        return '$expr.max(${params['value']})';
      case 'multipleOf':
        return '$expr.multipleOf(${params['value']})';
      case 'positive':
        return '$expr.positive()';
      case 'negative':
        return '$expr.negative()';

      // List constraints
      case 'minItems':
        return '$expr.minItems(${params['count']})';
      case 'maxItems':
        return '$expr.maxItems(${params['count']})';
      case 'uniqueItems':
        return '$expr.uniqueItems()';

      // Legacy support (backward compatibility)
      case 'isEmail':
        return '$expr.email()';
      case 'isNotEmpty':
        return '$expr.notEmpty()';
      case 'isDate':
        return '$expr.date()';
      case 'isDateTime':
        return '$expr.dateTime()';
      case 'string_not_empty':
        return '$expr.notEmpty()';
      case 'string_enum':
        final values = (params['values'] as List).cast<String>();
        final enumList = values.map((v) => "'$v'").join(', ');
        return '$expr.enumValues([$enumList])';
      case 'string_pattern_email':
        return '$expr.email()';
      case 'datetime':
        return '$expr.dateTime()';

      default:
        return expr; // Return unchanged if not supported
    }
  }

  /// Extract all constraints from annotations
  static List<PropertyConstraintInfo> extractAllConstraints(
    List<ElementAnnotation> annotations,
  ) {
    return annotations
        .map(_extractConstraint)
        .where((c) => c != null)
        .cast<PropertyConstraintInfo>()
        .toList();
  }

  /// Check if constraint affects required status
  static bool isRequiredConstraint(PropertyConstraintInfo constraint) {
    return constraint is RequiredConstraint ||
        constraint.constraintKey == 'required';
  }

  /// Check if constraint affects nullable status
  static bool isNullableConstraint(PropertyConstraintInfo constraint) {
    return constraint is NullableConstraint ||
        constraint.constraintKey == 'nullable';
  }
}
