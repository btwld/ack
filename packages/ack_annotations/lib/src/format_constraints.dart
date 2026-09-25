import 'package:meta/meta_meta.dart';

/// Adds `.uri()` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class Uri {
  const Uri();
}

/// Adds `.datetime()` to an inferred string schema.
@Target({TargetKind.field, TargetKind.parameter})
final class DateTime {
  const DateTime();
}
