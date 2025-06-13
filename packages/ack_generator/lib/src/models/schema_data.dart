/// Data class for Schema annotation properties
class SchemaData {
  final String? description;
  final bool additionalProperties;
  final String? additionalPropertiesField;
  final String? schemaClassName;
  final String? discriminatedKey;
  final String? discriminatedValue;

  const SchemaData({
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    this.schemaClassName,
    this.discriminatedKey,
    this.discriminatedValue,
  });
}
