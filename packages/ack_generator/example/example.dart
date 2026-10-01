// The input that `ack_generator` reads, and the API it writes.
//
// This file deliberately omits the `part` directives, so it compiles and
// analyzes without running `build_runner`. A real library adds them:
//
// ```dart
// part 'example.ack.dart';   // the model class and its parse/JSON API
// part 'example.ack.g.dart'; // the structural field mapping
// ```
//
// Then run:
//
// ```bash
// dart run build_runner build --delete-conflicting-outputs
// ```
//
// Add `ack` to `dependencies`, and `ack_generator` plus `build_runner` to
// `dev_dependencies`.
import 'package:ack/ack.dart';

/// Schema-first. `@Schemable()` derives an immutable `User` class from this
/// schema: final `name`, `email`, and `age` fields, `User.parse`,
/// `User.fromJson`, and `toJson`.
@Schemable()
final userSchema = Ack.object({
  'name': Ack.string().minLength(2).maxLength(50),
  'email': Ack.string().email(),
  'age': Ack.integer().min(0).max(120).optional(),
});

/// `name` overrides the class name that the declaration would imply.
/// This schema generates `AppSettings` rather than `Settings`.
@Schemable(name: 'AppSettings')
final settingsSchema = Ack.object({
  'theme': Ack.enumString(['light', 'dark']),
  'notifications': Ack.boolean(),
});

/// Class-first. `@Schemable()` runs the other direction: it derives a validated
/// schema from this hand-written class, which applies the generated
/// `_$ProductAck` mixin once the parts are in place.
@Schemable(caseStyle: AckCaseStyle.snake)
final class Product {
  const Product({required this.displayName, required this.priceCents});

  @NotEmpty()
  final String displayName;

  @Min(0)
  final int priceCents;
}

void main() {
  // Ack validates against the same schema before any code is generated. The
  // generated model wraps this result in typed fields.
  final result = userSchema.safeParse({
    'name': 'Ada Lovelace',
    'email': 'ada@example.com',
    'age': 36,
  });

  if (result.isOk) {
    // With the parts in place this reads `User.parse(json).name`.
    print('Valid user: ${result.getOrThrow()}');
  } else {
    print('Validation failed: ${result.getError()}');
  }

  print('Settings schema: ${settingsSchema.toJsonSchema()}');
}
