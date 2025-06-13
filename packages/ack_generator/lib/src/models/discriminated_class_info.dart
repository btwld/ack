import 'package:analyzer/dart/element/element.dart';

/// Information about a class (sealed or abstract) and its discriminated union structure
class DiscriminatedClassInfo {
  /// The base class element (sealed or abstract)
  final ClassElement baseClass;

  /// List of subclass elements that extend the base class
  final List<ClassElement> subclasses;

  /// Mapping from discriminator values to their corresponding subclass elements
  final Map<String, ClassElement> discriminatorMapping;

  /// The discriminator key field name (e.g., 'type')
  final String discriminatorKey;

  const DiscriminatedClassInfo({
    required this.baseClass,
    required this.subclasses,
    required this.discriminatorMapping,
    required this.discriminatorKey,
  });

  /// Get all discriminator values
  List<String> get discriminatorValues => discriminatorMapping.keys.toList();

  /// Check if a discriminator value exists
  bool hasDiscriminatorValue(String value) =>
      discriminatorMapping.containsKey(value);

  /// Get subclass for a discriminator value
  ClassElement? getSubclassForValue(String value) =>
      discriminatorMapping[value];

  @override
  String toString() => 'DiscriminatedClassInfo(${baseClass.name}, '
      'subclasses: ${subclasses.length}, '
      'discriminatorKey: $discriminatorKey, '
      'values: ${discriminatorValues.join(', ')})';
}
