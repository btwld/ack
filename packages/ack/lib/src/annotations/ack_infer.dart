import 'package:meta/meta_meta.dart';

import 'ack_generated_json.dart';

/// Marks a top-level Ack schema for immutable model-class generation.
///
/// Apply `@AckInfer()` to a top-level schema variable or getter:
///
/// ```dart
/// @AckInfer()
/// final userSchema = Ack.object({
///   'name': Ack.string(),
///   'age': Ack.integer(),
/// });
/// ```
///
/// The declaring library must include both generated parts, for example
/// `part 'user.ack.dart';` and `part 'user.ack.g.dart';`. `ack_generator` emits
/// the model class, public parse/JSON API, and runtime bridges in the Ack
/// part. Structural field mapping is generated into the Ack JSON part.
/// Ack remains responsible for validation and codec-aware serialization.
///
/// Supported targets:
/// - Top-level variables
/// - Top-level getters
///
/// `meta` cannot express "top-level getter only", so the annotation allows all
/// getters and `ack_generator` enforces the top-level restriction.
///
/// Unsupported targets:
/// - Classes
/// - Instance members
/// - Local variables
@Target({TargetKind.topLevelVariable, TargetKind.getter})
final class AckInfer {
  /// Internal marker used on generated model classes.
  ///
  /// Typed as [Object] so generated code only needs a constant annotation
  /// expression. The generator inspects the actual [AckGeneratedJson] type.
  static const Object jsonSerializable = AckGeneratedJson();

  /// Optional exact name for the generated model class.
  ///
  /// If omitted, the class name is derived from the schema declaration:
  /// - `userSchema` -> `User`
  /// - `passwordSchema` -> `Password`
  ///
  /// If provided, the value is used directly:
  /// - `@AckInfer(name: 'AppUser')` -> `AppUser`
  final String? name;

  /// Creates an annotation for immutable Ack model generation.
  ///
  /// [name] must be an unchanged UpperCamelCase Dart identifier. It is used
  /// exactly; a `Type` suffix is retained when intentionally supplied.
  const AckInfer({this.name});
}
