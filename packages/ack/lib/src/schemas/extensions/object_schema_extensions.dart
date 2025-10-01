import '../schema.dart';
import 'ack_schema_extensions.dart';

/// Adds fluent validation methods to [ObjectSchema].
extension ObjectSchemaExtensions on ObjectSchema {
  /// Makes the object schema strict, disallowing any properties not
  /// explicitly defined in the `properties` map.
  ///
  /// This is a convenience method for `copyWith(additionalProperties: false)`.
  ObjectSchema strict() {
    return copyWith(additionalProperties: false);
  }

  /// Allows the object schema to have properties that are not
  /// explicitly defined in the `properties` map.
  ///
  /// This is a convenience method for `copyWith(additionalProperties: true)`.
  ObjectSchema passthrough() {
    return copyWith(additionalProperties: true);
  }

  /// Merges this schema with another [ObjectSchema].
  ///
  /// The properties of the [other] schema will overwrite properties of this
  /// schema if they share the same key.
  ObjectSchema merge(ObjectSchema other) {
    // Combine properties, with the 'other' schema's properties taking precedence.
    final newProperties = {...properties, ...other.properties};

    return copyWith(properties: newProperties);
  }

  /// Makes all properties on the schema optional.
  ///
  /// This wraps each property schema with `.optional()`.
  ObjectSchema partial() {
    final optionalProperties = properties.map(
      (key, schema) => MapEntry(key, schema.optional()),
    );

    return copyWith(properties: optionalProperties);
  }

  /// Extends this schema with additional or overridden properties.
  ///
  /// Acts like an additional constructor, allowing you to override properties
  /// one by one and add additional properties and construction elements.
  ///
  /// Properties in [newProperties] will override existing properties with the same key.
  /// Other schema properties can be overridden using the optional parameters.
  ObjectSchema extend(
    Map<String, AckSchema> newProperties, {
    bool? additionalProperties,
    bool? isNullable,
    String? description,
    Map<String, Object?>? defaultValue,
  }) {
    // Merge properties, with new properties taking precedence
    final mergedProperties = {...properties, ...newProperties};

    return copyWith(
      properties: mergedProperties,
      additionalProperties: additionalProperties,
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
    );
  }

  /// Creates a new schema with a subset of the original's properties.
  ///
  /// Only the properties with keys included in [keysToPick] will be kept.
  ObjectSchema pick(List<String> keysToPick) {
    final pickSet = keysToPick.toSet();

    // Filter the properties map to only include the picked keys.
    final newProperties = Map.fromEntries(
      properties.entries.where((entry) => pickSet.contains(entry.key)),
    );

    return copyWith(properties: newProperties);
  }

  /// Creates a new schema with a subset of the original's properties removed.
  ///
  /// The properties with keys included in [keysToOmit] will be removed.
  ObjectSchema omit(List<String> keysToOmit) {
    final omitSet = keysToOmit.toSet();

    // Filter the properties map to exclude the omitted keys.
    final newProperties = Map.fromEntries(
      properties.entries.where((entry) => !omitSet.contains(entry.key)),
    );

    return copyWith(properties: newProperties);
  }
}
