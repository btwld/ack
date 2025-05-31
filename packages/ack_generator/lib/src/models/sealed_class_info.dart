import 'package:analyzer/dart/element/element.dart';

/// Information about a sealed class and its discriminated union structure
class SealedClassInfo {
  /// The sealed class element
  final ClassElement sealedClass;

  /// List of subclass elements that extend the sealed class
  final List<ClassElement> subclasses;

  /// Mapping from discriminator values to their corresponding subclass elements
  final Map<String, ClassElement> discriminatorMapping;

  /// The discriminator key field name (e.g., 'type')
  final String discriminatorKey;

  const SealedClassInfo({
    required this.sealedClass,
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
  String toString() => 'SealedClassInfo(${sealedClass.name}, '
      'subclasses: ${subclasses.length}, '
      'discriminatorKey: $discriminatorKey, '
      'values: ${discriminatorValues.join(', ')})';
}
