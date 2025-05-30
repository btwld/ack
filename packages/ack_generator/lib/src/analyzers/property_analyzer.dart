import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';

import '../models/property_info.dart';
import 'constraint_analyzer.dart';
import 'type_analyzer.dart';

/// Information about a parameter's required and nullable status
class ParameterInfo {
  final bool isRequired;
  final bool isNullable;

  const ParameterInfo({
    required this.isRequired,
    required this.isNullable,
  });
}

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

    // Create initial property info
    PropertyInfo property = PropertyInfo(
      name: field.name,
      typeName: typeName,
      isNullable: isNullableField,
      isRequired: false,
      constraints: [],
    );

    // Analyze constructor parameter relationship
    if (constructor != null) {
      final parameterInfo = _analyzeParameterFieldRelationship(
        field,
        constructor,
        constructorParam,
      );

      if (parameterInfo != null) {
        property.isRequired = parameterInfo.isRequired;

        // If field is not nullable but constructor param is, prefer the field
        if (!isNullableField && parameterInfo.isNullable) {
          property.isNullable = false;
        } else if (isNullableField && !parameterInfo.isNullable) {
          // Field is nullable but parameter is not - keep field nullability
          property.isNullable = true;
        } else {
          property.isNullable = parameterInfo.isNullable;
        }
      }
    } else if (constructorParam != null) {
      // Fallback to simple parameter analysis
      property.isRequired = constructorParam.isRequired;

      if (!isNullableField &&
          constructorParam.type.nullabilitySuffix ==
              NullabilitySuffix.question) {
        property.isNullable = false;
      }
    }

    // Extract constraint annotations from field
    final constraints =
        ConstraintAnalyzer.extractAllConstraints(field.metadata);
    property.constraints.addAll(constraints);

    // Apply constraint effects on required/nullable status
    for (final constraint in constraints) {
      if (ConstraintAnalyzer.isRequiredConstraint(constraint)) {
        property.isRequired = true;
      } else if (ConstraintAnalyzer.isNullableConstraint(
        constraint,
      )) {
        property.isNullable = true;
      }
    }

    return property;
  }

  /// Analyze the relationship between a field and constructor parameters
  /// Handles direct parameter mapping, initializer lists, and constructor body assignments
  static ParameterInfo? _analyzeParameterFieldRelationship(
    FieldElement field,
    ConstructorElement constructor,
    ParameterElement? directParam,
  ) {
    final fieldName = field.name;

    // Case 1: Direct parameter mapping (required this.field)
    if (directParam != null) {
      return ParameterInfo(
        isRequired: directParam.isRequired,
        isNullable:
            directParam.type.nullabilitySuffix == NullabilitySuffix.question,
      );
    }

    // Case 2 & 3: Initializer list or constructor body assignments
    // We need to analyze the constructor's AST to find parameter assignments
    final constructorNode = constructor.declaration;
    if (constructorNode is ConstructorDeclaration) {
      // Check initializer list first
      final initializerParam = _findParameterInInitializers(
        constructorNode,
        fieldName,
      );
      if (initializerParam != null) {
        final param = _findParameterByName(constructor, initializerParam);
        if (param != null) {
          return ParameterInfo(
            isRequired: param.isRequired,
            isNullable:
                param.type.nullabilitySuffix == NullabilitySuffix.question,
          );
        }
      }

      // Check constructor body assignments
      final bodyParam = _findParameterInConstructorBody(
        constructorNode,
        fieldName,
      );
      if (bodyParam != null) {
        final param = _findParameterByName(constructor, bodyParam);
        if (param != null) {
          return ParameterInfo(
            isRequired: param.isRequired,
            isNullable:
                param.type.nullabilitySuffix == NullabilitySuffix.question,
          );
        }
      }
    }

    return null;
  }

  /// Find parameter name used in initializer list for a specific field
  static String? _findParameterInInitializers(
    ConstructorDeclaration constructor,
    String fieldName,
  ) {
    for (final initializer in constructor.initializers) {
      if (initializer is ConstructorFieldInitializer) {
        if (initializer.fieldName.name == fieldName) {
          // Extract parameter name from the assignment expression
          final expression = initializer.expression;
          if (expression is SimpleIdentifier) {
            return expression.name;
          }
        }
      }
    }
    return null;
  }

  /// Find parameter name used in constructor body for a specific field
  static String? _findParameterInConstructorBody(
    ConstructorDeclaration constructor,
    String fieldName,
  ) {
    final body = constructor.body;
    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        if (statement is ExpressionStatement) {
          final expression = statement.expression;
          if (expression is AssignmentExpression) {
            final leftSide = expression.leftHandSide;
            final rightSide = expression.rightHandSide;

            // Check if this is an assignment to our field
            if (leftSide is SimpleIdentifier && leftSide.name == fieldName) {
              // Extract parameter name from right side
              if (rightSide is SimpleIdentifier) {
                return rightSide.name;
              }
            }
          }
        }
      }
    }
    return null;
  }

  /// Find a parameter element by name in the constructor
  static ParameterElement? _findParameterByName(
    ConstructorElement constructor,
    String parameterName,
  ) {
    for (final param in constructor.parameters) {
      if (param.name == parameterName) {
        return param;
      }
    }
    return null;
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
