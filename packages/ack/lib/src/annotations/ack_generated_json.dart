/// Generator-support marker applied to Ack-generated model classes.
///
/// This is not part of the user-facing annotation API. `ack_generator` emits
/// `Schemable.generatedJson` on generated schema-first models so its JSON
/// builder can find them. The marker carries no configuration: the generator
/// owns the fixed JSON mapping rules.
final class AckGeneratedJson {
  /// Creates the internal JSON-mapping marker.
  const AckGeneratedJson();
}
