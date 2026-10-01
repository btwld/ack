import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta_meta.dart';

/// JSON field-name styles supported by class-first Ack generation.
///
/// This enum is deliberately closed because Ack's second generation phase
/// delegates field mapping to json_serializable's closed `FieldRename` enum.
/// Supporting an open-ended transform would require redesigning that phase.
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

/// Marks a hand-written class for Ack schema generation.
///
/// The declaring library must include both generated parts, for example
/// `part 'user.ack.dart';` and `part 'user.ack.g.dart';`. Instantiable models and
/// implicit sealed-union branches must be `final class` declarations, use only
/// final stored fields, and apply the generated `_$ClassAck` mixin. Annotated
/// sealed union bases remain supported.
@Deprecated('Use @Schemable(). AckModel will be removed in 2.0.0.')
@Target({TargetKind.classType})
final class AckModel {
  /// Creates a class-first Ack model annotation.
  const AckModel({
    this.schemaName,
    this.description,
    this.caseStyle = AckCaseStyle.none,
    this.discriminatorKey,
    this.discriminatorValue,
    this.unknownProperties = AckUnknownPropertyPolicy.reject,
    this.captureField = 'additionalProperties',
  }) : // A switch expression is not const-evaluable in a const constructor.
       jsonSerializable = caseStyle == AckCaseStyle.snake
           ? const JsonSerializable(
               includeIfNull: false,
               fieldRename: FieldRename.snake,
             )
           : caseStyle == AckCaseStyle.kebab
           ? const JsonSerializable(
               includeIfNull: false,
               fieldRename: FieldRename.kebab,
             )
           : caseStyle == AckCaseStyle.pascal
           ? const JsonSerializable(
               includeIfNull: false,
               fieldRename: FieldRename.pascal,
             )
           : caseStyle == AckCaseStyle.screamingSnake
           ? const JsonSerializable(
               includeIfNull: false,
               fieldRename: FieldRename.screamingSnake,
             )
           : const JsonSerializable(
               includeIfNull: false,
               fieldRename: FieldRename.none,
             );

  /// Exact public schema facade class name.
  ///
  /// The name must be a public UpperCamel identifier. When omitted, Ack derives
  /// `<ClassName>Schema`, preserving the model class's written capitalization.
  final String? schemaName;

  /// Schema description. This takes precedence over an `@description` doc tag.
  /// Untagged documentation does not become a schema description.
  final String? description;

  /// Naming convention applied to JSON field keys.
  final AckCaseStyle caseStyle;

  /// Required discriminator key for an annotated sealed union base.
  final String? discriminatorKey;

  /// Wire discriminator for a concrete union branch.
  ///
  /// When omitted, the verbatim class name is used.
  final String? discriminatorValue;

  /// Policy for undeclared object properties.
  final AckUnknownPropertyPolicy unknownProperties;

  /// Dart field that stores captured unknown properties.
  ///
  /// Used only when [unknownProperties] is
  /// [AckUnknownPropertyPolicy.capture]. Defaults to
  /// `additionalProperties` and may be `args`.
  final String captureField;

  /// Fixed phase-2 configuration consumed by `ack_generator`.
  ///
  /// This remains derived from [caseStyle], so users cannot independently
  /// configure schema keys and JSON mapping.
  final JsonSerializable jsonSerializable;
}
