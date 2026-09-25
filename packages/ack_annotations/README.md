# ack_annotations

`ack_annotations` provides the `@AckInfer()` schema-first and `@AckModel()`
class-first annotations used by `ack_generator`. Deprecated `@AckType()` is
retained for Ack 1.1 extension-type compatibility.

## Installation

```yaml
dependencies:
  ack: ^1.6.2
  ack_annotations: ^1.6.2

dev_dependencies:
  ack_generator: ^1.6.2
  build_runner: ^2.4.0
```

## Usage

Annotate a top-level Ack schema variable or getter and run `build_runner`:

```dart
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'user.ack.dart';
part 'user.ack.g.dart';

@AckInfer()
final userSchema = Ack.object({
  'name': Ack.string(),
  'email': Ack.string().email(),
});
```

`ack_generator` emits an immutable `User` class with typed fields, an unchecked
constructor, parsing helpers, JSON methods, generated `copyWith`, deep
collection-aware equality, and a public `$ack` adapter. The Ack part owns those
declarations; `json_serializable` writes the structural field-mapping helpers
into `user.ack.g.dart`. Ack-only apps do not add JSON packages for generated
models. The annotation package requires Dart 3.9.

Generate the model with:

```bash
dart run build_runner build
```

For class-first generation, keep the class in source and apply its generated
mixin:

```dart
@AckModel()
final class Account with _$AccountAck {
  const Account({required this.name});

  @MinLength(2)
  final String name;

  static final fromJson = AccountSchema.fromJson;
}
```

This generates the public `AccountSchema` facade plus validated `toJson`,
`safeToJson`, `copyWith`, equality, and `toString` implementations.
Field documentation becomes the field schema's description. Format
annotations such as `@Url()`, `@Uuid()`, and `@Date()` constrain string
fields. Import `package:ack_annotations/format_annotations.dart` with a
prefix for `@formats.Uri()` and `@formats.DateTime()`. The prefix preserves
the Dart core `Uri` and `DateTime` type names.

## Custom names

Use `name` to set the exact generated class name:

```dart
@AckInfer(name: 'Password')
final passwordSchema = Ack.string().minLength(8);
```

This generates `Password`. Names must be unchanged UpperCamelCase identifiers;
an intentional `Type` suffix is kept exactly.

## Supported targets

- Top-level schema variables
- Top-level schema getters

`@AckInfer()` is not supported on classes or instance members.

`@AckModel()` targets a public, constructable `final class` with final stored
fields and derives an Ack codec schema from its constructor-backed fields.
Annotated sealed union bases remain supported; each concrete branch must be
final. Instantiable models apply the generated `_$ClassAck` mixin. The public
`<ClassName>Schema` facade exposes typed `schema` and raw `wireSchema`;
`schemaName:` overrides the exact facade class name and must be UpperCamelCase.

Unknown properties use `unknownProperties: AckUnknownPropertyPolicy.<policy>`.
Use `discard` only for tolerant, read-only consumers; models that round-trip
unknown keys use `capture` and may select their map field with `captureField`.
`@AckField` can override `schema`. Use `@Optional()` and `@Required()` for
key presence, and `@NotNull()` when an omitted key is allowed but an explicit
JSON `null` is not. Deprecated `AckFieldPresence` remains available during
migration. See the
[Model Code Generation guide](https://concepta.dev/documentation/ack/advanced/typesafe-schemas).
