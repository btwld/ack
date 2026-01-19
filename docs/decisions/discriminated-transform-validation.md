# Decision: Discriminated Union Child Schema Validation

## Issue Summary

**Bug Report:** `Ack.discriminated()` fails with a cryptic type cast error when used with child schemas that have `.transform<T>()` returning non-Map types.

**Original Error:**
```
type 'Cat' is not a subtype of type 'Map<String, Object?>' in type cast
```

**Location:** `packages/ack/lib/src/schemas/discriminated_object_schema.dart`

## The Problem

Users were attempting to use pre-transformed child schemas inside `Ack.discriminated()`:

```dart
// User's incorrect pattern
final catSchema = Ack.object({
  'type': Ack.literal('cat'),
  'name': Ack.string(),
}).transform<Cat>((map) => Cat(map!['name'] as String));

final dogSchema = Ack.object({
  'type': Ack.literal('dog'),
  'name': Ack.string(),
}).transform<Dog>((map) => Dog(map!['name'] as String));

final animalSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {
    'cat': catSchema,  // Returns Cat, not Map
    'dog': dogSchema,  // Returns Dog, not Map
  },
);

// Throws cryptic cast error
animalSchema.parse({'type': 'cat', 'name': 'Whiskers'});
```

## Decision Options Considered

### Option 1: Change Return Type to Object (REJECTED)

Change `DiscriminatedObjectSchema` to extend `AckSchema<Object>` instead of `AckSchema<MapValue>`, allowing child schemas to return any type.

**Pros:**
- Would allow the user's pattern to work
- More flexible

**Cons:**
- Deviates from Zod's behavior where `discriminatedUnion` works specifically with object schemas
- Breaks the semantic contract that discriminated unions work with objects
- Makes the return type less predictable
- Requires downstream code to handle arbitrary types

### Option 2: Add Validation with Helpful Error (ACCEPTED)

Keep `DiscriminatedObjectSchema` returning `MapValue` but add runtime validation with a clear error message guiding users to the correct pattern.

**Pros:**
- Maintains Zod-like semantics
- Preserves type safety
- Provides clear guidance to users
- No breaking changes to existing code

**Cons:**
- Users must learn the correct pattern
- Runtime error instead of compile-time (unavoidable in Dart due to type erasure)

## Final Decision

**We chose Option 2** - Add validation with a helpful error message.

### Reasoning

1. **Zod Compatibility:** In Zod, `z.discriminatedUnion()` specifically expects object schemas. The discriminator key must exist in all schemas as a literal. If you want to transform the result, you apply `.transform()` to the discriminated union itself.

2. **Semantic Clarity:** A discriminated union's purpose is to route validation to the correct object schema based on a discriminator property. The transformation of that object into a custom type is a separate concern that should happen after discrimination.

3. **Predictable API:** Keeping `MapValue` as the return type means users know exactly what to expect from `Ack.discriminated()` without transforms.

## Correct Usage Pattern

```dart
// Child schemas are plain object schemas (return Map)
final catSchema = Ack.object({
  'type': Ack.literal('cat'),
  'name': Ack.string(),
});

final dogSchema = Ack.object({
  'type': Ack.literal('dog'),
  'name': Ack.string(),
});

// Transform is applied to the discriminated union, not children
final animalSchema = Ack.discriminated(
  discriminatorKey: 'type',
  schemas: {
    'cat': catSchema,
    'dog': dogSchema,
  },
).transform<Animal>((map) => switch (map['type']) {
  'cat' => Cat(map['name'] as String),
  'dog' => Dog(map['name'] as String),
  _ => throw StateError('Unknown type'),
});

// Works correctly
final cat = animalSchema.parse({'type': 'cat', 'name': 'Whiskers'});
```

## Implementation Details

### Changes Made

**File:** `packages/ack/lib/src/schemas/discriminated_object_schema.dart`

1. **Documentation Update:** Added class-level documentation explaining that child schemas must return `Map<String, Object?>` and showing the correct transform pattern with a code example.

2. **Runtime Validation:** After the child schema returns its result, we check if it's a Map. If not, throw a `StateError` with a helpful message:

```dart
if (rawValue is! Map) {
  throw StateError(
    'Discriminated union child schema for "$discValueRaw" returned '
    '${rawValue.runtimeType} instead of Map. Child schemas in '
    'Ack.discriminated() must return Map types. To transform the result, '
    'use .transform() on the discriminated schema itself:\n\n'
    '  Ack.discriminated(...).transform<YourType>((map) => ...)\n',
  );
}
```

3. **Safe Casting:** Changed from direct cast to conditional cast for better safety:

```dart
final validatedValue =
    rawValue is MapValue ? rawValue : rawValue.cast<String, Object?>();
```

### Test Coverage

**File:** `packages/ack/test/integration/discriminated_child_transform_test.dart`

Four tests added:

1. `throws helpful error when child schema has non-Map transform` - Verifies the error message content
2. `correct pattern: transform on discriminated union itself` - Tests the recommended pattern
3. `correct pattern works with safeParse` - Ensures safeParse also works
4. `validation errors occur before transform` - Confirms validation order

## Verification

- Static analysis: No issues
- All 909 tests pass
- New tests specifically verify both the error case and correct usage

## Branch Information

- **Branch:** `claude/fix-discriminated-transforms-sHOui`
- **Commit:** `d59e81c`
- **Base:** `0d91c19` (Release: v1.0.0-beta.5)

## Files Changed

```
packages/ack/lib/src/schemas/discriminated_object_schema.dart  (+37 lines)
packages/ack/test/integration/discriminated_child_transform_test.dart  (+154 lines, new file)
```

## Related Patterns in Codebase

- `AnyOfSchema` uses `AckSchema<Object>` because it genuinely can return any type from heterogeneous schemas
- `ObjectSchema` uses `AckSchema<MapValue>` because it always returns maps
- `DiscriminatedObjectSchema` follows `ObjectSchema`'s pattern since it's specifically for object discrimination
