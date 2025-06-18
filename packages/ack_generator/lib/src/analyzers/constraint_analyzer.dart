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

  /// Extract constraint from annotation
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
    // Transform legacy names to standard format
    final standardName = _transformLegacyAnnotationName(annotationName);

    const mapping = {
      // Standard 'Is' prefix annotations
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

      // Special annotations
      'Description': 'description',
      'FieldType': 'fieldType',
    };

    return mapping[standardName];
  }

  /// Transform legacy annotation names to standard 'Is' prefix format
  static String _transformLegacyAnnotationName(String annotationName) {
    // List of known legacy names that should be prefixed with 'Is'
    const legacyNames = {
      'Required',
      'Nullable',
      'MinLength',
      'MaxLength',
      'Pattern',
      'EnumValues',
      'Min',
      'Max',
      'MultipleOf',
      'MinItems',
      'MaxItems',
      'UniqueItems',
      'Email',
      'NotEmpty',
      'Date',
      'DateTime',
      'Positive',
      'Negative',
    };

    // If it's a legacy name without 'Is' prefix, add it
    if (legacyNames.contains(annotationName)) {
      return 'Is$annotationName';
    }

    return annotationName;
  }

  /// Extract parameters from ConstantReader
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
      final values = valuesReader!.listValue
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
        final pattern = params['pattern'] as String?;
        if (pattern == null) return expr;
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
