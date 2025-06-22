import 'package:meta/meta_meta.dart';

/// Annotation to mark a class for schema generation
@Target({TargetKind.classType})
class AckModel {
  /// Optional custom schema class name
  final String? schemaName;

  /// Optional description for the schema
  final String? description;

  /// Whether to allow additional properties not defined in the schema
  final bool additionalProperties;

  /// The name of the field that should store additional properties
  /// Must be a `Map<String, dynamic>` field in your class
  final String? additionalPropertiesField;

  const AckModel({
    this.schemaName,
    this.description,
    this.additionalProperties = false,
    this.additionalPropertiesField,
  });
}
