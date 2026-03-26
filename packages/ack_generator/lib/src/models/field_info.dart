import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:logging/logging.dart';

import 'constraint_info.dart';

/// Logger for field info extraction warnings and diagnostics.
final _log = Logger('FieldInfo');

/// Information about a field in the model
class FieldInfo {
  final String name;
  final String jsonKey;
  final DartType type;
  final bool isRequired;
  final bool isNullable;
  final List<ConstraintInfo> constraints;
  final String? description;
  final String? schemaExpressionOverride;

  /// For list/set fields containing schema variable references (e.g., `Ack.list(addressSchema)`),
  /// this stores the schema variable name so the type builder can generate
  /// properly typed getters like `List<AddressType>`.
  final String? listElementSchemaRef;

  /// For nested object fields that reference another schema variable (e.g., `'address': addressSchema`),
  /// this stores the schema variable name so the type builder can generate
  /// properly typed getters like `AddressType get address`.
  final String? nestedSchemaRef;

  /// Optional display type override used when source qualification matters
  /// (e.g., `alias.UserRole` from a prefixed import).
  final String? displayTypeOverride;

  /// Optional collection element display type override for list/set fields.
  final String? collectionElementDisplayTypeOverride;

  /// Optional cast type override for list/set element wrappers
  /// (for example, `Map<String, Object?>` for object schema references).
  final String? collectionElementCastTypeOverride;

  /// Whether list/set elements should be wrapped as generated extension types.
  final bool collectionElementIsCustomType;

  /// Optional cast type override for nested schema references.
  final String? nestedSchemaCastTypeOverride;

  /// Whether reparsing this field's getter value would re-run a transform.
  ///
  /// Used to suppress generated `copyWith()` on object wrappers whose public
  /// field values no longer match the raw schema input shape.
  final bool isTransformedRepresentation;

  const FieldInfo({
    required this.name,
    required this.jsonKey,
    required this.type,
    required this.isRequired,
    required this.isNullable,
    required this.constraints,
    this.description,
    this.schemaExpressionOverride,
    this.listElementSchemaRef,
    this.nestedSchemaRef,
    this.displayTypeOverride,
    this.collectionElementDisplayTypeOverride,
    this.collectionElementCastTypeOverride,
    this.collectionElementIsCustomType = false,
    this.nestedSchemaCastTypeOverride,
    this.isTransformedRepresentation = false,
  });

  FieldInfo copyWith({
    String? name,
    String? jsonKey,
    DartType? type,
    bool? isRequired,
    bool? isNullable,
    List<ConstraintInfo>? constraints,
    String? description,
    String? schemaExpressionOverride,
    String? listElementSchemaRef,
    String? nestedSchemaRef,
    String? displayTypeOverride,
    String? collectionElementDisplayTypeOverride,
    String? collectionElementCastTypeOverride,
    bool? collectionElementIsCustomType,
    String? nestedSchemaCastTypeOverride,
  }) {
    return FieldInfo(
      name: name ?? this.name,
      jsonKey: jsonKey ?? this.jsonKey,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      isNullable: isNullable ?? this.isNullable,
      constraints: constraints ?? this.constraints,
      description: description ?? this.description,
      schemaExpressionOverride:
          schemaExpressionOverride ?? this.schemaExpressionOverride,
      listElementSchemaRef: listElementSchemaRef ?? this.listElementSchemaRef,
      nestedSchemaRef: nestedSchemaRef ?? this.nestedSchemaRef,
      displayTypeOverride: displayTypeOverride ?? this.displayTypeOverride,
      collectionElementDisplayTypeOverride:
          collectionElementDisplayTypeOverride ??
          this.collectionElementDisplayTypeOverride,
      collectionElementCastTypeOverride:
          collectionElementCastTypeOverride ??
          this.collectionElementCastTypeOverride,
      collectionElementIsCustomType:
          collectionElementIsCustomType ?? this.collectionElementIsCustomType,
      nestedSchemaCastTypeOverride:
          nestedSchemaCastTypeOverride ?? this.nestedSchemaCastTypeOverride,
    );
  }

  /// Whether this field references another schema model
  bool get isNestedSchema =>
      !isPrimitive && !isList && !isMap && !isSet && !isEnum && !isGeneric;

  /// Whether this field is a generic type parameter
  bool get isGeneric {
    // Check if this is a type parameter (like T, U, etc.)
    return type is TypeParameterType;
  }

  /// Whether this is a Set type
  bool get isSet => type.isDartCoreSet;

  /// Whether this is a primitive type
  bool get isPrimitive {
    // Check if it's a built-in Dart type
    return type.isDartCoreString ||
        type.isDartCoreInt ||
        type.isDartCoreDouble ||
        type.isDartCoreBool ||
        type.isDartCoreNum;
  }

  /// Whether this field is an enum type
  bool get isEnum {
    final element = type.element3;
    if (element == null) return false;

    // Check if this is an enum by looking at the element type
    return element is EnumElement2;
  }

  /// Get enum values if this is an enum type
  List<String> get enumValues {
    if (!isEnum) return [];
    final element = type.element3 as EnumElement2;
    try {
      return element.constants2.map((field) => field.name3!).toList();
    } catch (e) {
      _log.warning('Could not extract enum values for ${element.name3}: $e');
      return [];
    }
  }

  /// Whether this is a List type
  bool get isList => type.isDartCoreList;

  /// Whether this is a Map type
  bool get isMap => type.isDartCoreMap;
}
