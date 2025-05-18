import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import 'constraint_analyzer.dart';
import 'type_analyzer.dart';

/// Analyzes properties and extracts property information
class PropertyAnalyzer {
  /// Analyze a field element and extract property information
  static PropertyInfo analyzeField(
    FieldElement field, {
    ParameterElement? constructorParam,
  }) {
    // Determine type and nullability from field declaration
    final fieldType = field.type;
    final isNullableField =
        fieldType.nullabilitySuffix == NullabilitySuffix.question;
    final typeName = TypeAnalyzer.getTypeName(fieldType);

    // Create initial property info
    PropertyInfo property = PropertyInfo(
      name: field.name,
      typeName: typeName,
      isNullable: isNullableField,
      isRequired: false,
      constraints: [],
    );

    // If there's a constructor parameter, check its nullability and required status
    if (constructorParam != null) {
      final isRequiredParam = constructorParam.isRequired;

      // Update required status from constructor
      property.isRequired = isRequiredParam;

      // If field is not nullable but constructor param is, prefer the field
      if (!isNullableField && property.isNullable) {
        property.isNullable = false;
      }
    }

    // Extract constraint annotations from field
    final constraints = ConstraintAnalyzer.extractAllConstraints(field.metadata);
    property.constraints.addAll(constraints);

    // Apply constraint effects on required/nullable status
    for (final constraint in constraints) {
      if (ConstraintAnalyzer.isRequiredConstraint(constraint)) {
        property.isRequired = true;
      } else if (ConstraintAnalyzer.isNullableConstraint(constraint)) {
        property.isNullable = true;
      }
    }

    return property;
  }

  /// Analyze a constructor parameter and create property information
  static PropertyInfo analyzeConstructorParameter(ParameterElement param) {
    final paramName = param.name;
    final isRequired = param.isRequired;
    final isNullable =
        param.type.nullabilitySuffix == NullabilitySuffix.question;
    final typeName = TypeAnalyzer.getTypeName(param.type);

    return PropertyInfo(
      name: paramName,
      typeName: typeName,
      isRequired: isRequired,
      isNullable: isNullable,
      constraints: [],
    );
  }

  /// Check if a field should be excluded from analysis
  static bool shouldExcludeField(
    FieldElement field,
    String? additionalPropertiesField,
  ) {
    // Skip static fields, private fields, and the additionalProperties field
    return field.isStatic ||
        field.name.startsWith('_') ||
        field.name == additionalPropertiesField;
  }

  /// Find model dependencies for a property
  static Set<String> findPropertyDependencies(PropertyInfo property) {
    final dependencies = <String>{};
    final typeStr = property.typeName.name;

    // Skip primitive types and collections
    if (!TypeAnalyzer.isPrimitiveType(property.typeName)) {
      dependencies.add(typeStr);
    }

    // For list types with model items
    if (typeStr == 'List' && property.typeName.typeArguments.isNotEmpty) {
      final itemType = property.typeName.typeArguments[0].name;
      if (itemType != 'String' &&
          itemType != 'int' &&
          itemType != 'double' &&
          itemType != 'bool') {
        dependencies.add(itemType);
      }
    }

    return dependencies;
  }

  /// Check if a property needs custom conversion logic for models
  static bool needsCustomConversion(PropertyInfo property) {
    // For nested model types
    if (!TypeAnalyzer.isPrimitiveType(property.typeName)) {
      return true;
    }

    // For list types with models
    final typeStr = TypeAnalyzer.getTypeString(property.typeName);
    if (typeStr.startsWith('List<') &&
        !TypeAnalyzer.isPrimitiveListType(property.typeName)) {
      return true;
    }

    return false;
  }
}

/// Information about a property including its constraints
class PropertyInfo {
  final String name;
  final TypeName typeName;
  bool isRequired;
  bool isNullable;
  final List<PropertyConstraintInfo> constraints;

  PropertyInfo({
    required this.name,
    required this.typeName,
    this.isRequired = false,
    this.isNullable = false,
    required this.constraints,
  });

  @override
  String toString() => 'PropertyInfo($name: $typeName, '
      'required: $isRequired, nullable: $isNullable, '
      'constraints: ${constraints.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          typeName == other.typeName &&
          isRequired == other.isRequired &&
          isNullable == other.isNullable &&
          _listEquals(constraints, other.constraints);

  @override
  int get hashCode =>
      name.hashCode ^
      typeName.hashCode ^
      isRequired.hashCode ^
      isNullable.hashCode ^
      constraints.hashCode;

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
