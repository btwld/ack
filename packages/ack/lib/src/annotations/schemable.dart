import 'package:meta/meta_meta.dart';

/// JSON field-name styles supported by class-first Ack generation.
///
/// This enum is deliberately closed: `ack_generator` maps each style onto a
/// fixed field-rename rule when it generates the model schema.
enum AckCaseStyle { none, snake, kebab, pascal, screamingSnake }

/// How a class-first object treats properties that are not declared fields.
///
/// [reject] is the default: unknown properties fail validation.
/// [discard] accepts unknown properties during validation but does not store
/// them on the model. It is intended for tolerant, read-only consumers.
/// [capture] stores unknown properties in the configured `captureField`
/// and flattens them back onto the wire during encoding. Declared fields and
/// union discriminators always win over captured extras. Models that must
/// round-trip unknown properties use [capture].
enum AckUnknownPropertyPolicy { reject, discard, capture }

/// Marks an Ack schema declaration.
///
/// Use this annotation on a top-level schema variable or getter to generate a
/// schema-first model. Use it on a class to generate a class-first schema.
/// Use it on a `library` directive (`@Schemable(schemas: [...]) library;`) to
/// register custom type schemas across the library and its importers.
/// [name] applies only to a top-level schema; [schemas] applies to a class or
/// `library` directive; every other option applies only to a class.
/// `ack_generator` rejects an option set for the wrong target.
@Target({
  TargetKind.classType,
  TargetKind.topLevelVariable,
  TargetKind.getter,
  TargetKind.library,
})
final class Schemable {
  /// Creates a unified schema declaration annotation.
  const Schemable({
    this.name,
    this.schemaName,
    this.description,
    this.caseStyle = AckCaseStyle.none,
    this.discriminatorKey,
    this.discriminatorValue,
    this.unknownProperties = AckUnknownPropertyPolicy.reject,
    this.captureField = 'additionalProperties',
    this.schemas,
  });

  /// Exact generated model name for a top-level schema declaration.
  final String? name;

  /// Exact generated schema facade name for a class declaration.
  final String? schemaName;

  /// Description for a class schema. This takes precedence over an
  /// `@description` doc tag. A top-level schema uses `.describe(...)` instead.
  final String? description;

  /// JSON field-name style for a class declaration.
  final AckCaseStyle caseStyle;

  /// Discriminator key for a sealed class declaration.
  final String? discriminatorKey;

  /// Discriminator value for a concrete union branch.
  final String? discriminatorValue;

  /// Unknown-property policy for a class declaration.
  final AckUnknownPropertyPolicy unknownProperties;

  /// Dart field that stores captured unknown properties.
  final String captureField;

  /// Custom top-level schema functions registered for this class or library.
  ///
  /// Each entry must be a const tear-off of a zero-argument, non-generic
  /// top-level function returning a two-way `AckSchema<Boundary, Runtime>`.
  final List<Object Function()>? schemas;
}
