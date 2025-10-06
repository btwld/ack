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

  if (value is Map<String, Object?>) {
    return Map<String, Object?>.unmodifiable(
      value.map((key, val) => MapEntry(key, cloneDefault(val))),
    );
  }

  if (value is List<Object?>) {
    return List<Object?>.unmodifiable(
      value.map((item) => cloneDefault(item)),
    );
  }

  // Primitives are immutable (String, num, bool, DateTime, etc.)
  return value;
}
