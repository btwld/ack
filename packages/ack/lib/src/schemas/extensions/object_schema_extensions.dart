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
    final newRequired =
        {...requiredProperties, ...other.requiredProperties}.toList();

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
    final newRequired =
        requiredProperties.where((key) => pickSet.contains(key)).toList();

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
        requiredProperties.where((key) => !omitSet.contains(key)).toList();

    return copyWith(
      properties: newProperties,
      requiredProperties: newRequired,
    );
  }
}
