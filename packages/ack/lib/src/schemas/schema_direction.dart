part of 'schema.dart';

/// The direction in which a schema graph is currently being executed.
///
/// - [SchemaDirection.forward] corresponds to `parse`/`decode`: boundary input
///   is turned into a runtime value.
/// - [SchemaDirection.backward] corresponds to `encode`: a runtime value is
///   turned back into its boundary representation.
enum SchemaDirection { forward, backward }
