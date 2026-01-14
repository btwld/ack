# Plan: Implement Equality Semantics for AckSchema Classes

## Problem Statement

All `AckSchema` subclasses are marked with `@immutable` but lack proper `==` and `hashCode` implementations. This causes:

1. Two schemas with identical configuration to be unequal (unless const)
2. Inability to use schemas reliably as Map keys or Set elements
3. Failed equality comparisons in tests and user code

**Evidence:** `packages/ack/test/schemas/equality_test.dart` contains 6 failing tests demonstrating this issue.

## Approach

Implement `operator ==` and `hashCode` for all schema classes using a consistent pattern. Since `AckSchema` is a `sealed` class, we can implement equality in each concrete subclass.

### Key Considerations

1. **Use `Object.hash()` and `Object.hashAll()`** - Dart's built-in hash combining utilities
2. **Compare Lists with `ListEquality`** from `package:collection` or use manual deep comparison
3. **Handle function fields** - `TransformedSchema.transformer` is a function; functions compare by identity only
4. **Maintain const constructors** - Don't break existing const schema capabilities

## Implementation Steps

### Step 1: Add collection dependency (if needed)

Check if `package:collection` is already a dependency. If not, add it to `packages/ack/pubspec.yaml`:

```yaml
dependencies:
  collection: ^1.18.0
```

### Step 2: Implement base class helper (optional)

Consider adding a protected helper method in `AckSchema` base class for common field comparison, or just implement in each subclass directly.

### Step 3: Implement equality for each schema class

Location: `packages/ack/lib/src/schemas/schema.dart` and its part files.

#### 3.1 StringSchema (`string_schema.dart`)

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is StringSchema &&
        runtimeType == other.runtimeType &&
        isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description &&
        defaultValue == other.defaultValue &&
        strictPrimitiveParsing == other.strictPrimitiveParsing &&
        _listsEqual(constraints, other.constraints) &&
        _listsEqual(refinements, other.refinements);

@override
int get hashCode => Object.hash(
      runtimeType,
      isNullable,
      isOptional,
      description,
      defaultValue,
      strictPrimitiveParsing,
      Object.hashAll(constraints),
      Object.hashAll(refinements),
    );
```

#### 3.2 IntegerSchema (`num_schema.dart`)

Same pattern as StringSchema - compare all fields including `strictPrimitiveParsing`.

#### 3.3 DoubleSchema (`num_schema.dart`)

Same pattern as IntegerSchema.

#### 3.4 BooleanSchema (`boolean_schema.dart`)

Same pattern as StringSchema.

#### 3.5 ListSchema<V> (`list_schema.dart`)

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is ListSchema<V> &&
        runtimeType == other.runtimeType &&
        isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description &&
        _defaultValueEquals(defaultValue, other.defaultValue) &&
        itemSchema == other.itemSchema &&  // Recursive schema equality
        _listsEqual(constraints, other.constraints) &&
        _listsEqual(refinements, other.refinements);

@override
int get hashCode => Object.hash(
      runtimeType,
      isNullable,
      isOptional,
      description,
      Object.hashAll(defaultValue ?? []),
      itemSchema,
      Object.hashAll(constraints),
      Object.hashAll(refinements),
    );
```

#### 3.6 ObjectSchema (`object_schema.dart`)

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is ObjectSchema &&
        runtimeType == other.runtimeType &&
        isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description &&
        additionalProperties == other.additionalProperties &&
        _mapsEqual(properties, other.properties) &&  // Deep map comparison
        _mapsEqual(defaultValue, other.defaultValue) &&
        _listsEqual(constraints, other.constraints) &&
        _listsEqual(refinements, other.refinements);

@override
int get hashCode => Object.hash(
      runtimeType,
      isNullable,
      isOptional,
      description,
      additionalProperties,
      Object.hashAll(properties.keys),
      Object.hashAll(properties.values),
      Object.hashAll(constraints),
      Object.hashAll(refinements),
    );
```

#### 3.7 EnumSchema<T> (`enum_schema.dart`)

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is EnumSchema<T> &&
        runtimeType == other.runtimeType &&
        isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description &&
        defaultValue == other.defaultValue &&
        _listsEqual(values, other.values) &&
        _listsEqual(constraints, other.constraints) &&
        _listsEqual(refinements, other.refinements);

@override
int get hashCode => Object.hash(
      runtimeType,
      isNullable,
      isOptional,
      description,
      defaultValue,
      Object.hashAll(values),
      Object.hashAll(constraints),
      Object.hashAll(refinements),
    );
```

#### 3.8 AnyOfSchema (`any_of_schema.dart`)

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is AnyOfSchema &&
        runtimeType == other.runtimeType &&
        isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description &&
        defaultValue == other.defaultValue &&
        _listsEqual(schemas, other.schemas) &&  // Recursive schema equality
        _listsEqual(constraints, other.constraints) &&
        _listsEqual(refinements, other.refinements);

@override
int get hashCode => Object.hash(
      runtimeType,
      isNullable,
      isOptional,
      description,
      defaultValue,
      Object.hashAll(schemas),
      Object.hashAll(constraints),
      Object.hashAll(refinements),
    );
```

#### 3.9 AnySchema (`any_schema.dart`)

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is AnySchema &&
        runtimeType == other.runtimeType &&
        isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description &&
        defaultValue == other.defaultValue &&
        _listsEqual(constraints, other.constraints) &&
        _listsEqual(refinements, other.refinements);

@override
int get hashCode => Object.hash(
      runtimeType,
      isNullable,
      isOptional,
      description,
      defaultValue,
      Object.hashAll(constraints),
      Object.hashAll(refinements),
    );
```

#### 3.10 DiscriminatedObjectSchema (`discriminated_object_schema.dart`)

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is DiscriminatedObjectSchema &&
        runtimeType == other.runtimeType &&
        isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description &&
        discriminatorKey == other.discriminatorKey &&
        _mapsEqual(schemas, other.schemas) &&
        _mapsEqual(defaultValue, other.defaultValue) &&
        _listsEqual(constraints, other.constraints) &&
        _listsEqual(refinements, other.refinements);

@override
int get hashCode => Object.hash(
      runtimeType,
      isNullable,
      isOptional,
      description,
      discriminatorKey,
      Object.hashAll(schemas.keys),
      Object.hashAll(schemas.values),
      Object.hashAll(constraints),
      Object.hashAll(refinements),
    );
```

#### 3.11 TransformedSchema<I, O> (`transformed_schema.dart`)

**Special case:** The `transformer` field is a function. Functions only compare equal by identity in Dart. Options:

1. **Option A (Recommended):** Compare by identity only for transformer - document this limitation
2. **Option B:** Exclude transformer from equality (two TransformedSchemas are equal if underlying schema and flags match)
3. **Option C:** Don't implement equality for TransformedSchema (always uses identity)

Recommended implementation (Option A):

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is TransformedSchema<InputType, OutputType> &&
        runtimeType == other.runtimeType &&
        isNullable == other.isNullable &&
        isOptional == other.isOptional &&
        description == other.description &&
        defaultValue == other.defaultValue &&
        schema == other.schema &&
        identical(transformer, other.transformer) &&  // Identity comparison for functions
        _listsEqual(constraints, other.constraints) &&
        _listsEqual(refinements, other.refinements);

@override
int get hashCode => Object.hash(
      runtimeType,
      isNullable,
      isOptional,
      description,
      defaultValue,
      schema,
      transformer.hashCode,
      Object.hashAll(constraints),
      Object.hashAll(refinements),
    );
```

### Step 4: Add helper functions

Add these helper functions in `schema.dart` (before the class definitions or as top-level private functions):

```dart
/// Deep equality check for lists
bool _listsEqual<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Deep equality check for maps (used by ObjectSchema, DiscriminatedObjectSchema)
bool _mapsEqual<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
```

### Step 5: Handle Constraint equality

Check if `Constraint` classes have proper equality. If not, they may also need `==` and `hashCode`:

Location: `packages/ack/lib/src/constraints/constraint.dart`

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is Constraint &&
        runtimeType == other.runtimeType &&
        constraintKey == other.constraintKey;

@override
int get hashCode => Object.hash(runtimeType, constraintKey);
```

### Step 6: Handle Refinement equality

Refinements are records with a function field. Similar to TransformedSchema, function equality is by identity only. This is acceptable since refinements are typically defined inline.

## Testing

### Run existing equality tests

```bash
dart test test/schemas/equality_test.dart
```

All 15 tests should pass after implementation.

### Additional test cases to add

1. **Nested schema equality**: `Ack.list(Ack.object({...}))` equals another with same structure
2. **Constraint equality**: Schemas with same constraints should be equal
3. **Refinement identity**: Schemas with same refinement function (by identity) should be equal
4. **Different constraint order**: Decide if order matters (recommend: yes, order matters)
5. **Copy equality**: `schema.copyWith()` (no changes) should equal original

## Files to Modify

1. `packages/ack/lib/src/schemas/schema.dart` - Add helper functions
2. `packages/ack/lib/src/schemas/string_schema.dart` - Add == and hashCode
3. `packages/ack/lib/src/schemas/num_schema.dart` - Add == and hashCode to IntegerSchema, DoubleSchema
4. `packages/ack/lib/src/schemas/boolean_schema.dart` - Add == and hashCode
5. `packages/ack/lib/src/schemas/list_schema.dart` - Add == and hashCode
6. `packages/ack/lib/src/schemas/object_schema.dart` - Add == and hashCode
7. `packages/ack/lib/src/schemas/enum_schema.dart` - Add == and hashCode
8. `packages/ack/lib/src/schemas/any_of_schema.dart` - Add == and hashCode
9. `packages/ack/lib/src/schemas/any_schema.dart` - Add == and hashCode
10. `packages/ack/lib/src/schemas/discriminated_object_schema.dart` - Add == and hashCode
11. `packages/ack/lib/src/schemas/transformed_schema.dart` - Add == and hashCode
12. `packages/ack/lib/src/constraints/constraint.dart` - Add == and hashCode (if missing)

## Verification Checklist

- [ ] All equality tests pass: `dart test test/schemas/equality_test.dart`
- [ ] All existing tests still pass: `melos run test:dart`
- [ ] Static analysis passes: `dart analyze packages/ack`
- [ ] Code is formatted: `dart format packages/ack`
- [ ] No new linter warnings

## Notes

- Refinements contain functions, so two schemas with "equivalent" refinement logic won't be equal unless the same function instance is used
- TransformedSchema has the same limitation with its transformer function
- This is acceptable and consistent with Dart's function equality semantics
- Document this behavior in class-level dartdoc comments
