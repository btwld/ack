import 'package:analyzer/dart/element/element2.dart';
import 'field_info.dart';

/// Default representation type for object schemas
const String kMapType = 'Map<String, Object?>';

/// Information about an annotated model class
class ModelInfo {
  final String className;
  final String schemaClassName;
  final String? description;
  final List<FieldInfo> fields;
  final bool additionalProperties;
  final String? additionalPropertiesField;

  /// Computed property: returns list of required field JSON keys
  List<String> get requiredFields =>
      fields.where((f) => f.isRequired).map((f) => f.jsonKey).toList();

  // New discriminated type properties
  /// Field name for discrimination (only for base classes)
  final String? discriminatorKey;

  /// This class's discriminator value (only for subtypes)
  final String? discriminatorValue;

  /// Map of discriminator values to class elements (only for base classes)
  final Map<String, ClassElement2>? subtypes;

  /// Computed property: Whether this class is a discriminated base class (has discriminatedKey)
  bool get isDiscriminatedBase => discriminatorKey != null;

  /// Computed property: Whether this class is a discriminated subtype (has discriminatedValue)
  bool get isDiscriminatedSubtype => discriminatorValue != null;

  /// Whether this ModelInfo was created from a schema variable (not a class)
  final bool isFromSchemaVariable;

  /// Representation type for extension type (e.g., 'String', 'int', 'Map<String, Object?>')
  final String representationType;

  /// Whether the schema variable is nullable via `.nullable()`.
  ///
  /// This only applies to @AckType schema variables (not @AckModel classes).
  final bool isNullableSchema;

  /// Whether an extension type should be generated for this model.
  ///
  /// Extension types are generated for all @AckType schemas.
  /// Object schemas get field getters and copyWith; non-object schemas
  /// still benefit from typed parse/safeParse wrappers and implement
  /// their underlying representation type.
  bool get shouldGenerateExtensionType => true;

  const ModelInfo({
    required this.className,
    required this.schemaClassName,
    this.description,
    required this.fields,
    this.additionalProperties = false,
    this.additionalPropertiesField,
    // New discriminated parameters
    this.discriminatorKey,
    this.discriminatorValue,
    this.subtypes,
    this.isFromSchemaVariable = false,
    this.representationType = kMapType,
    this.isNullableSchema = false,
  });
}
