import 'property_constraint_info.dart';
import 'type_name.dart';

/// Information about a property in a class
class PropertyInfo {
  final String name;
  final String? jsonKey;
  final TypeName typeName;
  bool isRequired;
  bool isNullable;
  final List<PropertyConstraintInfo> constraints;

  PropertyInfo({
    required this.name,
    this.jsonKey,
    required this.typeName,
    this.isRequired = false,
    this.isNullable = false,
    required this.constraints,
  });

  @override
  String toString() => 'PropertyInfo($name: $typeName, '
      'jsonKey: $jsonKey, required: $isRequired, nullable: $isNullable, '
      'constraints: ${constraints.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          jsonKey == other.jsonKey &&
          typeName == other.typeName &&
          isRequired == other.isRequired &&
          isNullable == other.isNullable &&
          _listEquals(constraints, other.constraints);

  @override
  int get hashCode =>
      name.hashCode ^
      jsonKey.hashCode ^
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
