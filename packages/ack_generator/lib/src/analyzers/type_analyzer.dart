import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import '../models/type_name.dart';

/// Analyzes Dart types and provides utilities for type information
class TypeAnalyzer {
  /// Get a TypeName from a DartType
  static TypeName getTypeName(DartType type) {
    final name = _getSimpleTypeName(type);
    final typeArguments = <TypeName>[];

    if (type is InterfaceType) {
      for (final argType in type.typeArguments) {
        typeArguments.add(getTypeName(argType));
      }
    }

    return TypeName(name, typeArguments);
  }

  /// Get a simple type name from a DartType
  static String _getSimpleTypeName(DartType type) {
    if (type is InterfaceType) {
      return type.element.name;
    }
    // Use toString() as a fallback to avoid deprecated parameter issues
    return type.toString();
  }

  /// Get a string representation of a type
  static String getTypeString(TypeName typeName) {
    final name = typeName.name;

    if (typeName.typeArguments.isEmpty) {
      return name;
    }

    final typeArgs = typeName.typeArguments
        .map((t) => getTypeString(t))
        .join(', ');

    return '$name<$typeArgs>';
  }

  /// Check if a type is nullable
  static bool isNullable(DartType type) {
    return type.nullabilitySuffix == NullabilitySuffix.question;
  }

  /// Check if a type is a primitive (not a custom model)
  static bool isPrimitiveType(TypeName typeName) {
    final typeStr = typeName.name;
    return typeStr == 'String' ||
        typeStr == 'int' ||
        typeStr == 'double' ||
        typeStr == 'bool' ||
        typeStr == 'List' ||
        typeStr == 'Map';
  }

  /// Check if a list type contains primitive types
  static bool isPrimitiveListType(TypeName typeName) {
    if (typeName.name != 'List' || typeName.typeArguments.isEmpty) {
      return true;
    }

    final itemType = typeName.typeArguments[0].name;
    return itemType == 'String' ||
        itemType == 'int' ||
        itemType == 'double' ||
        itemType == 'bool' ||
        itemType == 'num';
  }

  /// Get the base schema type for a property type
  static String getBaseSchemaType(TypeName typeName) {
    final typeStr = typeName.name;

    if (typeStr == 'String') {
      return 'Ack.string';
    } else if (typeStr == 'int') {
      return 'Ack.int';
    } else if (typeStr == 'double') {
      return 'Ack.double';
    } else if (typeStr == 'bool') {
      return 'Ack.boolean';
    } else if (typeStr == 'List') {
      // For lists, extract item type if possible
      final itemType =
          typeName.typeArguments.isNotEmpty
              ? getBaseSchemaType(typeName.typeArguments[0])
              : 'Ack.string';
      return 'Ack.list($itemType)';
    } else if (typeStr == 'Map') {
      // Default handling for Map
      return 'Ack.object({}, additionalProperties: true)';
    }
    // For custom types, reference their schema
    return '${typeStr}Schema.schema';
  }
}
