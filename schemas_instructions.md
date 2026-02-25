# Ack Schema Reference

This guide summarizes every core schema available in the `ack` package and shows how to compose them using the fluent API. Each section includes a concise example that you can drop into your own project or adapt for documentation tests.

## Getting Started

```dart
import 'package:ack/ack.dart';

void main() {
  final schema = Ack.string().minLength(2);
  final result = schema.safeParse('Ack');
  if (result.isOk) {
    print('Valid: \\${result.getOrThrow()}');
  }
}
```

All schemas expose `validate`, `safeParse`, `tryParse`, and `parseOrThrow`. Fluent helpers like `.nullable()`, `.optional()`, `.withDefault()`, `.describe()`, `.refine()`, and `.transform()` are available on every schema unless noted.

---

## Primitive Schemas

### StringSchema

```dart
final displayNameSchema = Ack.string()
    .minLength(2)
    .maxLength(50)
    .describe('User display name')
    .refine((value) => value.trim() == value,
        message: 'Leading and trailing whitespace is not allowed.');

final ok = displayNameSchema.safeParse('Ack');            // Ok('Ack')
final fail = displayNameSchema.safeParse(' a ');          // SchemaConstraintsError
```

Use `.strictParsing()` to disable the fallback that converts primitives (int/double/bool) to strings. The `string_schema_extensions.dart` file adds helpers like `.email()`, `.url()`, `.minLength()`, etc.

### IntegerSchema

```dart
final quantitySchema = Ack.integer()
    .min(1)
    .max(100)
    .withDefault(1);

quantitySchema.validateOrThrow(5);      // passes
quantitySchema.safeParse('3');           // Ok(3) via lenient parsing
Ack.integer(strictPrimitiveParsing: true).safeParse('3'); // Fails
```

When `strictPrimitiveParsing` is `true`, only integers are accepted—strings and doubles become validation failures.

### DoubleSchema

```dart
final priceSchema = Ack.double()
    .min(0)
    .refine((value) => value % 0.05 == 0,
        message: 'Prices must align with 5¢ increments.');

priceSchema.safeParse(19.95);           // Ok(19.95)
Ack.double(strictPrimitiveParsing: true).safeParse(10); // Fails (int cannot be coerced)
```

### BooleanSchema

```dart
final enabledSchema = Ack.boolean().withDefault(false);

enabledSchema.parseOrThrow(true);       // returns true
Ack.boolean().safeParse('true');          // Ok(true) when strict parsing is off
Ack.boolean().strictParsing().safeParse('true'); // Fails
```

### AnySchema

`Ack.any()` accepts every non-null value and still participates in fluent operations.

```dart
final passthroughSchema = Ack.any().describe('Unstructured payload');

passthroughSchema.safeParse({'anything': 'goes'});
```

---

## Collection Schemas

### ListSchema

```dart
final tagsSchema = Ack.list(Ack.string().minLength(1)).minLength(1);

final ok = tagsSchema.safeParse(['dart', 'ack']);          // Ok([...])
final fail = tagsSchema.safeParse(['']);                   // SchemaConstraintsError

// Nullable list items must wrap the inner schema with .nullable()
final optionalInts = Ack.list(Ack.integer().nullable());
```

When an inner schema resolves to `null` for a non-nullable list item, Ack raises a `SchemaValidationError` so you never lose values silently.

### ObjectSchema

```dart
final userSchema = Ack.object({
  'id': Ack.string().minLength(1),
  'email': Ack.string().email(),
  'age': Ack.integer().optional().nullable(),
}, additionalProperties: false);

final ok = userSchema.safeParse({
  'id': 'usr_1',
  'email': 'hi@example.com',
});

final fail = userSchema.safeParse({'email': 'missing id'});
```

Use `.optional()` to mark a property as omit-able. `.nullable()` allows `null` values but still requires the field to exist. Set `additionalProperties: true` when you want to forward unknown keys in your schema validation.

### Optional vs Nullable

```dart
final profileSchema = Ack.object({
  'displayName': Ack.string().minLength(3),
  'nickname': Ack.string().minLength(3).optional(),   // can be omitted entirely
  'bio': Ack.string().minLength(3).nullable(),        // key must exist but may be null
});

profileSchema.safeParse({
  'displayName': 'Ack',                                 // nickname omitted → Ok
  'bio': null,                                          // null allowed because nullable()
});
```

Optional schemas validate their defaults through the underlying schema, so
`Ack.string().minLength(5).optional().withDefault('x')` fails fast.

---

## Union and Polymorphic Schemas

### AnyOfSchema

```dart
final idSchema = Ack.anyOf([
  Ack.string().uuid(),
  Ack.integer().positive(),
]);

idSchema.safeParse('74b5f11c-7e7a-4d0f-9dd6-2af961af0d41'); // Ok
idSchema.safeParse(-1);                                     // SchemaNestedError
```

The first schema that succeeds wins; failures aggregate into a nested error payload.

### DiscriminatedObjectSchema

```dart
final shapeSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {
    'circle': Ack.object({
      'type': Ack.literal('circle'),
      'radius': Ack.double().positive(),
    }),
    'rectangle': Ack.object({
      'type': Ack.literal('rectangle'),
      'width': Ack.double().positive(),
      'height': Ack.double().positive(),
    }),
  },
);

shapeSchema.safeParse({'type': 'circle', 'radius': 10}); // Ok
shapeSchema.safeParse({'type': 'triangle'});              // SchemaConstraintsError
```

Ack automatically injects JSON Schema information so each branch constrains the discriminator with a `const` value.

---

## Advanced Composition

### Refinements

`refine` lets you bolt on business rules after base validation:

```dart
Ack.integer().min(0).refine((n) => n.isEven, message: 'Must be even');
```

### Transformations

`transform` creates a new schema whose output type can differ from the input.

```dart
final dateSchema = Ack.string()
    .minLength(10)
    .transform<DateTime>((value) => DateTime.parse(value!));

dateSchema.safeParse('2024-06-01');      // Ok(DateTime)
dateSchema.safeParse('invalid');         // SchemaConstraintsError
```

If your transformer throws or returns `null` without calling `.nullable()`, Ack surfaces a `SchemaTransformError`.

### Defaults

Defaults apply before nullability checks and still go through validation:

```dart
final displayOrder = Ack.integer().min(1).withDefault(1);
displayOrder.safeParse(null); // Ok(1)
```

### JSON Schema Export

Every schema exposes `toJsonSchema()` for tooling interoperability:

```dart
final jsonSchema = userSchema.toJsonSchema();
print(jsonSchema['type']); // object
```

---

## Putting It Together

```dart
final productSchema = Ack.object({
  'id': Ack.string().minLength(3),
  'name': Ack.string().minLength(2).describe('Product display name'),
  'price': Ack.double().min(0),
  'tags': Ack.list(Ack.string().minLength(1)).optional(),
  'metadata': Ack.any().optional(),
}).refine((product) {
  final tags = product['tags'] as List<String>?;
  return tags == null || tags.toSet().length == tags.length;
}, message: 'Tags must be unique.');

final result = productSchema.safeParse({
  'id': 'P-1001',
  'name': 'Ack Reference Guide',
  'price': 29.99,
  'tags': ['docs', 'ack'],
});

if (result.isOk) {
  print('Valid product: \\${result.getOrThrow()}');
}
```

Use this file as a living reference. Each example aligns with tests under `packages/ack/test`, so keeping them in sync ensures both documentation and behaviour stay correct.
