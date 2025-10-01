/// Common type definitions used throughout the Ack library.
///
/// This file centralizes shared type aliases to ensure consistency
/// and prevent duplication across the codebase.
library;

/// Type alias for object/map values used in schema validation.
///
/// Represents a map with string keys and nullable object values,
/// which is the standard format for JSON objects in Dart.
typedef MapValue = Map<String, Object?>;
