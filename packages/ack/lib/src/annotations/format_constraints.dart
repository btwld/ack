import 'package:meta/meta_meta.dart';

/// Adds `.uri()` to an inferred string schema.
@Deprecated('Use @Validate.uri() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class Uri {
  const Uri();
}

/// Adds `.datetime()` to an inferred string schema.
@Deprecated('Use @Validate.dateTime() from package:ack/ack.dart instead.')
@Target({TargetKind.field, TargetKind.parameter})
final class DateTime {
  const DateTime();
}
