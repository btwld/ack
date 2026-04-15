import 'package:meta/meta_meta.dart';

/// Marks a top-level Ack schema for extension-type generation.
///
/// Apply `@AckType()` to a top-level schema variable or getter:
///
/// ```dart
/// @AckType()
/// final userSchema = Ack.object({
///   'name': Ack.string(),
///   'age': Ack.integer(),
/// });
/// ```
///
/// `ack_generator` emits a typed wrapper around the schema's validated
/// representation plus `parse()` and `safeParse()` helpers.
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
class AckType {
  /// Optional custom name for the generated extension type.
  ///
  /// If not provided, the type name is derived from the schema variable name:
  /// - `userSchema` -> `UserType`
  /// - `passwordSchema` -> `PasswordType`
  ///
  /// If provided, the custom name is used with the `Type` suffix:
  /// - `@AckType(name: 'CustomUser')` -> `CustomUserType`
  /// - `@AckType(name: 'MyPassword')` -> `MyPasswordType`
  final String? name;

  /// Creates an annotation to generate extension types for validated data.
  ///
  /// The [name] value must be a valid Dart identifier and should omit the
  /// trailing `Type` suffix.
  const AckType({this.name});
}
