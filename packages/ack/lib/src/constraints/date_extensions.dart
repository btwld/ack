import 'package:ack/src/constraints/core/datetime_constraint.dart';

import '../schemas/schema.dart';
import 'constraint.dart';

/// Extension methods for [DateSchema] to provide additional validation capabilities.
extension DateSchemaExtensions on DateSchema {
  DateSchema _add(Validator<DateTime> validator) =>
      withConstraints([validator]);

  /// {@macro date_time_validator}
  DateSchema dateTime() => _add(DateConstraint.dateTime());

  /// {@macro date_validator}
  DateSchema date() => _add(DateConstraint.date());

  /// {@macro date_time_validator}
  @Deprecated('Use dateTime() instead for consistent naming')
  DateSchema isDateTime() => dateTime();

  /// {@macro date_time_validator}
  @Deprecated('Use dateTime() instead for proper camelCase naming')
  DateSchema datetime() => dateTime();

  /// {@macro date_validator}
  @Deprecated('Use date() instead for consistent naming')
  DateSchema isDate() => date();

  /// {@macro min_date_validator}
  DateSchema min(DateTime min) => _add(DateConstraint.onOrAfter(min));

  /// {@macro max_date_validator}
  DateSchema max(DateTime max) => _add(DateConstraint.onOrBefore(max));
}
