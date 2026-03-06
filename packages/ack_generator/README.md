# ack_generator

Build-time schema generation for Ack.

`ack_generator` reads `@Schemable()` models and emits schema variables such as
 `userSchema`, `invoiceSchema`, and discriminated union schemas for sealed
 hierarchies.

## Install

```yaml
dependencies:
  ack: ^1.0.0-beta.9
  ack_annotations: ^1.0.0-beta.9

dev_dependencies:
  ack_generator: ^1.0.0-beta.9
  build_runner: ^2.4.0
```

## Generate a Schema

```dart
import 'package:ack_annotations/ack_annotations.dart';

part 'user.g.dart';

@Schemable()
class User {
  final String name;
  final String email;
  final int? age;

  const User({
    required this.name,
    required this.email,
    this.age,
  });
}
```

Run the generator:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated output:

```dart
final userSchema = Ack.object({
  'name': Ack.string(),
  'email': Ack.string(),
  'age': Ack.integer().optional(),
});
```

## What the Generator Uses

The generator is constructor-driven.

- It reads the unnamed constructor by default.
- `@SchemaConstructor()` selects a different constructor.
- The selected constructor must use named parameters only.
- Parameter annotations define keys, descriptions, and constraints.
- Field annotations are no longer the primary generation surface.

```dart
@Schemable()
class Profile {
  final String displayName;
  final String email;

  const Profile({
    @SchemaKey('display_name') required this.displayName,
    @Email() required this.email,
  });
}
```

## Custom Types with Typed Providers

If a parameter type is not built in and is not another `@Schemable()` model,
 register a `SchemaProvider<T>`.

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
  final List<Money> lineItems;

  const Invoice({
    required this.total,
    required this.lineItems,
  });
}
```

The generated schema embeds the provider schema for both `Money` and
 `List<Money>`.

## Discriminated Unions

Use `discriminatedKey` on a sealed base class and `discriminatedValue` on each
 concrete subtype.

```dart
@Schemable(discriminatedKey: 'type')
sealed class Shape {
  const Shape();
}

@Schemable(discriminatedValue: 'circle')
class Circle extends Shape {
  final double radius;

  const Circle({@Positive() required this.radius});
}

@Schemable(discriminatedValue: 'rectangle')
class Rectangle extends Shape {
  final double width;
  final double height;

  const Rectangle({
    @Positive() required this.width,
    @Positive() required this.height,
  });
}
```

This produces a discriminated schema keyed by `type`.

## Notes

- The generated output is schema-first. It validates data; it does not
  automatically instantiate your model classes.
- A typed `SchemaProvider<T>` should parse to `T`. Use a transformed schema if
  the wire shape differs from the model type.
- Prefix-qualified schemable models and providers are supported.

## Compatibility

These legacy APIs still work for migration, but new code should avoid them:

- `@AckModel()` and `ackModel`
- `AckField`

## Development

Useful commands:

```bash
dart format .
dart analyze
dart test
```
