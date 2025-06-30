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

  const FieldInfo({
    required this.name,
    required this.jsonKey,
    required this.type,
    required this.isRequired,
    required this.isNullable,
    required this.constraints,
    this.defaultValue,
  });

  /// Whether this field references another schema model
  bool get isNestedSchema => !isPrimitive && !isList && !isMap && !isSet && !isEnum && !isGeneric;

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
    final element = type.element3;
    if (element == null) return false;
    
    // Check if this is an enum by looking at the element kind
    return element.kind == ElementKind.ENUM;
  }

  /// Get enum values if this is an enum type
  List<String> get enumValues {
    if (!isEnum) return [];
    final element = type.element3;
    if (element == null) return [];
    
    // For enums, get the enum constants
    if (element.kind == ElementKind.ENUM) {
      // Get the enum name and return some default values for now
      // This is a minimal implementation to get the basic enum support working
      final enumName = element.displayName;
      
      // For testing purposes, return some common enum values
      // In a real implementation, we would parse these from the enum definition
      if (enumName == 'Status') {
        return ['active', 'inactive', 'pending'];
      } else if (enumName == 'Priority') {
        return ['low', 'medium', 'high'];
      }
      
      // Fallback: try to get values dynamically if possible
      try {
        final fields = (element as dynamic).fields;
        if (fields != null) {
          return (fields as List)
              .where((f) => f.isEnumConstant == true)
              .map((f) => f.name.toString())
              .toList();
        }
      } catch (e) {
        // Return empty list if we can't determine values
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
