import 'package:analyzer/dart/element/type.dart';

import '../models/constraint_info.dart';
import '../models/field_info.dart';
import '../models/model_info.dart';

/// Builds field schema expressions
class FieldBuilder {
  // Centralized type-to-schema mapping
  static const _primitiveSchemas = {
    'String': 'Ack.string()',
    'int': 'Ack.integer()',
    'double': 'Ack.double()',
    'bool': 'Ack.boolean()',
    'num': 'Ack.double()',
  };

  static const _specialTypeSchemas = {
    'DateTime': 'Ack.string().datetime()',
    'Duration': 'Ack.integer()',
    'Uri': 'Ack.string().uri()',
  };

  // Constraint application registry
  static final _constraints = {
    'minLength': (schema, args) => '$schema.minLength(${args[0]})',
    'maxLength': (schema, args) => '$schema.maxLength(${args[0]})',
    'notEmpty': (schema, args) => '$schema.notEmpty()',
    'email': (schema, args) => '$schema.email()',
    'url': (schema, args) => '$schema.url()',
    // Use triple quotes to handle all regex edge cases (including single quotes)
    'matches': (schema, args) => "$schema.matches(r'''${args[0]}''')",
    'min': (schema, args) => '$schema.min(${args[0]})',
    'max': (schema, args) => '$schema.max(${args[0]})',
    'positive': (schema, args) => '$schema.positive()',
    'multipleOf': (schema, args) => '$schema.multipleOf(${args[0]})',
    'minItems': (schema, args) => '$schema.minItems(${args[0]})',
    'maxItems': (schema, args) => '$schema.maxItems(${args[0]})',
    'enumString': (schema, args) {
      final values = args.map((v) => "'$v'").join(', ');
      return '$schema.enumString([$values])';
    },
    // Use triple quotes for pattern as well
    'pattern': (schema, args) => "$schema.matches(r'''${args[0]}''')",
    'enumFromType': (schema, args) => schema,
  };

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
      schema = _buildSchemaForType(field.type);
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
      // Nested schema reference (custom type with its own schema)
      schema = _buildSchemaForType(field.type);
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
      // Use object with additionalProperties for all Maps
      // Note: Non-String map keys will fail at runtime during JSON serialization,
      // which is acceptable behavior - the generator should not prevent code generation
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
    final typeName = type.getDisplayString().replaceAll('?', '');

    // Check primitives via registry (use simple string matching)
    if (_primitiveSchemas.containsKey(typeName)) {
      return _primitiveSchemas[typeName]!;
    }

    // Check special types via registry
    for (final entry in _specialTypeSchemas.entries) {
      if (_isDartCoreType(type, entry.key)) {
        return entry.value;
      }
    }

    // Dynamic/Object
    if (type.toString() == 'dynamic' || type.isDartCoreObject) {
      return 'Ack.any()';
    }

    // Generic type parameter
    if (type is TypeParameterType) {
      return 'Ack.any()';
    }

    // Collections (recursive)
    if (type.isDartCoreList) {
      if (type is ParameterizedType && type.typeArguments.isNotEmpty) {
        return 'Ack.list(${_buildSchemaForType(type.typeArguments[0])})';
      }
      return 'Ack.list(Ack.any())';
    }

    if (type.isDartCoreMap) {
      return 'Ack.object({}, additionalProperties: true)';
    }

    if (type.isDartCoreSet) {
      if (type is ParameterizedType && type.typeArguments.isNotEmpty) {
        return 'Ack.list(${_buildSchemaForType(type.typeArguments[0])}).unique()';
      }
      return 'Ack.list(Ack.any()).unique()';
    }

    // Custom schema reference
    return '${typeName[0].toLowerCase()}${typeName.substring(1)}Schema';
  }

  /// Checks if a type is a specific dart:core type by name
  bool _isDartCoreType(DartType type, String typeName) {
    final element = type.element;
    return element?.name == typeName && element?.library?.name == 'dart.core';
  }

  String _buildEnumSchema(FieldInfo field) {
    final enumValues = field.enumValues;
    if (enumValues.isEmpty) {
      throw UnsupportedError(
        'Enum ${field.type.getDisplayString()} has no values',
      );
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
    final generator = _constraints[constraint.name];
    if (generator != null) {
      return generator(schema, constraint.arguments);
    }

    // Unknown constraint - silently ignore (allows custom extensions)
    // The Dart compiler will catch method-not-found errors if constraint is a typo
    return schema;
  }
}
