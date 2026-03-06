import 'package:meta/meta_meta.dart';

/// Controls how requiredness is inferred for a field.
///
/// - [auto]: Infer from nullability and default value.
/// - [required]: Always required.
/// - [optional]: Always optional.
@Deprecated(
  'AckField is no longer used by the generator. Use constructor parameters instead.',
)
enum AckFieldRequiredMode { auto, required, optional }

/// Annotation to configure field generation
@Deprecated(
  'AckField is no longer used by the generator. Use constructor parameter annotations instead.',
)
@Target({TargetKind.field})
class AckField {
  /// Requiredness mode for this field.
  final AckFieldRequiredMode requiredMode;

  /// Custom JSON key name
  final String? jsonKey;

  /// Field description for documentation
  final String? description;

  /// Validation constraints
  final List<String> constraints;

  const AckField({
    this.requiredMode = AckFieldRequiredMode.auto,
    this.jsonKey,
    this.description,
    this.constraints = const [],
  });
}
