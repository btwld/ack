# Phase 1: Transformation Edge Cases 🔄

## Overview
This phase focuses on comprehensive edge case coverage for the transformation feature, ensuring robust handling of null values, complex transformation chains, and error scenarios.

## Current Status
- Basic transformation tests exist in `/packages/ack/test/schemas/extensions/transform_extension_test.dart`
- Good coverage for simple transformations and error handling
- Missing edge cases identified in validation report

## Implementation Plan

### 1.1 Null Handling Edge Cases

#### Test: Transformation returning null for non-nullable output schema
```dart
test('should throw when transformation returns null for non-nullable output', () {
  final schema = Ack.string().transform<String>((val) => null);
  
  expect(
    () => schema.parse('any value'),
    throwsA(isA<SchemaTransformError>()
      .having(
        (e) => e.message,
        'message',
        contains('Transformation returned null for non-nullable schema'),
      )),
  );
});
```

#### Test: Transformation of nullable input to non-nullable output
```dart
test('should handle nullable input to non-nullable output transformation', () {
  final schema = Ack.string().nullable().transform<int>(
    (val) => val?.length ?? 0,
  );
  
  expect(schema.parse(null), equals(0));
  expect(schema.parse('hello'), equals(5));
});
```

#### Test: Transformation of non-nullable input to nullable output
```dart
test('should handle non-nullable input to nullable output transformation', () {
  final schema = Ack.string().transform<int?>(
    (val) => val.isEmpty ? null : val.length,
  );
  
  expect(schema.parse(''), isNull);
  expect(schema.parse('hello'), equals(5));
});
```

#### Test: Null propagation through transformation chain
```dart
test('should propagate null through transformation chain correctly', () {
  final schema = Ack.string()
    .nullable()
    .transform<int?>((val) => val?.length)
    .transform<String?>((val) => val?.toString());
  
  expect(schema.parse(null), isNull);
  expect(schema.parse('hello'), equals('5'));
});
```

### 1.2 Complex Transformation Scenarios

#### Test: Nested transformations (transform of transform)
```dart
test('should handle nested transformations correctly', () {
  // String -> int -> String transformation chain
  final schema = Ack.string()
    .transform<int>((val) => val.length)
    .transform<String>((val) => 'Length: $val');
  
  expect(schema.parse('hello'), equals('Length: 5'));
  expect(schema.parse(''), equals('Length: 0'));
});
```

#### Test: Transformation with type narrowing
```dart
test('should handle type narrowing transformations', () {
  // Object -> specific type
  final schema = Ack.object({
    'value': Ack.any(),
  }).transform<String>((obj) {
    final value = obj['value'];
    if (value is String) return value;
    if (value is int) return value.toString();
    throw FormatException('Unsupported type');
  });
  
  expect(schema.parse({'value': 'hello'}), equals('hello'));
  expect(schema.parse({'value': 42}), equals('42'));
  expect(
    () => schema.parse({'value': true}),
    throwsA(isA<SchemaTransformError>()),
  );
});
```

#### Test: Transformation with type widening
```dart
test('should handle type widening transformations', () {
  // Specific type -> more general type
  final schema = Ack.int().transform<num>((val) => val.toDouble());
  
  expect(schema.parse(42), equals(42.0));
  expect(schema.parse(0), equals(0.0));
  expect(schema.parse(-10), equals(-10.0));
});
```

#### Test: Transformation that throws different exception types
```dart
test('should wrap various exception types in SchemaTransformError', () {
  final schema = Ack.string().transform<int>((val) {
    if (val == 'error') throw Exception('Generic error');
    if (val == 'format') throw FormatException('Invalid format');
    if (val == 'state') throw StateError('Bad state');
    return int.parse(val);
  });
  
  for (final testCase in ['error', 'format', 'state', 'abc']) {
    expect(
      () => schema.parse(testCase),
      throwsA(isA<SchemaTransformError>()
        .having((e) => e.originalError, 'originalError', isNotNull)),
    );
  }
});
```

#### Test: Transformation with side effects
```dart
test('should handle transformations with side effects correctly', () {
  final log = <String>[];
  
  final schema = Ack.string().transform<String>((val) {
    log.add('Transforming: $val');
    return val.toUpperCase();
  });
  
  expect(schema.parse('hello'), equals('HELLO'));
  expect(log, equals(['Transforming: hello']));
  
  expect(schema.parse('world'), equals('WORLD'));
  expect(log, equals(['Transforming: hello', 'Transforming: world']));
});
```

#### Test: Transformation composition with refinements
```dart
test('should compose transformations with refinements correctly', () {
  final schema = Ack.string()
    .minLength(2)
    .transform<int>((val) => val.length)
    .refine((length) => length <= 10, 'String too long')
    .transform<String>((val) => 'Count: $val');
  
  expect(schema.parse('hi'), equals('Count: 2'));
  expect(schema.parse('hello'), equals('Count: 5'));
  
  expect(
    () => schema.parse('x'),
    throwsA(isA<ValidationException>()),
  );
  
  expect(
    () => schema.parse('verylongstring'),
    throwsA(isA<ValidationException>()
      .having((e) => e.message, 'message', contains('String too long'))),
  );
});
```

### 1.3 Transformation Performance Cases

#### Test: Transformation with large data sets
```dart
test('should handle large data transformations efficiently', () {
  final largeList = List.generate(10000, (i) => 'item$i');
  
  final schema = Ack.list(Ack.string()).transform<int>(
    (list) => list.fold<int>(0, (sum, item) => sum + item.length),
  );
  
  final stopwatch = Stopwatch()..start();
  final result = schema.parse(largeList);
  stopwatch.stop();
  
  expect(result, greaterThan(0));
  expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
});
```

#### Test: Transformation with recursive data structures
```dart
test('should handle recursive transformations', () {
  // Transform nested maps to dot notation
  Map<String, dynamic> flatten(Map<String, dynamic> map, [String prefix = '']) {
    final result = <String, dynamic>{};
    
    map.forEach((key, value) {
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        result.addAll(flatten(value, fullKey));
      } else {
        result[fullKey] = value;
      }
    });
    
    return result;
  }
  
  final schema = Ack.object({
    'data': Ack.any(),
  }).transform<Map<String, dynamic>>(
    (obj) => flatten(obj['data'] as Map<String, dynamic>),
  );
  
  final input = {
    'data': {
      'user': {
        'name': 'John',
        'address': {
          'city': 'NYC',
          'zip': '10001',
        },
      },
    },
  };
  
  final result = schema.parse(input);
  expect(result['user.name'], equals('John'));
  expect(result['user.address.city'], equals('NYC'));
  expect(result['user.address.zip'], equals('10001'));
});
```

#### Test: Transformation memory efficiency
```dart
test('should not leak memory in transformation chains', () {
  // Create a schema that transforms through multiple stages
  final schema = Ack.string()
    .transform<List<int>>((s) => s.codeUnits)
    .transform<String>((codes) => codes.map((c) => c.toRadixString(16)).join('-'))
    .transform<String>((hex) => 'HEX: $hex');
  
  // Run multiple times to check for memory leaks
  for (int i = 0; i < 1000; i++) {
    final result = schema.parse('Test string $i');
    expect(result, startsWith('HEX:'));
  }
  
  // If this test completes without memory issues, it passes
});
```

### 1.4 Transformation Error Handling

#### Test: Stack trace preservation in transformation errors
```dart
test('should preserve stack traces in transformation errors', () {
  final schema = Ack.string().transform<int>((val) {
    return int.parse(val); // Will throw FormatException
  });
  
  try {
    schema.parse('not a number');
    fail('Should have thrown');
  } catch (e) {
    expect(e, isA<SchemaTransformError>());
    final error = e as SchemaTransformError;
    expect(error.originalError, isA<FormatException>());
    expect(error.stackTrace, isNotNull);
    expect(error.toString(), contains('SchemaTransformError'));
  }
});
```

#### Test: Custom error messages in transformation failures
```dart
test('should support custom error messages in transformations', () {
  final schema = Ack.string().transform<DateTime>((val) {
    try {
      return DateTime.parse(val);
    } catch (e) {
      throw FormatException('Invalid date format. Expected: YYYY-MM-DD');
    }
  });
  
  expect(
    () => schema.parse('invalid-date'),
    throwsA(isA<SchemaTransformError>()
      .having(
        (e) => e.originalError?.toString(),
        'originalError',
        contains('Invalid date format. Expected: YYYY-MM-DD'),
      )),
  );
});
```

#### Test: Transformation error recovery patterns
```dart
test('should support error recovery in transformations', () {
  final schema = Ack.string().transform<int>((val) {
    try {
      return int.parse(val);
    } catch (e) {
      // Fallback to length if parsing fails
      return val.length;
    }
  });
  
  expect(schema.parse('42'), equals(42));
  expect(schema.parse('not a number'), equals(12)); // length of string
});
```

#### Test: Transformation rollback scenarios
```dart
test('should not apply partial transformations on failure', () {
  int sideEffectCounter = 0;
  
  final schema = Ack.object({
    'values': Ack.list(Ack.string()),
  }).transform<List<int>>((obj) {
    final values = obj['values'] as List;
    return values.map((v) {
      sideEffectCounter++;
      if (v == 'fail') throw Exception('Transformation failed');
      return (v as String).length;
    }).toList();
  });
  
  sideEffectCounter = 0;
  expect(
    () => schema.parse({'values': ['one', 'two', 'fail', 'four']}),
    throwsA(isA<SchemaTransformError>()),
  );
  
  // Side effects occurred but result wasn't returned
  expect(sideEffectCounter, equals(3)); // Processed until 'fail'
});
```

## Validation Checklist

- [ ] All null handling edge cases covered
- [ ] Complex transformation scenarios tested
- [ ] Performance tests implemented
- [ ] Error handling comprehensive
- [ ] Stack traces preserved
- [ ] Tests added to `transform_extension_test.dart`
- [ ] All tests passing
- [ ] No regressions in existing tests

## Success Metrics

- 15+ new test cases added
- 100% coverage of identified edge cases
- Clear error messages for all failure scenarios
- Performance benchmarks established
- No memory leaks in transformation chains