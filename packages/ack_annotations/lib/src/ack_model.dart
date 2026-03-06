import 'package:meta/meta_meta.dart';

import 'schemable.dart';

/// Deprecated compatibility alias for [Schemable].
///
/// `AckModel` now follows the same constructor-driven contract as `Schemable`:
///
/// - the selected constructor defines the schema shape
/// - only named constructor parameters are supported
/// - field-level metadata is no longer part of the model contract
/// - discriminated roots must be `sealed`
///
/// New code should prefer `@Schemable()`.
///
/// ```dart
/// @Schemable()
/// class User {
///   final String name;
///
///   const User({required this.name});
/// }
/// ```
@Deprecated('Use @Schemable() instead.')
@Target({TargetKind.classType})
class AckModel extends Schemable {
  const AckModel({
    super.schemaName,
    super.description,
    super.additionalProperties = false,
    super.additionalPropertiesField,
    super.discriminatedKey,
    super.discriminatedValue,
    super.caseStyle = CaseStyle.none,
    super.useProviders = const [],
  });
}

/// Convenience constant for simple cases without options.
///
/// Use this when you don't need to customize the annotation:
/// ```dart
/// @ackModel
/// class User {
///   final String name;
///
///   const User({required this.name});
/// }
/// ```
///
/// For custom options, use the class constructor:
/// ```dart
/// @AckModel(description: 'A user model')
/// class User {
///   final String name;
///
///   const User({required this.name});
/// }
/// ```
@Deprecated('Use `schemable` instead.')
const ackModel = AckModel();
