/// The object form of a decoded JSON Schema document.
///
/// This zero-cost wrapper gives JSON Schema maps a domain type while remaining
/// usable anywhere a `Map<String, Object?>` is expected.
extension type const JsonSchema.fromMap(Map<String, Object?> value)
    implements Map<String, Object?> {}
