import '../schema.dart';

/// Adds fluent validation methods to [ObjectSchema].
extension ObjectSchemaExtensions on ObjectSchema {
  /// Makes the object schema strict, disallowing any properties not
  /// explicitly defined in the `properties` map.
  ObjectSchema strict() {
    return copyWith(additionalProperties: false);
  }

  /// Allows the object schema to have properties that are not
  /// explicitly defined in the `properties` map.
  ObjectSchema passthrough() {
    return copyWith(additionalProperties: true);
  }

  /// Merges this schema with another [ObjectSchema].
  ObjectSchema merge(ObjectSchema other) {
    final newProperties = {...properties, ...other.properties};
    return copyWith(properties: newProperties);
  }

  /// Makes all properties on the schema optional.
  ObjectSchema partial() {
    final optionalProperties = properties.map(
      (key, schema) => MapEntry(key, schema.optional()),
    );

    return copyWith(properties: optionalProperties);
  }

  /// Extends this schema with additional or overridden properties.
  ObjectSchema extend(
    Map<String, AnyAckSchema> newProperties, {
    bool? additionalProperties,
    bool? isNullable,
    String? description,
  }) {
    final mergedProperties = {...properties, ...newProperties};

    return copyWith(
      properties: mergedProperties,
      additionalProperties: additionalProperties,
      isNullable: isNullable,
      description: description,
    );
  }

  /// Creates a new schema with a subset of the original's properties.
  ObjectSchema pick(List<String> keysToPick) {
    final pickSet = keysToPick.toSet();
    final newProperties = Map.fromEntries(
      properties.entries.where((entry) => pickSet.contains(entry.key)),
    );

    return copyWith(properties: newProperties);
  }

  /// Creates a new schema with a subset of the original's properties removed.
  ObjectSchema omit(List<String> keysToOmit) {
    final omitSet = keysToOmit.toSet();
    final newProperties = Map.fromEntries(
      properties.entries.where((entry) => !omitSet.contains(entry.key)),
    );

    return copyWith(properties: newProperties);
  }
}
