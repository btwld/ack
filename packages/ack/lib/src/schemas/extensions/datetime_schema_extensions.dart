import '../../constraints/datetime_constraint.dart';
import '../schema.dart';

/// Extensions for `TransformedSchema<String, DateTime>` to add date range validation.
///
/// These extensions work with schemas created by [Ack.date()] or [Ack.datetime()],
/// which parse ISO 8601 date/datetime strings into DateTime objects.
///
/// Example:
/// ```dart
/// // Age validation (18+)
/// final eighteenYearsAgo = DateTime.now().subtract(Duration(days: 365 * 18));
/// final birthdateSchema = Ack.date().max(eighteenYearsAgo);
///
/// // Date range validation
/// final eventDateSchema = Ack.date()
///   .min(DateTime(2025, 1, 1))
///   .max(DateTime(2025, 12, 31));
/// ```
extension DateTimeSchemaExtensions on TransformedSchema<String, DateTime> {
  /// Constrains the date to be on or after [minDate] (inclusive).
  ///
  /// The constraint is applied to the transformed DateTime value, after the
  /// string has been validated and parsed.
  ///
  /// Example:
  /// ```dart
  /// final schema = Ack.date().min(DateTime(2000, 1, 1));
  ///
  /// schema.parse("2005-06-15"); // ✓ Valid - after min
  /// schema.parse("2000-01-01"); // ✓ Valid - exactly at min (inclusive)
  /// schema.parse("1999-12-31"); // ✗ Fails - before min
  /// ```
  TransformedSchema<String, DateTime> min(DateTime minDate) {
    return copyWith(
      constraints: [...constraints, DateTimeConstraint.min(minDate)],
    );
  }

  /// Constrains the date to be on or before [maxDate] (inclusive).
  ///
  /// The constraint is applied to the transformed DateTime value, after the
  /// string has been validated and parsed.
  ///
  /// Example - 18+ age requirement:
  /// ```dart
  /// final now = DateTime.now();
  /// final eighteenYearsAgo = DateTime(
  ///   now.year - 18,
  ///   now.month,
  ///   now.day,
  /// );
  /// final schema = Ack.date().max(eighteenYearsAgo);
  ///
  /// schema.parse("2000-01-01"); // ✓ Valid if more than 18 years ago
  /// schema.parse("2020-01-01"); // ✗ Fails if less than 18 years ago
  /// ```
  TransformedSchema<String, DateTime> max(DateTime maxDate) {
    return copyWith(
      constraints: [...constraints, DateTimeConstraint.max(maxDate)],
    );
  }
}
