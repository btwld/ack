# Custom field types in @Schemable classes

Owning guide: [Type-safe schemas](https://github.com/btwld/ack/blob/v2.0.0-beta.3/docs/core-concepts/typesafe-schemas.mdx) ("Custom schemas and types that own their schema").

A field whose type the generator can't infer needs a schema that **produces that type**, usually a codec. Ack looks for one in this order:

1. `@Schemable(schemas: [fn])` on the class, on the union base, or on a `library;` directive (yours or an imported one). `fn` is a tear-off of a top-level function that returns `AckSchema<Boundary, T>`.
2. A `static` member named `schema` on the type itself (field or getter, typed `AckSchema<Boundary, T>`).
3. A single top-level `AckSchema<Boundary, T>` variable, getter, or zero-argument function in the current library.

## A type you own

```dart
final class Money {
  const Money(this.cents);
  final int cents;
  static final schema = Ack.integer().min(0).codec<Money>(
    decode: Money.new,
    encode: (m) => m.cents,
  );

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;
  @override
  int get hashCode => cents.hashCode;
}
// A field `required final Money tax` now resolves to Money.schema, including inside List<Money> and Map<String, Money>.
```

An extension type works the same way. Declare it `implements Object`. An enum with a static `schema` uses that instead of `Ack.enumValues`.

## A generic wrapper

A static field can't use type parameters, so declare a static generic method. `static AckSchema<String, Cmd<A>> schema<A>() => ...` is called with the field's type arguments. The form with one `AckSchema<Object, A>` parameter per type parameter receives the inferred schema of each type argument.

## A third-party type

```dart
@Schemable(schemas: [hexColorSchema])
final class const Theme({required final HexColor primary}) with _$ThemeAck;

AckSchema<String, HexColor> hexColorSchema() => Ack.string()
    .matches(r'^#[0-9a-f]{6}$')
    .codec<HexColor>(decode: HexColor.parse, encode: (c) => c.hex);
```

## Rules

- Put wire constraints **before** `.codec(...)` so they validate the boundary value and export.
- The schema must produce exactly the field type; otherwise the build fails.
- Give a value type `==` and `hashCode` (or make it an extension type over a primitive). The generated model's `==` compares fields with `==`, so without it a `toJson()` round trip never compares equal.
- Presence still comes from the field (`T`, `T?`, default). A custom schema's own `optional`/`nullable`/default doesn't carry over.
- Map keys must be `String`. Write `dynamic` as `Object?`. `List<T?>` is rejected.
- A generated part can't add imports, so every type a field names has to be imported by the annotated library itself.
