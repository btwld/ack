# ack_annotations

`ack_annotations` provides the `@AckType()` annotation used by
`ack_generator`.

## Installation

```yaml
dependencies:
  ack: ^1.0.0-beta.12-wip
  ack_annotations: ^1.0.0-beta.12-wip

dev_dependencies:
  ack_generator: ^1.0.0-beta.12-wip
  build_runner: ^2.4.0
```

## Usage

Annotate a top-level Ack schema variable or getter and run `build_runner`:

```dart
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'user.g.dart';

@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'email': Ack.string().email(),
});
```

`ack_generator` emits an extension type such as `UserType` with typed getters
plus `parse()` and `safeParse()` helpers.

Generate the wrapper with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Custom names

Use `name` to override the generated type prefix:

```dart
@AckType(name: 'Password')
final passwordSchema = Ack.string().minLength(8);
```

This generates `PasswordType`.

## Supported targets

- Top-level schema variables
- Top-level schema getters

`@AckType()` is not supported on classes or instance members.
