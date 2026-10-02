import 'package:meta/meta_meta.dart';

import 'ack_generated_json.dart';
import 'ack_model.dart';

/// Marks an Ack schema declaration.
///
/// Use this annotation on a top-level schema variable or getter to generate a
/// schema-first model. Use it on a class to generate a class-first schema.
/// [name] applies only to a top-level schema; every other option applies only
/// to a class. `ack_generator` rejects an option set for the other target.
/// The deprecated `@AckInfer` and `@AckModel` spellings remain supported until
/// 2.0.0.
@Target({TargetKind.classType, TargetKind.topLevelVariable, TargetKind.getter})
final class Schemable {
  /// Internal marker used on generated schema-first model classes.
  ///
  /// Typed as [Object] so generated code only needs a constant annotation
  /// expression. The generator inspects the actual [AckGeneratedJson] type.
  static const Object generatedJson = AckGeneratedJson();

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
}
