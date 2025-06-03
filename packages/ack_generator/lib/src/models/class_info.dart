import 'property_info.dart';

/// Information about a class to be generated
class ClassInfo {
  final String name;
  final Map<String, PropertyInfo> constructorParams;
  final Map<String, PropertyInfo> properties;
  final Set<String> dependencies;

  const ClassInfo({
    required this.name,
    required this.constructorParams,
    required this.properties,
    required this.dependencies,
  });

  /// Get properties excluding a specific field (like additionalProperties)
  Map<String, PropertyInfo> getPropertiesExcluding(String? fieldName) {
    if (fieldName == null) return properties;

    return Map.fromEntries(
      properties.entries.where((entry) => entry.key != fieldName),
    );
  }

  /// Get required properties
  List<PropertyInfo> getRequiredProperties({String? excludeField}) {
    return getPropertiesExcluding(
      excludeField,
    ).values.where((prop) => prop.isRequired).toList();
  }

  /// Update dependencies
  ClassInfo withDependencies(Set<String> newDependencies) {
    return ClassInfo(
      name: name,
      constructorParams: constructorParams,
      properties: properties,
      dependencies: newDependencies,
    );
  }

  @override
  String toString() => 'ClassInfo($name, properties: ${properties.length}, '
      'dependencies: ${dependencies.length})';
}
