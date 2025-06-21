import 'package:analyzer/dart/element/type.dart';
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
  bool get isNestedSchema => !isPrimitive && !isList && !isMap;

  /// Whether this is a primitive type
  bool get isPrimitive {
    // Check if it's a built-in Dart type
    return type.isDartCoreString ||
        type.isDartCoreInt ||
        type.isDartCoreDouble ||
        type.isDartCoreBool ||
        type.isDartCoreNum;
  }

  /// Whether this is a List type
  bool get isList => type.isDartCoreList;

  /// Whether this is a Map type  
  bool get isMap => type.isDartCoreMap;
}
