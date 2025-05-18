import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

/// Analyzes constraint annotations and extracts constraint information
class ConstraintAnalyzer {
  /// Extract constraint from an annotation element
  static PropertyConstraintInfo? extractConstraint(ElementAnnotation metadata) {
    final name = metadata.element?.displayName;

    if (name == 'Required') {
      return RequiredConstraint();
    } else if (name == 'Nullable') {
      return NullableConstraint();
    }

    // Check for other constraints
    final reader = ConstantReader(metadata.computeConstantValue());

    switch (name) {
      case 'IsEmail':
        return PropertyConstraintInfo(
          constraintKey: 'isEmail',
          parameters: {},
        );
      case 'MinLength':
        return _extractMinLength(reader);
      case 'MaxLength':
        return _extractMaxLength(reader);
      case 'Pattern':
        return _extractPattern(reader);
      case 'IsNotEmpty':
        return PropertyConstraintInfo(
          constraintKey: 'isNotEmpty',
          parameters: {},
        );
      case 'EnumValues':
        return _extractEnumValues(reader);
      case 'Min':
        return _extractMin(reader);
      case 'Max':
        return _extractMax(reader);
      case 'MultipleOf':
        return _extractMultipleOf(reader);
      case 'MinItems':
        return _extractMinItems(reader);
      case 'MaxItems':
        return _extractMaxItems(reader);
      case 'UniqueItems':
        return PropertyConstraintInfo(
          constraintKey: 'uniqueItems',
          parameters: {},
        );
      case 'Description':
        return _extractDescription(reader);
      case 'FieldType':
        return _extractFieldType(reader);
      default:
        return null;
    }
  }

  /// Extract all constraints from a list of annotations
  static List<PropertyConstraintInfo> extractAllConstraints(
    List<ElementAnnotation> annotations,
  ) {
    final constraints = <PropertyConstraintInfo>[];
    
    for (final annotation in annotations) {
      final constraint = extractConstraint(annotation);
      if (constraint != null) {
        constraints.add(constraint);
      }
    }
    
    return constraints;
  }

  static PropertyConstraintInfo _extractMinLength(ConstantReader reader) {
    final length = reader.peek('length')?.intValue ?? 0;
    return PropertyConstraintInfo(
      constraintKey: 'minLength',
      parameters: {'length': length},
    );
  }

  static PropertyConstraintInfo _extractMaxLength(ConstantReader reader) {
    final length = reader.peek('length')?.intValue ?? 0;
    return PropertyConstraintInfo(
      constraintKey: 'maxLength',
      parameters: {'length': length},
    );
  }

  static PropertyConstraintInfo _extractPattern(ConstantReader reader) {
    final pattern = reader.peek('pattern')?.stringValue ?? '';
    return PropertyConstraintInfo(
      constraintKey: 'pattern',
      parameters: {'pattern': pattern},
    );
  }

  static PropertyConstraintInfo _extractEnumValues(ConstantReader reader) {
    final listReader = reader.peek('values');
    final values = <String>[];
    if (listReader != null && listReader.isList) {
      for (final value in listReader.listValue) {
        final stringValue = ConstantReader(value).stringValue;
        values.add(stringValue);
      }
    }
    return PropertyConstraintInfo(
      constraintKey: 'enumValues',
      parameters: {'values': values},
    );
  }

  static PropertyConstraintInfo _extractMin(ConstantReader reader) {
    final valueReader = reader.peek('value');
    final value = valueReader?.isInt == true
        ? valueReader!.intValue.toDouble()
        : valueReader?.doubleValue ?? 0;

    return PropertyConstraintInfo(
      constraintKey: 'min',
      parameters: {'value': value},
    );
  }

  static PropertyConstraintInfo _extractMax(ConstantReader reader) {
    final valueReader = reader.peek('value');
    final value = valueReader?.isInt == true
        ? valueReader!.intValue.toDouble()
        : valueReader?.doubleValue ?? 0;

    return PropertyConstraintInfo(
      constraintKey: 'max',
      parameters: {'value': value},
    );
  }

  static PropertyConstraintInfo _extractMultipleOf(ConstantReader reader) {
    final value = reader.peek('value')?.doubleValue ?? 0;
    return PropertyConstraintInfo(
      constraintKey: 'multipleOf',
      parameters: {'value': value},
    );
  }

  static PropertyConstraintInfo _extractMinItems(ConstantReader reader) {
    final count = reader.peek('count')?.intValue ?? 0;
    return PropertyConstraintInfo(
      constraintKey: 'minItems',
      parameters: {'count': count},
    );
  }

  static PropertyConstraintInfo _extractMaxItems(ConstantReader reader) {
    final count = reader.peek('count')?.intValue ?? 0;
    return PropertyConstraintInfo(
      constraintKey: 'maxItems',
      parameters: {'count': count},
    );
  }

  static PropertyConstraintInfo _extractDescription(ConstantReader reader) {
    final text = reader.peek('text')?.stringValue ?? '';
    return PropertyConstraintInfo(
      constraintKey: 'description',
      parameters: {'text': text},
    );
  }

  static PropertyConstraintInfo _extractFieldType(ConstantReader reader) {
    final typeStr = reader.peek('type')?.typeValue.toString() ?? '';
    return PropertyConstraintInfo(
      constraintKey: 'fieldType',
      parameters: {'type': typeStr},
    );
  }

  /// Check if a constraint affects the required status
  static bool isRequiredConstraint(PropertyConstraintInfo constraint) {
    return constraint is RequiredConstraint ||
        constraint.constraintKey == 'required';
  }

  /// Check if a constraint affects the nullable status
  static bool isNullableConstraint(PropertyConstraintInfo constraint) {
    return constraint is NullableConstraint ||
        constraint.constraintKey == 'nullable';
  }
}

/// Information about a property constraint
class PropertyConstraintInfo {
  final String constraintKey;
  final Map<String, Object?> parameters;

  const PropertyConstraintInfo({
    required this.constraintKey,
    required this.parameters,
  });

  @override
  String toString() => 'PropertyConstraintInfo($constraintKey: $parameters)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyConstraintInfo &&
          runtimeType == other.runtimeType &&
          constraintKey == other.constraintKey &&
          _mapEquals(parameters, other.parameters);

  @override
  int get hashCode => constraintKey.hashCode ^ parameters.hashCode;

  bool _mapEquals(Map<String, Object?> a, Map<String, Object?> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Required constraint implementation
class RequiredConstraint extends PropertyConstraintInfo {
  RequiredConstraint() : super(constraintKey: 'required', parameters: {});
}

/// Nullable constraint implementation  
class NullableConstraint extends PropertyConstraintInfo {
  NullableConstraint() : super(constraintKey: 'nullable', parameters: {});
}
