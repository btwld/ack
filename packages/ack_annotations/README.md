# ack_annotations

Annotations for constructor-driven Ack schema generation.

Use `ack_annotations` with `ack_generator` to derive `Ack.object()` schemas from
 Dart models, constructor parameters, and explicit schema providers.

## Install

```yaml
dependencies:
  ack_annotations: ^1.0.0-beta.9

dev_dependencies:
  ack_generator: ^1.0.0-beta.9
  build_runner: ^2.4.0
```

## Quick Start

```dart
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

part 'product.g.dart';

@Schemable()
class Product {
  final String name;
  final double price;
  final String? description;

  const Product({
    required this.name,
    required this.price,
    this.description,
  });
}
```

When using a `part` directive with `@Schemable`, include an unprefixed
`import 'package:ack/ack.dart';` because generated code references `Ack`
directly.

Generate the schema:

```bash
dart run build_runner build --delete-conflicting-outputs
```

The generator emits `productSchema`.

## Constructor Contract

`@Schemable()` reads one constructor and turns its named parameters into schema
 properties.

- Use the unnamed constructor by default.
- Mark a different constructor with `@SchemaConstructor()`.
- Use only named parameters in the selected constructor.
- Apply parameter metadata on constructor parameters, not on fields.

```dart
@Schemable()
class User {
  final String name;
  final String email;

  const User._({required this.name, required this.email});

  @SchemaConstructor()
  const User.fromApi({
    @SchemaKey('full_name') required this.name,
    @Description('Primary email address') required this.email,
  });
}
```

## Parameter Annotations

Use constructor-parameter annotations to control the generated schema.

- `@SchemaKey('wire_name')`: override the property name
- `@Description('...')`: attach schema documentation
- `@MinLength`, `@MaxLength`, `@Email`, `@Url`, `@Pattern`
- `@Min`, `@Max`, `@Positive`, `@MultipleOf`
- `@MinItems`, `@MaxItems`, `@EnumString`

```dart
@Schemable()
class SignupRequest {
  final String username;
  final String email;
  final int age;

  const SignupRequest({
    @MinLength(3) @MaxLength(20) required this.username,
    @Email() required this.email,
    @Min(13) required this.age,
  });
}
```

## Typed Schema Providers

Register a `SchemaProvider<T>` when a constructor parameter uses a custom type
 that is not itself `@Schemable()`.

`SchemaProvider<T>` must return `AckSchema<T>`. If the wire shape differs from
 `T`, return a transformed schema.

Provider targets that are themselves `@Schemable()` are rejected. If you need
composition over generated schemas, keep the provider target non-schemable and
reference generated schemas inside the provider implementation.

```dart
import 'package:ack/ack.dart';
import 'package:ack_annotations/ack_annotations.dart';

class Money {
  final int cents;
  const Money(this.cents);
}

class MoneySchemaProvider implements SchemaProvider<Money> {
  const MoneySchemaProvider();

  @override
  AckSchema<Money> get schema => Ack.object({
    'cents': Ack.integer(),
  }).transform((value) => Money(value!['cents'] as int));
}

@Schemable(useProviders: const [MoneySchemaProvider])
class Invoice {
  final Money total;

  const Invoice({required this.total});
}
```

## Discriminated Models

Use sealed roots for discriminated unions.

```dart
@Schemable(discriminatorKey: 'type')
sealed class Notification {
  const Notification();
}

@Schemable(discriminatorValue: 'email')
class EmailNotification extends Notification {
  final String subject;

  const EmailNotification({required this.subject});
}
```

## Additional Properties (Passthrough)

Use `@Schemable(additionalProperties: true)` to generate
`Ack.object(..., additionalProperties: true)` (equivalent passthrough behavior
for unknown keys).

## Compatibility

These APIs still exist for migration, but new code should avoid them:

- `@AckModel()` and `ackModel`
- `AckField`

`AckField` is deprecated and no longer drives generation. Use constructor
 parameter annotations instead.

## Related Packages

- Runtime schemas: [`ack`](../../README.md)
- Code generation: [`ack_generator`](../ack_generator/README.md)
