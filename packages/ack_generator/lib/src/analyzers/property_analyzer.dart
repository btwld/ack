import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../models/property_info.dart';
import '../utils/dart_mappable_detector.dart';
import 'constraint_analyzer.dart';
import 'type_analyzer.dart';

/// Analyzes properties and extracts property information
class PropertyAnalyzer {
  /// Analyze a field element and extract property information
  static PropertyInfo analyzeField(
    FieldElement field, {
    ParameterElement? constructorParam,
    ConstructorElement? constructor,
  }) {
    // Determine type and nullability from field declaration
    final fieldType = field.type;
    final isNullableField =
        fieldType.nullabilitySuffix == NullabilitySuffix.question;
    final typeName = TypeAnalyzer.getTypeName(fieldType);

    // Find matching constructor parameter for enhanced inference
    final matchingParam =
        constructorParam ?? _findMatchingParameter(field, constructor);

    // Determine required status from constructor parameter
    final isRequired = _inferRequired(field, matchingParam);

    // Determine nullable status from field type and parameter
    final isNullable = _inferNullable(field, matchingParam, isNullableField);

    // Get the class element to check for dart_mappable annotations
    final enclosingElement = field.enclosingElement3;
    if (enclosingElement is! ClassElement) {
      throw ArgumentError(
        'Field "${field.name}" must belong to a class element, '
        'but found ${enclosingElement.runtimeType}',
      );
    }
    final classElement = enclosingElement;

    // Check for dart_mappable field override
    final customKey = DartMappableDetector.getFieldKey(field);

    // Apply case transformation if dart_mappable is present
    final caseStyle = DartMappableDetector.getCaseStyle(classElement);
    final jsonKey = customKey ??
        DartMappableDetector.transformFieldName(field.name, caseStyle);

    // Create property info with jsonKey
    PropertyInfo property = PropertyInfo(
      name: field.name,
      jsonKey: jsonKey == field.name ? null : jsonKey,
      typeName: typeName,
      isRequired: isRequired,
      isNullable: isNullable,
      constraints: [],
    );

    // Extract constraint annotations from field
    final constraints = ConstraintAnalyzer.extractAllConstraints(
      field.metadata,
    );
    property.constraints.addAll(constraints);

    // Apply constraint effects on required/nullable status (annotations override inference)
    for (final constraint in constraints) {
      if (ConstraintAnalyzer.isRequiredConstraint(constraint)) {
        property.isRequired = true;
      } else if (ConstraintAnalyzer.isNullableConstraint(constraint)) {
        property.isNullable = true;
      }
    }

    return property;
  }

  /// Find matching constructor parameter for a field using element-based analysis
  static ParameterElement? _findMatchingParameter(
    FieldElement field,
    ConstructorElement? constructor,
  ) {
    if (constructor == null) return null;

    // Direct match by name (handles: required this.field, this.field)
    for (final param in constructor.parameters) {
      if (param.name == field.name) {
        return param;
      }
    }

    return null;
  }

  /// Infer required status from constructor parameter and annotations
  static bool _inferRequired(
    FieldElement field,
    ParameterElement? matchingParam,
  ) {
    // Check for explicit @IsRequired annotation first
    final hasRequiredAnnotation = field.metadata.any((annotation) {
      final name = annotation.element?.displayName;
      return name == 'IsRequired' || name == 'Required';
    });

    if (hasRequiredAnnotation) {
      return true;
    }

    // Infer from constructor parameter
    return matchingParam?.isRequired ?? false;
  }

  /// Infer nullable status from field type, constructor parameter, and annotations
  static bool _inferNullable(
    FieldElement field,
    ParameterElement? matchingParam,
    bool isNullableField,
  ) {
    // Check for explicit @IsNullable annotation first
    final hasNullableAnnotation = field.metadata.any((annotation) {
      final name = annotation.element?.displayName;
      return name == 'IsNullable' || name == 'Nullable';
    });

    if (hasNullableAnnotation) {
      return true;
    }

    // Field type takes precedence (String? is always nullable)
    if (isNullableField) {
      return true;
    }

    // If field is non-nullable but parameter is nullable, keep field non-nullable
    // This handles cases like: final String name; User({String? userName}) : name = userName ?? '';
    return false;
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
