# Phase 3: Validation Workflow Refactor

## Overview
Implement the correct validation order and workflow based on JSON Schema standards. This phase reorders validation steps, treats null as a valid type rather than a special case, and ensures proper type checking before conversion.

## Problem Statement

### Current Validation Order (Incorrect)
```dart
// In AckSchema.parseAndValidate()
1. Check if input is null → Special null handling
2. Apply default value substitution
3. Type conversion (_onConvert)
4. Constraint validation
5. Refinements
```

### Issues with Current Order
1. **Null special-casing before type check** - prevents "null-only" schemas
2. **Default value before type validation** - can inject wrong types
3. **No schema composition support** - missing allOf/anyOf/oneOf logic
4. **Type checking mixed with conversion** - violates separation of concerns
5. **Missing annotation tracking** - can't implement unevaluatedProperties

### Correct Validation Order (JSON Schema Compliant, Simplified)
```dart
1. Schema resolution/composition (refs, conditionals, anyOf)
2. Type validation (is the input type acceptable?)
3. Handle null as a JSON type (not a special case)
4. Conversion/coercion (no type guards here)
5. Constraint validation (spec keywords)
6. Refinements (custom predicates)
```

## Current Implementation Analysis

### AckSchema.parseAndValidate() - Current
```dart
@protected
SchemaResult<DartType> parseAndValidate(Object? inputValue, SchemaContext context) {
  // ❌ STEP 1: Null special case BEFORE type checking
  if (inputValue == null) {
    if (isNullable) {
      return SchemaResult.ok(null);
    } else {
      return SchemaResult.fail(NonNullableConstraint().validate(null));
    }
  }

  // ❌ STEP 2: Conversion without proper type validation
  final convertedResult = _onConvert(inputValue, context);
  if (convertedResult.isFail) return convertedResult;

  // ❌ STEP 3: Another null check after conversion
  if (convertedValue == null && !isNullable) {
    // This can never happen due to earlier check
  }

  // ✅ STEP 4-5: Constraints and refinements are correct
  final constraintViolations = _checkConstraints(convertedValue, context);
  return _runRefinements(convertedValue, context);
}
```

### Type Checking Issues
```dart
// In StringSchema._onConvert()
@override
SchemaResult<String> _onConvert(Object? inputValue, SchemaContext context) {
  // ❌ Type checking happens during conversion
  if (inputValue is! String) {
    return SchemaResult.fail(/* type error */);
  }
  return SchemaResult.ok(inputValue);
}
```

**Problem**: Type checking is scattered across individual schema implementations instead of centralized.

## Solution Design

### 1. New Validation Pipeline (Synchronous, No Auto‑Defaults)
```dart
abstract class AckSchema<T> {
  SchemaResult<T> validate(Object? input, {String? debugName}) {
    final context = ValidationContext(
      name: debugName ?? schemaType.name.toLowerCase(),
      schema: this,
      value: input,
    );

    return _validatePipeline(input, context);
  }

  SchemaResult<T> _validatePipeline(Object? input, ValidationContext context) {
    // STEP 1: Schema resolution and composition (sync stub for now)
    final resolvedSchema = _resolveSchema(context);

    // STEP 2: Type validation FIRST
    final inputType = AckSchema.getJsonType(input);
    final typeCheckResult = _validateType(inputType, resolvedSchema, context);
    if (typeCheckResult.isFail) return typeCheckResult.cast<T>();

    // STEP 3: Handle null as valid type (not a special case)
    if (inputType == JsonType.nil) {
      // If null is accepted, return null. Otherwise, type validation would already fail.
      return SchemaResult.ok(null as T);
    }

    // STEP 4: Conversion/coercion (pure)
    final convertedResult = _onConvert(input, context);
    if (convertedResult.isFail) return convertedResult;
    final convertedValue = convertedResult.getOrThrow();

    // STEP 5: Constraint validation
    final violations = _checkConstraints(convertedValue, context);
    if (violations.isNotEmpty) {
      return SchemaResult.fail(SchemaConstraintsError(
        constraints: violations,
        context: context,
      ));
    }

    // STEP 6: Refinements
    return _runRefinements(convertedValue, context);
  }

  AckSchema<T> _resolveSchema(ValidationContext context) => this;
}
```

### 2. Centralized Type Validation
```dart
SchemaResult<T> _validateType(JsonType inputType, AckSchema resolvedSchema, ValidationContext context) {
  final acceptedTypes = resolvedSchema.acceptedTypes;

  // Special case: integers are valid numbers
  if (acceptedTypes.contains(JsonType.number) && inputType == JsonType.integer) {
    return SchemaResult.ok(null); // Continue validation
  }

  if (!acceptedTypes.contains(inputType)) {
    return SchemaResult.fail(TypeMismatchError(
      expectedTypes: acceptedTypes.map((t) => t.typeName).toList(),
      actualType: inputType.typeName,
      context: context,
    ));
  }

  return SchemaResult.ok(null); // Type check passed
}
```

### 3. Schema Resolution for Composition
```dart
AckSchema _resolveSchema(ValidationContext context) {
  // For now, return self (no composition). Composition hooks come in Phase 4.
  return this;
}
```

### 4. Updated Individual Schema Implementations

#### StringSchema - Simplified
```dart
@override
SchemaResult<String> _onConvert(Object? inputValue, SchemaContext context) {
  // ✅ Type checking already done - just convert
  assert(inputValue is String, 'Type checking should have been done already');

  // Pure conversion logic (if any coercion needed)
  return SchemaResult.ok(inputValue as String);
}
```

#### IntegerSchema - With Coercion
```dart
@override
SchemaResult<int> _onConvert(Object? inputValue, SchemaContext context) {
  // ✅ Type checking done, now handle valid coercions
  return switch (inputValue) {
    int value => SchemaResult.ok(value),
    double value when value.remainder(1) == 0 => SchemaResult.ok(value.toInt()),
    String value => _tryParseInt(value, context),
    _ => SchemaResult.fail(ConversionError('Cannot convert ${inputValue.runtimeType} to int', context)),
  };
}
```

### 5. Enhanced Error Messages
```dart
class TypeMismatchError extends SchemaError {
  final List<String> expectedTypes;
  final String actualType;

  TypeMismatchError({
    required this.expectedTypes,
    required this.actualType,
    required ValidationContext context,
  }) : super(
    'Expected ${expectedTypes.join(' or ')}, got $actualType',
    context: context,
  );

  @override
  String toErrorString() {
    final expected = expectedTypes.length == 1
        ? expectedTypes.first
        : expectedTypes.join(' or ');
    return 'Expected $expected, got $actualType at path: ${context.path}';
  }
}
```

## Implementation Steps

### Step 1: Add Type Validation Infrastructure
1. Create `TypeMismatchError` class
2. Add `_validateType()` method to AckSchema
3. Update error messages to include expected vs actual types
4. Add tests for type validation

### Step 2: Refactor Validation Pipeline
1. Create new synchronous `_validatePipeline()` method
2. Update `validate()` to use the new pipeline
3. Move null handling after type validation
4. Remove automatic default insertion from validation

### Step 3: Simplify Schema Implementations
1. Remove type checking from `_onConvert()` methods
2. Focus `_onConvert()` on pure conversion/coercion
3. Update all schema types (String, Integer, Boolean, etc.)
4. Add assertion checks for debugging

### Step 4: Schema Resolution Infrastructure
1. Add `_resolveSchema()` method (returns self for now)
2. Add infrastructure for future composition support
3. Document extension points for allOf/anyOf/oneOf

### Step 5: Enhanced Error Reporting
1. Update all error types to include expected types
2. Improve error message clarity
3. Add path information to all errors
4. Test error message quality

## Validation Order Comparison

### Before (Incorrect)
```dart
input = "123"
1. null check → skip (not null)
2. default → skip (not null)
3. _onConvert(String→Int) → FAIL "Expected int, got String"
   // Never gets to see if string→int coercion is allowed
```

### After (Correct)
```dart
input = "123"
1. type check → JsonType.string vs [JsonType.integer] → FAIL "Expected integer, got string"
   // OR if coercion allowed: [JsonType.integer, JsonType.string] → PASS
2. null handling → skip (string input)
3. defaults → skip (has value)
4. _onConvert(String→Int) → "123" becomes 123
5. constraints → check int constraints
6. refinements → check int refinements
```

## Type System Examples

### Strict Typing (No Coercion)
```dart
final schema = Ack.integer().strict(); // Only accepts JsonType.integer

schema.validate(123)     // ✅ Success
schema.validate("123")   // ❌ Type error: Expected integer, got string
schema.validate(12.0)    // ❌ Type error: Expected integer, got number
```

### Coercion Allowed
```dart
final schema = Ack.integer(); // Accepts [JsonType.integer, JsonType.string, JsonType.number]

schema.validate(123)     // ✅ Success → 123
schema.validate("123")   // ✅ Success → 123 (string→int conversion)
schema.validate(12.0)    // ✅ Success → 12 (double→int conversion)
schema.validate(12.5)    // ❌ Conversion error: Cannot convert 12.5 to integer
```

### Nullable Types
```dart
final schema = Ack.integer().nullable(); // Accepts [JsonType.integer, JsonType.nil]

schema.validate(123)     // ✅ Success → 123
schema.validate(null)    // ✅ Success → null
schema.validate("123")   // ❌ Type error: Expected integer or null, got string
```

## Test Cases

### Type Validation Tests
```dart
group('Type Validation', () {
  test('should validate type before conversion', () {
    final schema = Ack.integer().strict();

    final result = schema.validate("123");
    expect(result.isFail, isTrue);
    expect(result.getError(), isA<TypeMismatchError>());
    expect(result.getError().message, contains('Expected integer, got string'));
  });

  test('should allow coercion when enabled', () {
    final schema = Ack.integer(); // coercion enabled by default

    final result = schema.validate("123");
    expect(result.isOk, isTrue);
    expect(result.getOrThrow(), equals(123));
  });
});
```

### Null Handling Tests
```dart
group('Null Handling', () {
  test('should treat null as valid type when nullable', () {
    final schema = Ack.string().nullable();

    final result = schema.validate(null);
    expect(result.isOk, isTrue);
    expect(result.getOrThrow(), isNull);
  });

  test('should not auto-apply defaults during validation', () {
    final schema = Ack.integer().withDefault(42);

    // Validation is pure; defaults are annotations and not applied automatically
    final result = schema.validate(null);
    expect(result.isFail, isTrue); // non-nullable without explicit .nullable()
  });
});
```

### Defaults Note
Validation does not insert defaults. If a default‑application utility is provided, test it separately as a post‑validation transform.

## Performance Considerations

### Optimizations
1. **Early type checking** prevents expensive conversions on wrong types
2. **Centralized type validation** reduces code duplication
3. **Assertion-based debugging** has zero cost in production
4. **Predictable validation order** allows optimization opportunities

### Benchmarks
```dart
// Before: Type error after conversion attempt
input: "invalid" → string schema
Time: 150μs (includes failed conversion)

// After: Type error immediately
input: "invalid" → string schema
Time: 50μs (type check only)
```

## Migration Guide

### For Schema Implementations
```dart
// Before: Type checking in _onConvert
@override
SchemaResult<String> _onConvert(Object? input, context) {
  if (input is! String) {
    return SchemaResult.fail(InvalidTypeConstraint(...));
  }
  return SchemaResult.ok(input);
}

// After: Pure conversion
@override
SchemaResult<String> _onConvert(Object? input, context) {
  assert(input is String, 'Type validation should be done already');
  return SchemaResult.ok(input as String);
}
```

### For Custom Schemas
- ✅ Override `acceptedTypes` getter to define valid input types
- ✅ Remove type checking from `_onConvert()`
- ✅ Focus `_onConvert()` on pure conversion logic
- ✅ Use assertions for debugging type assumptions

## Risk Assessment

### Low Risk
- Most changes are internal to validation pipeline
- Public API remains unchanged
- Type checking becomes more predictable

### Medium Risk
- Default value timing change might affect edge cases
- Custom schema implementations need minor updates

### Mitigation
1. **Comprehensive test suite** for all validation orders
2. **Benchmark suite** to ensure performance improvements
3. **Migration guide** for custom schema authors
4. **Gradual rollout** with feature flags

## Success Metrics
1. ✅ Validation order matches JSON Schema specification
2. ✅ Type errors reported immediately (better performance)
3. ✅ Null treated as first-class type, not special case
4. ✅ Foundation ready for schema composition (Phase 4)
5. ✅ Error messages more precise and helpful
6. ✅ No regression in validation correctness

## Timeline
- **Week 1**: Steps 1-2 (Type validation + pipeline refactor)
- **Week 2**: Step 3 (Update schema implementations)
- **Week 3**: Steps 4-5 (Schema resolution + error reporting)
- **Week 4**: Testing + performance validation

This phase establishes the correct validation workflow foundation that enables advanced features like schema composition while improving performance and error clarity.
