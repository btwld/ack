# Ack Example Package

This package demonstrates both code-generation directions with `@Schemable()`:
schemas converted to immutable models, and hand-written classes converted to
codec schemas. Annotated examples declare both `.ack.dart`
and `.ack.g.dart` parts.

## Included examples

- Primitive typed schemas in
  [`lib/schema_types_primitives.dart`](lib/schema_types_primitives.dart)
- Object schemas in
  [`lib/schema_types_simple.dart`](lib/schema_types_simple.dart)
- Discriminated schemas in
  [`lib/schema_types_discriminated.dart`](lib/schema_types_discriminated.dart)
- Built-in and custom codec schemas in
  [`lib/schema_types_transforms.dart`](lib/schema_types_transforms.dart)
- Edge cases and strict resolution in
  [`lib/schema_types_edge_cases.dart`](lib/schema_types_edge_cases.dart)
- Cross-schema object models in [`lib/pet.dart`](lib/pet.dart),
  [`lib/user_with_color.dart`](lib/user_with_color.dart), and
  [`lib/additional_properties_example.dart`](lib/additional_properties_example.dart)
- Codecs (built-in and custom) in
  [`lib/codecs_example.dart`](lib/codecs_example.dart)
- Hand-written class-first models and sealed unions in
  [`lib/class_first_models.dart`](lib/class_first_models.dart), including the
  required `_$ClassAck` mixin, `AccountSchema.schema` / `wireSchema`, and union
  facades backed by private codecs

## Try both generation directions

The checked-in generated parts let you use the examples immediately:

```dart
import 'package:ack_example/class_first_models.dart';
import 'package:ack_example/schema_types_simple.dart';

void main() {
  final user = User.parse({'name': 'Ada', 'age': 36, 'active': true});
  print(user.name);

  final account = Account.fromJson({'display_name': 'Ada'});
  print(account.toJson()); // {'display_name': 'Ada', 'role': 'member'}
}
```

## Running the examples

```bash
dart run melos bootstrap
cd example
dart run build_runner build
dart test
```
