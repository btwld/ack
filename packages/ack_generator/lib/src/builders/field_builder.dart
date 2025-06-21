import '../models/field_info.dart';
import '../models/constraint_info.dart';

/// Builds field schema expressions
class FieldBuilder {
  String buildFieldSchema(FieldInfo field) {
    String schema;
    
    if (field.isPrimitive) {
      schema = _buildPrimitiveSchema(field);
    } else if (field.isList) {
      schema = _buildListSchema(field);
    } else if (field.isMap) {
      schema = _buildMapSchema(field);
    } else {
      schema = _buildNestedSchema(field);
    }
    
    // Apply constraints
    for (final constraint in field.constraints) {
      schema = _applyConstraint(schema, constraint);
    }
    
    // Apply nullable if needed
    if (field.isNullable && !field.isRequired) {
      schema = '$schema.nullable()';
    }
    
    return schema;
  }

  String _buildPrimitiveSchema(FieldInfo field) {
    if (field.type.isDartCoreString) {
      return 'Ack.string';
    } else if (field.type.isDartCoreInt) {
      return 'Ack.integer';
    } else if (field.type.isDartCoreDouble) {
      return 'Ack.double';
    } else if (field.type.isDartCoreBool) {
      return 'Ack.boolean';
    } else if (field.type.isDartCoreNum) {
      return 'Ack.number';
    } else {
      throw UnsupportedError(
        'Unsupported primitive type: ${field.type.getDisplayString()}'
      );
    }
  }

  String _buildListSchema(FieldInfo field) {
    // Try to extract the list item type
    final typeStr = field.type.getDisplayString();
    final listMatch = RegExp(r'List<(.+)>').firstMatch(typeStr);
    
    if (listMatch != null) {
      final itemType = listMatch.group(1)!.trim();
      // Remove nullability for type checking
      final baseItemType = itemType.replaceAll('?', '');
      
      // Check if item type is primitive
      if (_isPrimitiveTypeName(baseItemType)) {
        final itemSchema = _buildPrimitiveSchemaForType(baseItemType);
        return 'Ack.list($itemSchema)';
      } else {
        // Nested schema in list
        return 'Ack.list(${baseItemType}Schema().definition)';
      }
    }
    
    // Fallback for untyped lists
    return 'Ack.list(Ack.any)';
  }

  String _buildMapSchema(FieldInfo field) {
    // For now, treat maps as generic objects
    return 'Ack.object({}, additionalProperties: true)';
  }

  String _buildNestedSchema(FieldInfo field) {
    final typeName = field.type.getDisplayString();
    final baseType = typeName.replaceAll('?', '');
    return '${baseType}Schema().definition';
  }

  bool _isPrimitiveTypeName(String typeName) {
    return ['String', 'int', 'double', 'bool', 'num'].contains(typeName);
  }

  String _buildPrimitiveSchemaForType(String typeName) {
    switch (typeName) {
      case 'String':
        return 'Ack.string';
      case 'int':
        return 'Ack.integer';
      case 'double':
        return 'Ack.double';
      case 'num':
        return 'Ack.number';
      case 'bool':
        return 'Ack.boolean';
      default:
        return 'Ack.any';
    }
  }

  String _applyConstraint(String schema, ConstraintInfo constraint) {
    switch (constraint.name) {
      case 'email':
        return '$schema.email()';
      case 'notEmpty':
        return '$schema.notEmpty()';
      case 'minLength':
        return '$schema.minLength(${constraint.arguments.first})';
      case 'maxLength':
        return '$schema.maxLength(${constraint.arguments.first})';
      case 'min':
        return '$schema.min(${constraint.arguments.first})';
      case 'max':
        return '$schema.max(${constraint.arguments.first})';
      case 'positive':
        return '$schema.positive()';
      case 'negative':
        return '$schema.negative()';
      case 'url':
        return '$schema.url()';
      case 'uuid':
        return '$schema.uuid()';
      case 'pattern':
        return '$schema.pattern(${constraint.arguments.first})';
      default:
        // Unknown constraint, ignore for now
        return schema;
    }
  }
}
