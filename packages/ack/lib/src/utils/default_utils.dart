/// Utilities for safely handling default values in schemas.
library;

/// Deep clones a default value to prevent mutation.
///
/// - Maps: Creates unmodifiable copy with recursively cloned values
/// - Lists: Creates unmodifiable copy with recursively cloned items
/// - Primitives: Returns as-is (immutable by nature)
///
/// Ensures default values are safely reused without shared-state bugs.
///
/// Example:
/// ```dart
/// final defaultValue = {'user': {'name': 'Guest'}};
/// final cloned = cloneDefault(defaultValue);
/// // Separate instances; modifying one won't affect the other
/// ```
Object? cloneDefault(Object? value) {
  if (value == null) return null;

  // Handle any Map (not just Map<String, Object?>) so we don't skip cloned defaults
  // for literals inferred as Map<String, int> or similar.
  if (value is Map) {
    // Preserve String-keyed maps to keep compatibility with MapValue casts.
    if (value.keys.every((key) => key is String)) {
      final cloned = <String, Object?>{};
      value.forEach((key, entryValue) {
        cloned[key as String] = cloneDefault(entryValue);
      });
      return Map<String, Object?>.unmodifiable(cloned);
    }

    final cloned = <Object?, Object?>{};
    value.forEach((key, entryValue) {
      cloned[key] = cloneDefault(entryValue);
    });
    return Map<Object?, Object?>.unmodifiable(cloned);
  }

  if (value is List) {
    return List<Object?>.unmodifiable(value.map(cloneDefault));
  }

  // Primitives / value types are immutable enough for defaults (String, num, bool, etc.).
  return value;
}
