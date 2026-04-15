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

  /// Computed property: returns list of required field JSON keys
  List<String> get requiredFields =>
      fields.where((f) => f.isRequired).map((f) => f.jsonKey).toList();

  /// Field name for discrimination.
  ///
  /// This is set on declared discriminated bases and may also be propagated
  /// to linked schema-variable subtypes.
  final String? discriminatorKey;

  /// This class's discriminator value (only for subtypes)
  final String? discriminatorValue;

  /// Map of discriminator values to subtype schema declarations.
  final Map<String, String>? subtypeNames;

  /// Canonical schema declaration identity.
  final String? schemaIdentity;

  /// Parent discriminated base class name for subtypes.
  final String? discriminatedBaseClassName;

  /// Computed property: Whether this model has a discriminator key.
  ///
  /// This may be true for linked schema-variable subtypes.
  bool get isDiscriminatedBase => discriminatorKey != null;

  /// Computed property: Whether this model is a declared discriminated base.
  bool get isDiscriminatedBaseDefinition =>
      discriminatorKey != null && subtypeNames != null;

  /// Computed property: Whether this class is a discriminated subtype (has discriminatedValue)
  bool get isDiscriminatedSubtype => discriminatorValue != null;

  /// Representation type for extension type (e.g., `String`, `int`, `Map<String, Object?>`)
  final String representationType;

  /// Whether the schema declaration is nullable via `.nullable()`.
  final bool isNullableSchema;

  const ModelInfo({
    required this.className,
    required this.schemaClassName,
    this.description,
    required this.fields,
    this.additionalProperties = false,
    this.discriminatorKey,
    this.discriminatorValue,
    this.subtypeNames,
    this.schemaIdentity,
    this.discriminatedBaseClassName,
    this.representationType = kMapType,
    this.isNullableSchema = false,
  });
}
