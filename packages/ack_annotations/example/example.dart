// Shows the annotations that this package declares. The annotations are inert
// on their own: `ack_generator` reads them and writes the `.ack.dart` and
// `.ack.g.dart` parts. This file leaves those parts out, so it compiles and
// analyzes without running `build_runner`.
//
// A real class-first library adds the two part directives and the generated
// `_$UserAck` mixin. See the ack_generator package for a complete setup.
import 'package:ack/annotations.dart';

/// Class-first: `@AckModel()` derives a schema from the constructor.
///
/// `caseStyle` renames every JSON key, and the constraint annotations add
/// validation that the generated schema enforces.
@AckModel(caseStyle: AckCaseStyle.snake)
final class User {
  const User({required this.fullName, required this.email, this.age});

  @MinLength(2)
  @MaxLength(50)
  final String fullName;

  @Email()
  final String email;

  /// A nullable field is optional on the wire.
  @Min(0)
  @Max(120)
  final int? age;
}

/// `unknownProperties` decides what happens to keys the class does not declare.
///
/// [AckUnknownPropertyPolicy.capture] stores them in [captureField] and writes
/// them back when the model encodes.
@AckModel(
  unknownProperties: AckUnknownPropertyPolicy.capture,
  captureField: 'extras',
)
final class TolerantPayload {
  const TolerantPayload({required this.id, this.extras = const {}});

  final String id;

  final Map<String, Object?> extras;
}

/// `@Required()` and `@Optional()` override what the constructor implies for one
/// field. Keep `@AckField(schema: ...)` for custom field codecs.
@AckModel()
final class Article {
  const Article({required this.title, this.summary});

  @NotEmpty()
  final String title;

  /// The constructor allows a missing value, so mark the key required anyway.
  @Required()
  final String? summary;
}

void main() {
  // The annotations carry const data that the generator reads at build time.
  const user = AckModel(caseStyle: AckCaseStyle.snake);
  print('User keys use ${user.caseStyle.name} case.');

  const tolerant = AckModel(
    unknownProperties: AckUnknownPropertyPolicy.capture,
    captureField: 'extras',
  );
  print('Unknown keys go to "${tolerant.captureField}".');
}
