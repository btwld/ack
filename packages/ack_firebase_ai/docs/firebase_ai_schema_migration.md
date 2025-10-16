# Firebase AI Schema Migration Guide

## Context

We migrated `AckSchema.toFirebaseAiSchema()` from returning a `Map<String, Object?>`
to emitting the typed `firebase_ai.Schema` class. This connector now mirrors the
official Firebase AI schema surface, reducing manual JSON handling and avoiding
type mismatches when configuring `GenerationConfig.responseSchema`.

The `Schema` class lives in `package:firebase_ai/src/schema.dart`. It exposes the
constructors and fields shown below (excerpted from the Firebase AI SDK):

```dart
final class Schema {
  Schema(
    this.type, {
    this.format,
    this.description,
    this.title,
    this.nullable,
    this.enumValues,
    this.items,
    this.minItems,
    this.maxItems,
    this.minimum,
    this.maximum,
    this.properties,
    this.optionalProperties,
    this.propertyOrdering,
    this.anyOf,
  });

  Schema.object({
    required Map<String, Schema> properties,
    List<String>? optionalProperties,
    List<String>? propertyOrdering,
    String? description,
    String? title,
    bool? nullable,
  }) : this(
          SchemaType.object,
          properties: properties,
          optionalProperties: optionalProperties,
          propertyOrdering: propertyOrdering,
          description: description,
          title: title,
          nullable: nullable,
        );
  // … see firebase_ai/src/schema.dart for the full definition.
}
```

Refer to the upstream source for the complete class (it includes array, enum,
number, boolean helpers, plus `anyOf` support and the full `SchemaType` enum).

## Migration Summary

- **Old API**: `Map<String, Object?>` representation based on ACK’s
  `toJsonSchema()` helper. Tests and consumers accessed keys via map lookups.
- **New API**: Strongly typed `Schema` instances from Firebase AI SDK. Tests use
  `Schema.type`, `properties`, `optionalProperties`, etc. Internal converter now
  delegates to the platform constructors to guarantee parity with Gemini.
- **Dependency**: Added `firebase_ai` to `pubspec.yaml` to enable typed Schema
  usage (completed in version `1.0.0-beta.2`).
- **Testing**: Because `firebase_ai` depends on Flutter, run `flutter test`
  (not `dart test`). Documentation and CI scripts must be updated accordingly.

## Key Behaviour Changes

| Area | Before | After |
|------|--------|-------|
| Return type | `Map<String, Object?>` | `Schema` (Firebase AI) |
| Object required handling | Manual `required` array | `optionalProperties` drives `required` inside `Schema.toJson()` |
| Enum support | Relied on JSON `enum` array | Uses `Schema.enumString()` with `enumValues` |
| Any schema | Returned `{ 'type': 'object' }` map | Builds `Schema.object(properties: const {})` respecting `nullable` |
| anyOf | Took first schema only | Uses `Schema.anyOf(schemas: …)` preserving all branches |
| Discriminated unions | Fell back to blank object | Normalizes each branch, injects discriminator enum, then wraps with `Schema.anyOf` |
| Tests | Looked for map keys | Assert against `SchemaType`, `properties`, `optionalProperties`, `toJson()` |

## Limitations & Follow‑ups

- **String length metadata**: Firebase AI’s `Schema` does not surface
  `minLength`/`maxLength` yet. We still enforce those constraints with ACK on
  parse. Track upstream SDK updates and add mapping once supported.
- **Flutter dependency**: The package now requires Flutter toolchain for tests.
  Consider isolating a pure-Dart facade if we need to keep headless CI lanes.
- **Discriminated schemas**: Current approach clones each branch and adds a
  discriminator enum. Review once Firebase AI exposes native discriminated
  union support.
- **Additional properties**: ACK `ObjectSchema` supports `additionalProperties`;
  Firebase AI’s schema currently does not. We always emit closed objects.
- **Transformed schemas**: Still throw `UnsupportedError` up front so callers
  can unwrap transforms manually.

## Validation Checklist

1. **Converters**
   - [ ] Review `_convertObject` optional property handling vs. Firebase AI
         expectations.
   - [ ] Confirm `_convertDiscriminated` output matches desired Gemini prompts.
2. **Tests**
   - [ ] All existing suites pass under `flutter test`.
   - [ ] Add coverage for nullable enums and nested anyOf chains if needed.
3. **Documentation**
   - [ ] README reflects typed API and Flutter requirement (✔ already updated).
   - [ ] Update any downstream consumers referencing raw maps.
4. **Release**
   - [ ] Publish `1.0.0-beta.2` after review.
   - [ ] Communicate migration guidance to downstream teams.

## Review Pointers

- Compare generated `Schema` JSON (`schema.toJson()`) against the previous map
  snapshots to ensure no behavioural regressions.
- Consider adding a smoke test that instantiates `GenerationConfig` with the
  new schema to confirm compatibility with the Firebase AI client.
- If we eventually need a pure JSON schema for other services, keep the old
  converter behind a different extension (e.g., `.toJsonSchemaMap()`).

