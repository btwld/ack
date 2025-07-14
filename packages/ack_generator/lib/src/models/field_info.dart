import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element.dart';
import 'constraint_info.dart';

/// Information about a field in the model
class FieldInfo {
  final String name;
  final String jsonKey;
  final DartType type;
  final bool isRequired;
  final bool isNullable;
  final List<ConstraintInfo> constraints;
  final String? defaultValue;
  final String? description;

  const FieldInfo({
    required this.name,
    required this.jsonKey,
    required this.type,
    required this.isRequired,
    required this.isNullable,
    required this.constraints,
    this.defaultValue,
    this.description,
  });

  /// Whether this field references another schema model
  bool get isNestedSchema =>
      !isPrimitive && !isList && !isMap && !isSet && !isEnum && !isGeneric;

  /// Whether this field is a generic type parameter
  bool get isGeneric {
    // Check if this is a type parameter (like T, U, etc.)
    return type is TypeParameterType;
  }

  /// Whether this is a Set type
  bool get isSet => type.isDartCoreSet;

  /// Whether this is a primitive type
  bool get isPrimitive {
    // Check if it's a built-in Dart type
    return type.isDartCoreString ||
        type.isDartCoreInt ||
        type.isDartCoreDouble ||
        type.isDartCoreBool ||
        type.isDartCoreNum;
  }

  /// Whether this field is an enum type
  bool get isEnum {
    final element = type.element;
    if (element == null) return false;

    // Check if this is an enum by looking at the element kind
    return element.kind == ElementKind.ENUM;
  }

  /// Get enum values if this is an enum type
  List<String> get enumValues {
    if (!isEnum) return [];
    final element = type.element;
    if (element == null) return [];

    // For enums, get the enum constants using the analyzer API
    if (element.kind == ElementKind.ENUM) {
      try {
        // Use dynamic access to get fields (handles analyzer API variations)
        final fields = (element as dynamic).fields;
        if (fields != null) {
          final enumConstants = (fields as List)
              .where((field) => field.isEnumConstant == true)
              .map((field) => field.name as String)
              .toList();

          return enumConstants;
        }
      } catch (e) {
        // If there's any issue with the analyzer API, fall back to empty list
        // This maintains backward compatibility with manual @EnumString annotations
        print(
            'Warning: Could not extract enum values for ${element.displayName}: $e');
        return [];
      }
    }

    return [];
  }

  /// Whether this is a List type
  bool get isList => type.isDartCoreList;

  /// Whether this is a Map type
  bool get isMap => type.isDartCoreMap;
}
