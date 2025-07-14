import 'package:analyzer/dart/element/type.dart';

import '../models/constraint_info.dart';
import '../models/field_info.dart';
import '../models/model_info.dart';

/// Builds field schema expressions
class FieldBuilder {
  String buildFieldSchema(FieldInfo field, [ModelInfo? model]) {
    // Check if this field is a discriminator field in a subtype
    if (model != null &&
        model.isDiscriminatedSubtype &&
        model.discriminatorKey != null &&
        field.name == model.discriminatorKey) {
      // Generate Ack.literal() for discriminator field
      return 'Ack.literal(\'${model.discriminatorValue}\')';
    }

    String schema;

    if (field.isPrimitive) {
      schema = _buildPrimitiveSchema(field);
    } else if (field.isEnum) {
      schema = _buildEnumSchema(field);
    } else if (field.isGeneric) {
      schema = _buildGenericSchema(field);
    } else if (field.isList) {
      schema = _buildListSchema(field);
    } else if (field.isMap) {
      schema = _buildMapSchema(field);
    } else if (field.isSet) {
      schema = _buildSetSchema(field);
    } else {
      schema = _buildNestedSchema(field);
    }

    // Apply constraints
    for (final constraint in field.constraints) {
      schema = _applyConstraint(schema, constraint);
    }

    // Apply optional if field is not required
    if (!field.isRequired) {
      schema = '$schema.optional()';
    }

    // Apply nullable if field is nullable
    if (field.isNullable) {
      schema = '$schema.nullable()';
    }

    return schema;
  }

  String _buildPrimitiveSchema(FieldInfo field) {
    if (field.type.isDartCoreString) {
      return 'Ack.string()';
    } else if (field.type.isDartCoreInt) {
      return 'Ack.integer()';
    } else if (field.type.isDartCoreDouble) {
      return 'Ack.double()';
    } else if (field.type.isDartCoreBool) {
      return 'Ack.boolean()';
    } else if (field.type.isDartCoreNum) {
      return 'Ack.double()'; // Map num to double
    } else {
      throw UnsupportedError(
          'Unsupported primitive type: ${field.type.getDisplayString()}');
    }
  }

  String _buildListSchema(FieldInfo field) {
    // Use the DartType API instead of string parsing
    final listType = field.type;

    if (listType is ParameterizedType && listType.typeArguments.isNotEmpty) {
      final itemType = listType.typeArguments[0];
      final itemSchema = _buildSchemaForType(itemType);
      return 'Ack.list($itemSchema)';
    }

    // Fallback for untyped lists
    return 'Ack.list(Ack.any())';
  }

  String _buildMapSchema(FieldInfo field) {
    // Extract map value type using DartType API
    final mapType = field.type;

    // Try to get type arguments from the DartType
    if (mapType is ParameterizedType && mapType.typeArguments.length == 2) {
      final keyType = mapType.typeArguments[0];

      // Verify key type is String (required for JSON)
      if (!keyType.isDartCoreString) {
        throw UnsupportedError(
            'Map keys must be String for JSON serialization. Found: ${keyType.getDisplayString()}');
      }

      // Use object with additionalProperties for all Maps
      return 'Ack.object({}, additionalProperties: true)';
    }

    // Fallback for untyped maps
    return 'Ack.object({}, additionalProperties: true)';
  }

  String _buildSetSchema(FieldInfo field) {
    // Sets are serialized as arrays with unique constraint
    // Extract set element type using DartType API
    final setType = field.type;

    if (setType is ParameterizedType && setType.typeArguments.isNotEmpty) {
      final elementType = setType.typeArguments[0];
      final elementSchema = _buildSchemaForType(elementType);
      return 'Ack.list($elementSchema).unique()';
    }

    // Fallback for untyped sets
    return 'Ack.list(Ack.any()).unique()';
  }

  String _buildSchemaForType(DartType type) {
    // Helper method to build schema for any DartType
    if (type.isDartCoreString) {
      return 'Ack.string()';
    } else if (type.isDartCoreInt) {
      return 'Ack.integer()';
    } else if (type.isDartCoreDouble) {
      return 'Ack.double()';
    } else if (type.isDartCoreBool) {
      return 'Ack.boolean()';
    } else if (type.isDartCoreNum) {
      return 'Ack.double()'; // Map num to double
    } else if (type.toString() == 'dynamic' || type.isDartCoreObject) {
      return 'Ack.any()';
    } else if (type is TypeParameterType) {
      // Generic type parameter
      return 'Ack.any()';
    } else if (type.isDartCoreList) {
      // Nested list
      if (type is ParameterizedType && type.typeArguments.isNotEmpty) {
        final itemType = type.typeArguments[0];
        return 'Ack.list(${_buildSchemaForType(itemType)})';
      }
      return 'Ack.list(Ack.any())';
    } else if (type.isDartCoreMap) {
      // Nested map - use object with additionalProperties
      return 'Ack.object({}, additionalProperties: true)';
    } else if (type.isDartCoreSet) {
      // Nested set
      if (type is ParameterizedType && type.typeArguments.isNotEmpty) {
        final elementType = type.typeArguments[0];
        return 'Ack.list(${_buildSchemaForType(elementType)}).unique()';
      }
      return 'Ack.list(Ack.any()).unique()';
    } else {
      // Assume it's a custom schema model - reference as a variable
      final typeName = type.getDisplayString().replaceAll('?', '');
      final camelCaseName =
          '${typeName[0].toLowerCase()}${typeName.substring(1)}';
      return '${camelCaseName}Schema';
    }
  }

  String _buildNestedSchema(FieldInfo field) {
    final typeName = field.type.getDisplayString();
    final baseType = typeName.replaceAll('?', '');
    final camelCaseName =
        '${baseType[0].toLowerCase()}${baseType.substring(1)}';
    return '${camelCaseName}Schema';
  }

  String _buildEnumSchema(FieldInfo field) {
    final enumValues = field.enumValues;
    if (enumValues.isEmpty) {
      throw UnsupportedError(
          'Enum ${field.type.getDisplayString()} has no values');
    }

    // Generate enum schema with string values
    final valueList = enumValues.map((value) => "'$value'").join(', ');

    return 'Ack.string().enumString([$valueList])';
  }

  String _buildGenericSchema(FieldInfo field) {
    // Generic types are treated as dynamic/any since we can't know the actual type at generation time
    return 'Ack.any()';
  }

  String _applyConstraint(String schema, ConstraintInfo constraint) {
    switch (constraint.name) {
      // STRING LENGTH CONSTRAINTS
      case 'minLength':
        return '$schema.minLength(${constraint.arguments.first})';
      case 'maxLength':
        return '$schema.maxLength(${constraint.arguments.first})';
      case 'notEmpty':
        return '$schema.notEmpty()';

      // STRING FORMAT CONSTRAINTS
      case 'email':
        return '$schema.email()';
      case 'url':
        return '$schema.url()';

      // STRING PATTERN CONSTRAINTS
      case 'matches':
        return '$schema.matches(r\'${constraint.arguments.first}\')';

      // NUMERIC CONSTRAINTS
      case 'min':
        return '$schema.min(${constraint.arguments.first})';
      case 'max':
        return '$schema.max(${constraint.arguments.first})';
      case 'positive':
        return '$schema.positive()';
      case 'multipleOf':
        return '$schema.multipleOf(${constraint.arguments.first})';

      // LIST CONSTRAINTS
      case 'minItems':
        return '$schema.minItems(${constraint.arguments.first})';
      case 'maxItems':
        return '$schema.maxItems(${constraint.arguments.first})';

      // ENUM CONSTRAINTS
      case 'enumString':
        final values = constraint.arguments.map((v) => "'$v'").join(', ');
        return '$schema.enumString([$values])';

      // LEGACY SUPPORT
      case 'pattern':
        return '$schema.matches(r\'${constraint.arguments.first}\')';
      case 'enumFromType':
        return schema;

      default:
        // Unknown constraint, ignore for now
        return schema;
    }
  }
}
