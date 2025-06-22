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

  const ModelInfo({
    required this.className,
    required this.schemaClassName,
    this.description,
    required this.fields,
    required this.requiredFields,
    this.hasDiscriminator = false,
    this.additionalProperties = false,
    this.additionalPropertiesField,
  });
}
