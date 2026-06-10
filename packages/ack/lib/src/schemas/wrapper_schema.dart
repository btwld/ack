part of 'schema.dart';

/// ACK-internal infrastructure for schemas that wrap another boundary-facing
/// schema.
///
/// Wrappers add runtime behavior (e.g. codecs, defaults) while preserving an
/// inner schema for boundary-shape traversal, schema-model export, and
/// discriminated-branch rewriting. The canonical JSON export path is
/// `AckSchema → AckSchemaModel → JSON`; wrappers do not render JSON directly.
///
/// The fluent API (`nullable`, `describe`, `withConstraint`, …) is provided by
/// [FluentSchema], which this mixin requires via its `on` clause; wrappers only
/// have to implement [copyWith] from `FluentSchema` plus the two members below.
///
/// Not a public extension point for application code. Consumers should use
/// `Ack.*` factories (`withDefault`, `codec`, `transform`, `model`) instead of
/// implementing this mixin themselves.
@internal
mixin WrapperSchema<
  Boundary extends Object,
  Runtime extends Object,
  Schema extends AckSchema<Boundary, Runtime>
>
    on FluentSchema<Boundary, Runtime, Schema> {
  /// The wrapped schema used for boundary-shape traversal.
  AnyAckSchema get inner;

  /// Returns a copy of this wrapper with [inner] swapped for [newInner].
  ///
  /// Used by traversal utilities (e.g. discriminated-branch synthesis) that
  /// need to rewrite the underlying boundary schema while preserving wrapper
  /// configuration and behavior.
  Schema copyWithInner(AnyAckSchema newInner);
}
