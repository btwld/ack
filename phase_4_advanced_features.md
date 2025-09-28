# Phase 4: Advanced Features

## Overview
Implement advanced validation features inspired by JSON Schema 2020-12 and dart_schema_builder analysis. This phase adds validation annotations, async validation support, schema composition, and advanced keywords like `unevaluatedProperties`.

## Problem Statement

### Missing Advanced Features
1. **No validation annotations** - can't track which properties/items were evaluated
2. **No `unevaluatedProperties` support** - can't implement conditional property validation
3. **Synchronous-only validation** - can't load remote schemas or async validation
4. **Limited schema composition** - AnyOfSchema exists but incomplete
5. **No schema references** - can't implement `$ref` or `$dynamicRef`
6. **Missing conditional schemas** - no `if/then/else` support

### Current Limitations

#### AnyOfSchema (Partial Implementation)
```dart
// Current: Returns first successful result
for (final schema in schemas) {
  final result = schema.validate(inputValue);
  if (result.isOk) {
    return SchemaResult.ok(result.getOrThrow()!);  // ❌ Early return loses annotations
  }
}
```

**Issues:**
- No annotation collection
- Can't implement `unevaluatedProperties` pattern
- Missing `allOf` and `oneOf` implementations

#### No Async Support
```dart
// All validation is synchronous
SchemaResult<T> validate(Object? value) // ❌ Can't load remote schemas
```

## Solution Design

### 1. Validation Annotations (Minimal)

To power `unevaluatedProperties` and `unevaluatedItems` without expanding the public API:
- Keep `SchemaResult` as‑is (no annotation payload).
- Add two mutable sets to `ValidationContext`: `evaluatedProperties`, `evaluatedItems`.
- Applicators and composition update these sets as they evaluate fields/items.
- This minimal design avoids duplicating other packages’ richer annotation systems while enabling unevaluated* semantics.

### 2. Async Validation Support (Additive, Non‑blocking)

Add an optional `validateAsync()` where needed (e.g., resolving references). Keep sync `validate()` intact — no blocking/waiting:
```dart
extension AckSchemaAsync<T> on AckSchema<T> {
  Future<SchemaResult<T>> validateAsync(Object? input, {String? debugName}) async {
    // Default: delegate to sync validate; override in specific schemas if async is required
    return validate(input, debugName: debugName);
  }
}
```
If remote I/O is needed for `$ref`, provide it via an optional plugin so the core remains synchronous and lightweight.

#### Schema Registry for References (In‑Memory in Core)
```dart
class SchemaRegistry {
  final Map<Uri, AckSchema> _schemas = {};

  void register(Uri uri, AckSchema schema) {
    _schemas[uri] = schema;
  }

  AckSchema? resolve(Uri uri) => _schemas[uri];
}
```
Remote HTTP resolution is intentionally excluded from core to avoid duplication. Offer a separate extension for network loading if needed.

### 3. Enhanced Schema Composition

#### AllOfSchema Implementation
```dart
final class AllOfSchema extends AckSchema<Object> {
  final List<AckSchema> schemas;

  const AllOfSchema(this.schemas) : super(schemaType: SchemaType.unknown);

  @override
  SchemaResult<Object> validate(Object? input, {String? debugName}) {
    final context = ValidationContext(name: debugName ?? 'allOf', schema: this, value: input);
    final errors = <SchemaError>[];

    // All schemas must pass
    for (final schema in schemas) {
      final result = schema.validate(input);
      if (result.isFail) errors.add(result.getError());
    }

    if (errors.isNotEmpty) {
      return SchemaResult.fail(SchemaNestedError(errors: errors, context: context));
    }

    return SchemaResult.ok(input as Object);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    return {
      'allOf': schemas.map((s) => s.toJsonSchema()).toList(),
    };
  }
}
```

#### AnyOfSchema (Annotation-Aware Short‑Circuit)
```dart
final class AnyOfSchema extends AckSchema<Object> {
  final List<AckSchema> schemas;

  const AnyOfSchema(this.schemas) : super(schemaType: SchemaType.unknown);

  @override
  SchemaResult<Object> validate(Object? input, {String? debugName}) {
    final context = ValidationContext(name: debugName ?? 'anyOf', schema: this, value: input);
    var matched = false;
    final errors = <SchemaError>[];

    final needsAnnotations = context.needsAnnotations;
    for (final schema in schemas) {
      final result = schema.validate(input);
      if (result.isOk) {
        matched = true;
        if (!needsAnnotations) break;
      } else {
        errors.add(result.getError());
      }
    }

    if (!matched) {
      return SchemaResult.fail(SchemaValidationError(
        message: 'Value does not match any of the schemas',
        context: context,
      ));
    }
    return SchemaResult.ok(input as Object);
  }
}
```

#### OneOfSchema Implementation
```dart
final class OneOfSchema extends AckSchema<Object> {
  final List<AckSchema> schemas;

  const OneOfSchema(this.schemas) : super(schemaType: SchemaType.unknown);

  @override
  SchemaResult<Object> validate(Object? input, {String? debugName}) {
    var passedCount = 0;
    final context = ValidationContext(name: debugName ?? 'oneOf', schema: this, value: input);

    for (final schema in schemas) {
      final result = schema.validate(input);
      if (result.isOk) {
        passedCount++;
      }
    }

    if (passedCount != 1) {
      return SchemaResult.fail(
        SchemaValidationError(
          message: 'Value must match exactly one schema, but matched $passedCount',
          context: context,
        ),
      );
    }

    return SchemaResult.ok(input as Object);
  }
}
```

### 4. UnevaluatedProperties Implementation (Minimal)

#### Enhanced ObjectSchema (sync, context‑based annotations)
```dart
@override
SchemaResult<Map<String, Object?>>> validate(Object? input, {String? debugName}) {
  final map = input as Map<String, Object?>;
  final result = <String, Object?>{};

  // Validate known properties first
  for (final entry in properties.entries) {
    final key = entry.key;
    final schema = entry.value;

    if (map.containsKey(key)) {
      final fieldContext = context.createChild(
        name: key,
        schema: schema,
        value: map[key],
        pathSegment: key,
      );
      final fieldResult = schema.validate(map[key]);
      if (fieldResult.isOk) {
        result[key] = fieldResult.getOrThrow();
        context.evaluatedProperties.add(key);
      } else {
        return SchemaResult.fail(fieldResult.getError());
      }
    }
  }

  // Handle unevaluated properties
  if (unevaluatedProperties != null) {
    for (final key in map.keys) {
      if (!context.evaluatedProperties.contains(key)) {
        final fieldContext = context.createChild(
          name: key,
          schema: unevaluatedProperties!,
          value: map[key],
          pathSegment: key,
        );
        final fieldResult = unevaluatedProperties!.validate(map[key]);
        if (fieldResult.isOk) {
          result[key] = fieldResult.getOrThrow();
          context.evaluatedProperties.add(key);
        } else {
          return SchemaResult.fail(SchemaValidationError(
            message: 'Unevaluated property "$key" is invalid',
            context: fieldContext,
          ));
        }
      }
    }
  }

  return SchemaResult.ok(result);
}
```

### 5. Conditional Schemas (if/then/else)

#### ConditionalSchema Implementation
```dart
final class ConditionalSchema extends AckSchema<Object> {
  final AckSchema ifSchema;
  final AckSchema? thenSchema;
  final AckSchema? elseSchema;

  const ConditionalSchema({
    required this.ifSchema,
    this.thenSchema,
    this.elseSchema,
  }) : super(schemaType: SchemaType.unknown);

  @override
  SchemaResult<Object> validate(Object? input, {String? debugName}) {
    final context = ValidationContext(name: debugName ?? 'conditional', schema: this, value: input);
    final ifResult = ifSchema.validate(input);
    if (ifResult.isOk) {
      if (thenSchema != null) {
        final thenResult = thenSchema!.validate(input);
        if (thenResult.isFail) return SchemaResult.fail(thenResult.getError());
      }
    } else {
      if (elseSchema != null) {
        final elseResult = elseSchema!.validate(input);
        if (elseResult.isFail) return SchemaResult.fail(elseResult.getError());
      }
    }
    return SchemaResult.ok(input as Object);
  }

  @override
  Map<String, Object?> toJsonSchema() {
    return {
      'if': ifSchema.toJsonSchema(),
      if (thenSchema != null) 'then': thenSchema!.toJsonSchema(),
      if (elseSchema != null) 'else': elseSchema!.toJsonSchema(),
    };
  }
}
```

### 6. Schema References

#### RefSchema Implementation (In‑Memory)
```dart
final class RefSchema extends AckSchema<Object> {
  final String ref;
  final SchemaRegistry registry;

  const RefSchema({
    required this.ref,
    required this.registry,
  }) : super(schemaType: SchemaType.unknown);

  @override
  SchemaResult<Object> validate(Object? input, {String? debugName}) {
    final context = ValidationContext(name: debugName ?? 'ref', schema: this, value: input);
    final uri = Uri.parse(ref);
    final resolvedSchema = registry.resolve(uri);
    if (resolvedSchema == null) {
      return SchemaResult.fail(SchemaResolutionError('Cannot resolve reference: $ref', context: context));
    }
    return resolvedSchema.validate(input).cast<Object>();
  }

  @override
  Map<String, Object?> toJsonSchema() {
    return {'\$ref': ref};
  }
}
```

## Implementation Steps

### Step 1: Validation Annotations Infrastructure
1. Create `ValidationAnnotations` class
2. Update `SchemaResult` to carry annotations
3. Update base validation pipeline to track annotations
4. Add tests for annotation collection and merging

### Step 2: Async Validation Support
1. Provide an optional `validateAsync()` extension (no blocking in sync)
2. Implement in‑memory `SchemaRegistry` in core
3. Defer remote HTTP references to an optional plugin/package
4. Add tests for in‑memory `$ref`

### Step 3: Enhanced Schema Composition
1. Implement `AllOfSchema`, update `AnyOfSchema`, add `OneOfSchema`
2. Add annotation collection to all composition schemas
3. Create fluent API: `Ack.allOf()`, `Ack.anyOf()`, `Ack.oneOf()`
4. Add comprehensive composition tests

### Step 4: UnevaluatedProperties Pattern
1. Add `unevaluatedProperties` support to `ObjectSchema`
2. Implement property tracking in validation
3. Add `unevaluatedItems` support to `ListSchema`
4. Add tests for complex evaluation patterns

### Step 5: Conditional Schemas
1. Implement `ConditionalSchema` for if/then/else
2. Add fluent API: `Ack.conditional()`
3. Integration with annotation system
4. Add conditional validation tests

### Step 6: Schema References
1. Implement `RefSchema` for `$ref` support
2. Add dynamic reference support (`$dynamicRef`)
3. HTTP schema loading capability
4. Add reference resolution tests

## Advanced Usage Examples

### Schema Composition
```dart
// AllOf: Must satisfy all conditions
final userSchema = Ack.allOf([
  Ack.object({'name': Ack.string()}),      // Must have name
  Ack.object({'age': Ack.integer().min(18)}),  // Must be adult
  Ack.object({'email': Ack.string().email()}), // Must have valid email
]);

// OneOf: Exactly one authentication method
final authSchema = Ack.oneOf([
  Ack.object({'password': Ack.string()}),
  Ack.object({'apiKey': Ack.string()}),
  Ack.object({'oauth': Ack.object({'token': Ack.string()})}),
]);
```

### Conditional Validation
```dart
final personSchema = Ack.conditional(
  if: Ack.object({'type': Ack.literal('employee')}),
  then: Ack.object({
    'employeeId': Ack.string().required(),
    'department': Ack.string().required(),
  }),
  else: Ack.object({
    'guestId': Ack.string().required(),
  }),
);
```

### UnevaluatedProperties
```dart
final flexibleSchema = Ack.object({
  'name': Ack.string(),
  'age': Ack.integer(),
}).unevaluatedProperties(Ack.string()); // Any other properties must be strings

// Validates:
// {'name': 'John', 'age': 30, 'hobby': 'coding'} ✅
// {'name': 'John', 'age': 30, 'invalid': 123} ❌
```

### Reference Usage (In‑Memory)
```dart
final registry = SchemaRegistry();
registry.register(Uri.parse('schema:person'), personSchema);

final schema = Ack.ref('schema:person');
final result = schema.validate(userData); // sync core
```

## Test Cases

### Annotation Collection
```dart
test('should track evaluated keys in context', () {
  final schema = Ack.object({
    'user': Ack.object({'name': Ack.string()}),
  }).unevaluatedProperties(Ack.string());

  final result = schema.validate({'user': {'name': 'John'}, 'extra': 'x'});
  expect(result.isOk, isTrue);
});
```

### Schema Composition
```dart
test('allOf should require all schemas to pass', () {
  final schema = Ack.allOf([
    Ack.object({'name': Ack.string()}),
    Ack.object({'age': Ack.integer()}),
  ]);

  expect(schema.validate({'name': 'John', 'age': 30}).isOk, isTrue);
  expect(schema.validate({'name': 'John'}).isFail, isTrue);
});
```

### UnevaluatedProperties
```dart
test('should validate unevaluated properties', () {
  final schema = Ack.allOf([
    Ack.object({'name': Ack.string()}),
  ]).unevaluatedProperties(Ack.integer());

  expect(schema.validate({'name': 'John', 'score': 100}).isOk, isTrue);
  expect(schema.validate({'name': 'John', 'score': 'invalid'}).isFail, isTrue);
});
```

## Performance Considerations

### Optimization Strategies
1. **Lazy annotation collection** - only when needed
2. **Schema caching** - parsed schemas cached by URI
3. **Parallel validation** - independent schemas validated concurrently
4. **Early termination** - stop on first error for performance-critical paths

### Performance Note
- anyOf short‑circuits when annotations are not needed; otherwise evaluates all alternatives in the current scope to ensure unevaluated* correctness.

## Migration Guide

### From Synchronous to Asynchronous
Core remains synchronous; optional plugins may introduce async resolution for `$ref`.

### New Composition APIs
```dart
// New fluent APIs
final schema = Ack.allOf([...]);
final schema = Ack.anyOf([...]);
final schema = Ack.oneOf([...]);
final schema = Ack.conditional(if: ..., then: ...);
```

## Risk Assessment

### Low Risk
- All changes are additive
- Existing APIs remain unchanged
- Async support is opt-in

### Medium Risk
- Complex annotation tracking might have edge cases
- Schema references introduce network dependencies

### Mitigation
1. **Comprehensive test suite** covering all advanced features
2. **Performance benchmarks** to ensure no regression
3. **Gradual feature rollout** with feature flags
4. **Timeout mechanisms** for remote schema loading

## Success Metrics
1. ✅ Full JSON Schema 2020-12 composition support
2. ✅ Annotation system enables unevaluatedProperties
3. ✅ Async validation for remote schemas
4. ✅ Performance competitive with dart_schema_builder
5. ✅ Rich validation patterns possible
6. ✅ Maintains Dart type safety

## Timeline
- **Week 1**: Steps 1-2 (Annotations + Async support)
- **Week 2**: Steps 3-4 (Composition + UnevaluatedProperties)
- **Week 3**: Steps 5-6 (Conditionals + References)
- **Week 4**: Performance optimization + documentation

This phase completes Ack's evolution into a full-featured JSON Schema validation library while maintaining its Dart-first approach and type safety benefits.
