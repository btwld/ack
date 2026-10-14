import 'package:meta/meta_meta.dart';

/// Annotation that overrides the wire JSON key for a class-first field or
/// constructor parameter.
///
/// ```dart
/// @Schemable()
/// final class Account with _$AccountAck {
///   const Account({required this.imageUrl});
///
///   @AckKey('avatar')
///   final Uri imageUrl;
/// }
/// ```
@Target({TargetKind.field, TargetKind.parameter})
final class AckKey {
  /// Creates a JSON key override annotation for a field or parameter.
  const AckKey(this.name);

  /// Explicit wire JSON key for this property.
  final String name;
}
