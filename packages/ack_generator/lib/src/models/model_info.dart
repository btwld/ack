import 'package:analyzer/dart/element/element.dart';
import 'field_info.dart';

/// Information about an annotated model class
class ModelInfo {
  final String className;
  final String schemaClassName;
  final String? description;
  final List<FieldInfo> fields;
  final List<String> requiredFields;
  final bool hasDiscriminator;
  final bool additionalProperties;
  final String? additionalPropertiesField;
  final bool model;

  // New discriminated type properties
  /// Whether this class is a discriminated base class (has discriminatedKey)
  final bool isDiscriminatedBase;
  
  /// Whether this class is a discriminated subtype (has discriminatedValue)
  final bool isDiscriminatedSubtype;
  
  /// Field name for discrimination (only for base classes)
  final String? discriminatorKey;
  
  /// This class's discriminator value (only for subtypes)
  final String? discriminatorValue;
  
  /// Map of discriminator values to class elements (only for base classes)
  final Map<String, ClassElement>? subtypes;

  const ModelInfo({
    required this.className,
    required this.schemaClassName,
    this.description,
    required this.fields,
    required this.requiredFields,
    this.hasDiscriminator = false,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.model = false,
    // New discriminated parameters
    this.isDiscriminatedBase = false,
    this.isDiscriminatedSubtype = false,
    this.discriminatorKey,
    this.discriminatorValue,
    this.subtypes,
  });
}
