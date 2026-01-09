# ack_annotations

Annotation package for the Ack validation ecosystem. Use these annotations on your Dart data classes to drive code generation with `ack_generator` and produce strongly typed validation schemas.

---

## Installation

```yaml
dependencies:
  ack_annotations: ^1.0.0-beta.4

dev_dependencies:
  ack_generator: ^1.0.0-beta.4
  build_runner: ^2.4.0
```

> Still on the 0.3 alpha line? Use `^0.3.0-alpha.0` for all Ack packages until you migrate to `1.0.0-beta.4`.

---

## Quick Start

```dart
import 'package:ack_annotations/ack_annotations.dart';

@AckModel()
class Product {
  final String name;
  final double price;

  Product({required this.name, required this.price});
}
```

Run the generator:

```bash
dart run build_runner build --delete-conflicting-outputs
```

The generator emits a matching `productSchema` that you can access from `ack_generator` output.

---

## `@AckModel`

Annotate classes that need schema generation.

Key options:

- `schemaName`: override the generated schema identifier.
- `description`: surface documentation in the generated schema.
- `additionalProperties`: allow unmodelled JSON fields.
- `additionalPropertiesField`: capture extra properties in a `Map<String, dynamic>` field.
- `discriminatedKey`: configure the discriminator field on base classes (for unions).
- `discriminatedValue`: declare the discriminator value on concrete subclasses.

Example (discriminated union):

```dart
@AckModel(discriminatedKey: 'type')
abstract class Notification {
  String get type;
}

@AckModel(discriminatedValue: 'email')
class EmailNotification extends Notification {
  @override
  String get type => 'email';
  final String subject;
  EmailNotification({required this.subject});
}
```

---

## `@AckField`

Annotate individual fields to fine-tune schema generation.

```dart
@AckModel()
class User {
  @AckField(constraints: ['minLength(1)', 'maxLength(50)'])
  final String name;

  @AckField(jsonKey: 'primary_email', constraints: ['email'])
  final String email;

  @AckField(required: true)
  final bool marketingOptIn;

  User({
    required this.name,
    required this.email,
    required this.marketingOptIn,
  });
}
```

Field options:
- `required`: ensures the field is present (otherwise Ack treats fields as required unless they are nullable/optional in the generated schema).
- `jsonKey`: map to a different JSON key.
- `description`: add documentation to the generated schema.
- `constraints`: string-based helpers for quick validation rules.

---

## Constraint Annotations

`ack_annotations` also exposes typed constraint annotations for readability.

| Category | Annotation | Generated constraint |
| --- | --- | --- |
| String | `@MinLength(n)` / `@MaxLength(n)` | `.minLength(n)` / `.maxLength(n)` |
| String | `@Email()` / `@Url()` | `.email()` / `.url()` |
| Pattern | `@Pattern('^[A-Z]')` | `.pattern(...)` |
| Number | `@Min(0)` / `@Max(10)` | `.min(0)` / `.max(10)` |
| Number | `@Positive()` | `.positive()` |
| Number | `@MultipleOf(5)` | `.multipleOf(5)` |
| List | `@MinItems(1)` / `@MaxItems(10)` | `.minLength(1)` / `.maxLength(10)` |
| Enum | `@EnumString(['draft','published'])` | `.enumString([...])` |

Mix and match annotation-based constraints with the string list syntax from `@AckField`—both map to the same generator capabilities.

---

## Working With build_runner

1. Make sure all Ack packages are on matching versions (either the 0.3 alpha train or the 1.0.0 release).
2. Run `dart run build_runner build --delete-conflicting-outputs` after changing annotated classes.
3. For continuous development, `dart run build_runner watch` keeps schemas in sync.

---

## Further Reading

- Core concepts & runtime API: [`ack` README](../../README.md)
- Generator workflows: [`ack_generator` README](../ack_generator/README.md)
- Full 1.0 migration plan: [`MIGRATION.md`](../../MIGRATION.md)
