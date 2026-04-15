# Ack Generator

`ack_generator` emits extension types for top-level Ack schemas annotated with
`@AckType()`.

## Overview

Write your schemas directly with the Ack fluent API, then annotate the schema
variable or getter to generate a typed wrapper:

```dart
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'user_schema.g.dart';

@AckType()
final userSchema = Ack.object({
  'name': Ack.string(),
  'email': Ack.string().email(),
});
```

Running `dart run build_runner build` generates an extension type such as:

```dart
extension type UserType(Map<String, Object?> _data)
    implements Map<String, Object?> {
  static UserType parse(Object? data) { ... }
  static SchemaResult<UserType> safeParse(Object? data) { ... }

  String get name => _data['name'] as String;
  String get email => _data['email'] as String;
}
```

## Installation

```yaml
dependencies:
  ack: ^1.0.0-beta.12-wip
  ack_annotations: ^1.0.0-beta.12-wip

dev_dependencies:
  ack_generator: ^1.0.0-beta.12-wip
  build_runner: ^2.4.0
```

## Supported declarations

- Top-level schema variables
- Top-level schema getters

`@AckType()` is not supported on classes or instance members.

## Supported schema shapes

- `Ack.object(...)`
- Primitive schemas such as `Ack.string()`, `Ack.integer()`, `Ack.double()`, `Ack.boolean()`
- `Ack.list(...)` and `Set`-like list wrappers
- `Ack.literal(...)`, `Ack.enumString(...)`, `Ack.enumValues(...)`
- Non-object transforms with explicit output types
- `Ack.discriminated(...)` when branches are top-level `@AckType` object schemas in the same library

## Important limitations

- `Ack.any()` and `Ack.anyOf()` do not generate extension types.
- Inline anonymous object branches are rejected for typed generation. Extract them to a named top-level schema first.
- Nullable top-level schemas do not emit extension types.
- `@AckType()` requires static schema resolution for nested object references.

## Build commands

```bash
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch
```

## More information

- Root docs: [../../README.md](../../README.md)
- Annotation package: [../ack_annotations/README.md](../ack_annotations/README.md)
- Example package: [../../example/README.md](../../example/README.md)
