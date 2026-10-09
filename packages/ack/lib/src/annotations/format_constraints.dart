import 'package:meta/meta_meta.dart';

/// Adds `.uri()` to an inferred string schema.
@Deprecated('Use @Check.uri() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Uri {
  const Uri();
}

/// Adds `.datetime()` to an inferred string schema.
@Deprecated('Use @Check.dateTime() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class DateTime {
  const DateTime();
}
