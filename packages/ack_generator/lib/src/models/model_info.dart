import 'field_info.dart';

/// Information about an annotated model class
class ModelInfo {
  final String className;
  final String schemaClassName;
  final String? description;
  final List<FieldInfo> fields;
  final List<String> requiredFields;
  final bool hasDiscriminator;

  const ModelInfo({
    required this.className,
    required this.schemaClassName,
    this.description,
    required this.fields,
    required this.requiredFields,
    this.hasDiscriminator = false,
  });
}
