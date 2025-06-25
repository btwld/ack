import '../schema.dart';

/// Adds fluent validation methods to [ObjectSchema].
extension ObjectSchemaExtensions on ObjectSchema {
  /// Makes the object schema strict, disallowing any properties not
  /// explicitly defined in the `properties` map.
  ///
  /// This is a convenience method for `copyWith(allowAdditionalProperties: false)`.
  ObjectSchema strict() {
    return copyWith(allowAdditionalProperties: false);
  }

  /// Allows the object schema to have properties that are not
  /// explicitly defined in the `properties` map.
  ///
  /// This is a convenience method for `copyWith(allowAdditionalProperties: true)`.
  ObjectSchema passthrough() {
    return copyWith(allowAdditionalProperties: true);
  }

  /// Merges this schema with another [ObjectSchema].
  ///
  /// The properties of the [other] schema will overwrite properties of this
  /// schema if they share the same key. The `requiredProperties` lists
  /// will be combined.
  ObjectSchema merge(ObjectSchema other) {
    // Combine properties, with the 'other' schema's properties taking precedence.
    final newProperties = {...properties, ...other.properties};

    // Combine required properties, ensuring uniqueness.
    final newRequired = {...required, ...other.required}.toList();

    return copyWith(
      properties: newProperties,
      requiredProperties: newRequired,
    );
  }

  /// Makes all properties on the schema optional.
  ///
  /// This is a convenience method for `copyWith(requiredProperties: const [])`.
  ObjectSchema partial() {
    return copyWith(requiredProperties: const []);
  }

  /// Extends this schema with additional or overridden properties.
  ///
  /// Acts like an additional constructor, allowing you to override properties
  /// one by one and add additional properties and construction elements.
  ///
  /// Properties in [newProperties] will override existing properties with the same key.
  /// The [required] list will be merged with existing required properties.
  /// Other schema properties can be overridden using the optional parameters.
  ObjectSchema extend(
    Map<String, AckSchema> newProperties, {
    List<String>? required,
    bool? additionalProperties,
    bool? isNullable,
    String? description,
    Map<String, Object?>? defaultValue,
  }) {
    // Merge properties, with new properties taking precedence
    final mergedProperties = {...properties, ...newProperties};

    // Merge required fields if provided, otherwise keep existing
    final mergedRequired = required != null
        ? {...this.required, ...required}.toList()
        : this.required;

    return copyWith(
      properties: mergedProperties,
      requiredProperties: mergedRequired,
      allowAdditionalProperties: additionalProperties,
      isNullable: isNullable,
      description: description,
      defaultValue: defaultValue,
    );
  }

  /// Creates a new schema with a subset of the original's properties.
  ///
  /// Only the properties with keys included in [keysToPick] will be
  /// kept. Required properties that are not picked will be removed
  /// from the new schema's required list.
  ObjectSchema pick(List<String> keysToPick) {
    final pickSet = keysToPick.toSet();

    // Filter the properties map to only include the picked keys.
    final newProperties = Map.fromEntries(
      properties.entries.where((entry) => pickSet.contains(entry.key)),
    );

    // Filter the required list to only include picked keys that were originally required.
    final newRequired = required.where((key) => pickSet.contains(key)).toList();

    return copyWith(
      properties: newProperties,
      requiredProperties: newRequired,
    );
  }

  /// Creates a new schema with a subset of the original's properties removed.
  ///
  /// The properties with keys included in [keysToOmit] will be removed.
  /// Required properties that are omitted will also be removed from the
  /// new schema's required list.
  ObjectSchema omit(List<String> keysToOmit) {
    final omitSet = keysToOmit.toSet();

    // Filter the properties map to exclude the omitted keys.
    final newProperties = Map.fromEntries(
      properties.entries.where((entry) => !omitSet.contains(entry.key)),
    );

    // Filter the required list to exclude omitted keys.
    final newRequired =
        required.where((key) => !omitSet.contains(key)).toList();

    return copyWith(
      properties: newProperties,
      requiredProperties: newRequired,
    );
  }
}
