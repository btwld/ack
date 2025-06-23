import '../../constraints/string/format_constraint.dart';
import '../../constraints/string/length_constraint.dart';
import '../schema.dart';

/// Adds fluent validation methods to [StringSchema].
extension StringSchemaExtensions on StringSchema {
  /// Adds a constraint that the string's length must be at least [n].
  StringSchema minLength(int n) {
    return copyWith(constraints: [...constraints, MinLengthConstraint(n)]);
  }

  /// Adds a constraint that the string's length must be no more than [n].
  StringSchema maxLength(int n) {
    return copyWith(constraints: [...constraints, MaxLengthConstraint(n)]);
  }

  /// Adds a constraint that the string's length must be exactly [n].
  StringSchema length(int n) {
    return copyWith(constraints: [...constraints, ExactLengthConstraint(n)]);
  }

  /// Adds a constraint that the string must be a valid email address.
  StringSchema email() {
    return copyWith(constraints: [...constraints, EmailConstraint()]);
  }

  /// Adds a constraint that the string must be a valid URL.
  StringSchema url() {
    return copyWith(constraints: [...constraints, UrlConstraint()]);
  }

  /// Adds a constraint that the string must be a valid UUID.
  StringSchema uuid() {
    return copyWith(constraints: [...constraints, UuidConstraint()]);
  }
}
