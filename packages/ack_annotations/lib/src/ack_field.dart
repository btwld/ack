import 'package:meta/meta_meta.dart';

/// Annotation to configure field generation
@Target({TargetKind.field})
class AckField {
  /// Whether this field is required
  final bool required;
  
  /// Custom JSON key name
  final String? jsonKey;
  
  /// Validation constraints
  final List<String> constraints;
  
  const AckField({
    this.required = false,
    this.jsonKey,
    this.constraints = const [],
  });
}
