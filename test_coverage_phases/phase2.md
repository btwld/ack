# Phase 2: ObjectSchema Advanced Scenarios 📦

## Overview
This phase covers complex interaction scenarios and edge cases for ObjectSchema extensions including merge, pick, omit, extend, partial, strict, and passthrough operations.

## Current Status
- Excellent basic coverage in `/packages/ack/test/schemas/extensions/object_schema_extensions_test.dart`
- All basic operations tested
- Missing complex edge cases and conflict scenarios

## Implementation Plan

### 2.1 Complex Merge Scenarios

#### Test: Merging schemas with conflicting property types
```dart
test('should handle conflicting property types in merge', () {
  final schema1 = Ack.object({
    'id': Ack.string(),
    'name': Ack.string(),
  });
  
  final schema2 = Ack.object({
    'id': Ack.int(), // Conflicting type
    'email': Ack.string(),
  });
  
  // The second schema should override
  final merged = schema1.merge(schema2);
  
  expect(merged.parse({'id': 123, 'name': 'John', 'email': 'john@example.com'}), equals({
    'id': 123,
    'name': 'John',
    'email': 'john@example.com',
  }));
  
  // String id should now fail
  expect(
    () => merged.parse({'id': 'abc', 'name': 'John', 'email': 'john@example.com'}),
    throwsA(isA<ValidationException>()),
  );
});
```

#### Test: Merging schemas with conflicting constraints
```dart
test('should handle conflicting constraints in merge', () {
  final schema1 = Ack.object({
    'age': Ack.int().min(0).max(100),
  });
  
  final schema2 = Ack.object({
    'age': Ack.int().min(18).max(65), // Different constraints
  });
  
  final merged = schema1.merge(schema2);
  
  // Should use schema2's constraints (18-65)
  expect(merged.parse({'age': 25}), equals({'age': 25}));
  
  expect(
    () => merged.parse({'age': 10}),
    throwsA(isA<ValidationException>()),
  );
  
  expect(
    () => merged.parse({'age': 70}),
    throwsA(isA<ValidationException>()),
  );
});
```

#### Test: Merging schemas with different nullability
```dart
test('should handle nullability conflicts in merge', () {
  final schema1 = Ack.object({
    'field': Ack.string().nullable(),
  });
  
  final schema2 = Ack.object({
    'field': Ack.string(), // Non-nullable
  });
  
  final merged = schema1.merge(schema2);
  
  // Second schema wins - field is non-nullable
  expect(
    () => merged.parse({'field': null}),
    throwsA(isA<ValidationException>()),
  );
  
  expect(merged.parse({'field': 'value'}), equals({'field': 'value'}));
});
```

#### Test: Deep merge of nested object schemas
```dart
test('should handle deep merge of nested objects', () {
  final schema1 = Ack.object({
    'user': Ack.object({
      'name': Ack.string(),
      'settings': Ack.object({
        'theme': Ack.string(),
      }),
    }),
  });
  
  final schema2 = Ack.object({
    'user': Ack.object({
      'email': Ack.string(),
      'settings': Ack.object({
        'language': Ack.string(),
      }),
    }),
  });
  
  final merged = schema1.merge(schema2);
  
  final result = merged.parse({
    'user': {
      'name': 'John',
      'email': 'john@example.com',
      'settings': {
        'theme': 'dark',
        'language': 'en',
      },
    },
  });
  
  expect(result['user']['name'], equals('John'));
  expect(result['user']['email'], equals('john@example.com'));
  expect(result['user']['settings']['theme'], equals('dark'));
  expect(result['user']['settings']['language'], equals('en'));
});
```

#### Test: Merge with circular references
```dart
test('should handle merge with circular schema references', () {
  // Create schemas that reference each other
  late final AckSchema user;
  late final AckSchema group;
  
  user = Ack.object({
    'name': Ack.string(),
    'groups': Ack.list(Ack.lazy(() => group)),
  });
  
  group = Ack.object({
    'title': Ack.string(),
    'members': Ack.list(Ack.lazy(() => user)),
  });
  
  final extendedUser = (user as ObjectSchema).merge(Ack.object({
    'email': Ack.string(),
  }));
  
  // Should handle circular references without stack overflow
  final result = extendedUser.parse({
    'name': 'John',
    'email': 'john@example.com',
    'groups': [
      {
        'title': 'Admins',
        'members': [
          {
            'name': 'Jane',
            'groups': [],
          },
        ],
      },
    ],
  });
  
  expect(result['email'], equals('john@example.com'));
});
```

### 2.2 Pick/Omit Advanced Cases

#### Test: Pick/omit with nested property paths
```dart
test('should support nested property paths in pick', () {
  final schema = Ack.object({
    'user': Ack.object({
      'name': Ack.string(),
      'email': Ack.string(),
      'address': Ack.object({
        'street': Ack.string(),
        'city': Ack.string(),
        'zip': Ack.string(),
      }),
    }),
    'metadata': Ack.object({
      'created': Ack.string(),
      'updated': Ack.string(),
    }),
  });
  
  // Should support dot notation for nested picking
  final picked = schema.pick(['user.name', 'user.address.city', 'metadata.created']);
  
  final result = picked.parse({
    'user': {
      'name': 'John',
      'address': {
        'city': 'NYC',
      },
    },
    'metadata': {
      'created': '2024-01-01',
    },
  });
  
  expect(result, equals({
    'user': {
      'name': 'John',
      'address': {
        'city': 'NYC',
      },
    },
    'metadata': {
      'created': '2024-01-01',
    },
  }));
});
```

#### Test: Pick/omit maintaining required field relationships
```dart
test('should maintain required field relationships in pick/omit', () {
  final schema = Ack.object({
    'id': Ack.string(),
    'name': Ack.string(),
    'email': Ack.string().optional(),
    'age': Ack.int().optional(),
  }).requiredProperties(['id', 'name']);
  
  // Pick should maintain required status
  final picked = schema.pick(['id', 'email']);
  
  // ID should still be required
  expect(
    () => picked.parse({'email': 'test@example.com'}),
    throwsA(isA<ValidationException>()
      .having((e) => e.message, 'message', contains('required'))),
  );
  
  // Omit should update required fields appropriately
  final omitted = schema.omit(['name']);
  
  // Name is omitted so it shouldn't be required
  expect(
    omitted.parse({'id': '123', 'age': 25}),
    equals({'id': '123', 'age': 25}),
  );
});
```

#### Test: Pick/omit with computed property names
```dart
test('should handle dynamic property selection in pick/omit', () {
  final schema = Ack.object({
    'field1': Ack.string(),
    'field2': Ack.string(),
    'field3': Ack.string(),
    'data1': Ack.int(),
    'data2': Ack.int(),
  });
  
  // Dynamically select fields
  final fieldPrefix = 'field';
  final fieldsToKeep = List.generate(3, (i) => '$fieldPrefix${i + 1}');
  
  final picked = schema.pick(fieldsToKeep);
  
  final result = picked.parse({
    'field1': 'a',
    'field2': 'b',
    'field3': 'c',
  });
  
  expect(result.keys.length, equals(3));
  expect(result.keys.every((k) => k.startsWith(fieldPrefix)), isTrue);
});
```

#### Test: Pick/omit interaction with additional properties
```dart
test('should handle pick/omit with passthrough and strict modes', () {
  final baseSchema = Ack.object({
    'id': Ack.string(),
    'name': Ack.string(),
    'email': Ack.string(),
  }).passthrough();
  
  // Pick with passthrough should still allow additional properties
  final picked = baseSchema.pick(['id', 'name']);
  
  final result1 = picked.parse({
    'id': '123',
    'name': 'John',
    'extra': 'allowed',
  });
  
  expect(result1['extra'], equals('allowed'));
  
  // Making it strict after pick should work
  final strictPicked = picked.strict();
  
  expect(
    () => strictPicked.parse({
      'id': '123',
      'name': 'John',
      'extra': 'not allowed',
    }),
    throwsA(isA<ValidationException>()),
  );
});
```

### 2.3 Extend Edge Cases

#### Test: Extend with conflicting nullability constraints
```dart
test('should handle nullability conflicts in extend', () {
  final base = Ack.object({
    'field': Ack.string().nullable(),
  });
  
  // Extend with non-nullable version
  final extended = base.extend({
    'field': Ack.string(), // Override as non-nullable
  });
  
  expect(extended.parse({'field': 'value'}), equals({'field': 'value'}));
  
  expect(
    () => extended.parse({'field': null}),
    throwsA(isA<ValidationException>()),
  );
});
```

#### Test: Extend with conflicting default values
```dart
test('should handle default value conflicts in extend', () {
  final base = Ack.object({
    'status': Ack.string().withDefault('pending'),
  });
  
  final extended = base.extend({
    'status': Ack.string().withDefault('active'),
  });
  
  // Should use the extended default
  expect(extended.parse({}), equals({'status': 'active'}));
  
  // Explicit values should still work
  expect(
    extended.parse({'status': 'completed'}),
    equals({'status': 'completed'}),
  );
});
```

#### Test: Extend overriding refinements
```dart
test('should handle refinement overrides in extend', () {
  final base = Ack.object({
    'password': Ack.string().refine(
      (val) => val.length >= 6,
      'Password must be at least 6 characters',
    ),
  });
  
  final extended = base.extend({
    'password': Ack.string().refine(
      (val) => val.length >= 8 && /[0-9]/.hasMatch(val),
      'Password must be at least 8 characters and contain a number',
    ),
  });
  
  // Old validation should not apply
  expect(
    () => extended.parse({'password': 'abcdef'}),
    throwsA(isA<ValidationException>()
      .having((e) => e.message, 'message', contains('8 characters'))),
  );
  
  // New validation should work
  expect(
    extended.parse({'password': 'abcdefg1'}),
    equals({'password': 'abcdefg1'}),
  );
});
```

#### Test: Extend with recursive schema references
```dart
test('should handle recursive schemas in extend', () {
  // Define a recursive node structure
  late final ObjectSchema nodeSchema;
  
  nodeSchema = Ack.object({
    'value': Ack.string(),
    'children': Ack.list(Ack.lazy(() => nodeSchema)).optional(),
  });
  
  // Extend with additional metadata
  final extendedNode = nodeSchema.extend({
    'id': Ack.string(),
    'metadata': Ack.object({
      'created': Ack.string(),
    }).optional(),
  });
  
  final result = extendedNode.parse({
    'id': '1',
    'value': 'root',
    'children': [
      {
        'id': '2',
        'value': 'child1',
        'metadata': {'created': '2024-01-01'},
      },
      {
        'id': '3',
        'value': 'child2',
        'children': [
          {
            'id': '4',
            'value': 'grandchild',
          },
        ],
      },
    ],
  });
  
  expect(result['id'], equals('1'));
  expect(result['children'][0]['metadata']['created'], equals('2024-01-01'));
  expect(result['children'][1]['children'][0]['value'], equals('grandchild'));
});
```

### 2.4 Schema Composition

#### Test: Combining strict() with passthrough()
```dart
test('should handle conflicting strict and passthrough modes', () {
  final schema = Ack.object({
    'id': Ack.string(),
  });
  
  // Last operation should win
  final strictThenPass = schema.strict().passthrough();
  final passThenStrict = schema.passthrough().strict();
  
  // strictThenPass should allow additional properties
  expect(
    strictThenPass.parse({'id': '123', 'extra': 'allowed'}),
    equals({'id': '123', 'extra': 'allowed'}),
  );
  
  // passThenStrict should not allow additional properties
  expect(
    () => passThenStrict.parse({'id': '123', 'extra': 'not allowed'}),
    throwsA(isA<ValidationException>()),
  );
});
```

#### Test: Partial() applied to already optional schemas
```dart
test('should handle partial on schemas with mixed optionality', () {
  final schema = Ack.object({
    'required1': Ack.string(),
    'required2': Ack.int(),
    'optional1': Ack.string().optional(),
    'optional2': Ack.bool().optional(),
  }).requiredProperties(['required1', 'required2']);
  
  final partial = schema.partial();
  
  // All fields should be optional now
  expect(partial.parse({}), equals({}));
  expect(partial.parse({'required1': 'test'}), equals({'required1': 'test'}));
  expect(partial.parse({'optional1': 'test'}), equals({'optional1': 'test'}));
  
  // Should handle all combinations
  final allCombinations = [
    {},
    {'required1': 'a'},
    {'required2': 1},
    {'optional1': 'b'},
    {'optional2': true},
    {'required1': 'a', 'required2': 1},
    {'required1': 'a', 'optional1': 'b'},
    {'required1': 'a', 'required2': 1, 'optional1': 'b', 'optional2': true},
  ];
  
  for (final combo in allCombinations) {
    expect(() => partial.parse(combo), returnsNormally);
  }
});
```

#### Test: Method chaining order sensitivity
```dart
test('should apply operations in correct order', () {
  final base = Ack.object({
    'a': Ack.string(),
    'b': Ack.string(),
    'c': Ack.string(),
  });
  
  // Different operation orders
  final order1 = base.pick(['a', 'b']).extend({'d': Ack.string()});
  final order2 = base.extend({'d': Ack.string()}).pick(['a', 'b']);
  
  // order1 should have a, b, d
  expect(
    order1.parse({'a': '1', 'b': '2', 'd': '3'}),
    equals({'a': '1', 'b': '2', 'd': '3'}),
  );
  
  // order2 should only have a, b (d was added then removed by pick)
  expect(
    order2.parse({'a': '1', 'b': '2'}),
    equals({'a': '1', 'b': '2'}),
  );
  
  expect(
    () => order2.parse({'a': '1', 'b': '2', 'd': '3'}),
    throwsA(isA<ValidationException>()),
  );
});
```

#### Test: Immutability of original schemas after operations
```dart
test('should not modify original schema when applying operations', () {
  final original = Ack.object({
    'field': Ack.string(),
  });
  
  // Apply various operations
  final extended = original.extend({'extra': Ack.int()});
  final picked = original.pick(['field']);
  final strict = original.strict();
  final partial = original.partial();
  
  // Original should still work as before
  expect(original.parse({'field': 'test'}), equals({'field': 'test'}));
  
  // Original should not have the extended field
  expect(
    () => original.parse({'field': 'test', 'extra': 123}),
    returnsNormally, // Original is not strict by default
  );
  
  // Verify each derived schema is independent
  expect(extended.parse({'field': 'test', 'extra': 123}), 
    equals({'field': 'test', 'extra': 123}));
  
  expect(() => strict.parse({'field': 'test', 'unknown': 'value'}),
    throwsA(isA<ValidationException>()));
  
  expect(partial.parse({}), equals({}));
  
  // Multiple operations on same base should be independent
  final extended1 = original.extend({'field1': Ack.string()});
  final extended2 = original.extend({'field2': Ack.string()});
  
  expect(extended1.parse({'field': 'test', 'field1': 'value1'}),
    equals({'field': 'test', 'field1': 'value1'}));
  
  expect(extended2.parse({'field': 'test', 'field2': 'value2'}),
    equals({'field': 'test', 'field2': 'value2'}));
});
```

## Validation Checklist

- [ ] Complex merge scenarios tested
- [ ] Pick/omit with nested paths implemented
- [ ] Extend edge cases covered
- [ ] Schema composition verified
- [ ] Immutability confirmed
- [ ] Tests added to `object_schema_extensions_test.dart`
- [ ] All tests passing
- [ ] No regressions in existing tests

## Success Metrics

- 20+ new test cases added
- All conflict scenarios properly handled
- Method chaining behavior documented
- Schema immutability guaranteed
- Clear error messages for all edge cases