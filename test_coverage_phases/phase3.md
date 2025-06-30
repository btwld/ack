# Phase 3: Discriminated Union Advanced Cases 🔀

## Overview
This phase focuses on advanced polymorphic validation scenarios for discriminated unions, including non-string discriminators, nested unions, and performance optimization.

## Current Status
- Good basic coverage in `/packages/ack/test/schemas/discriminated_object_schema_test.dart`
- Basic string discriminator validation works
- JSON schema generation with `oneOf` tested
- Missing advanced discriminator types and nested scenarios

## Implementation Plan

### 3.1 Complex Discriminator Scenarios

#### Test: Nested discriminated unions
```dart
test('should handle nested discriminated unions', () {
  // Inner discriminated union for different payment methods
  final paymentSchema = Ack.discriminated(
    discriminatorKey: 'method',
    schemas: {
      'card': Ack.object({
        'method': Ack.literal('card'),
        'cardNumber': Ack.string(),
        'cvv': Ack.string(),
      }),
      'paypal': Ack.object({
        'method': Ack.literal('paypal'),
        'email': Ack.string(),
      }),
      'bank': Ack.object({
        'method': Ack.literal('bank'),
        'accountNumber': Ack.string(),
        'routingNumber': Ack.string(),
      }),
    },
  );
  
  // Outer discriminated union for different event types
  final eventSchema = Ack.discriminated(
    discriminatorKey: 'type',
    schemas: {
      'order': Ack.object({
        'type': Ack.literal('order'),
        'orderId': Ack.string(),
        'payment': paymentSchema, // Nested discriminated union
      }),
      'refund': Ack.object({
        'type': Ack.literal('refund'),
        'refundId': Ack.string(),
        'originalPayment': paymentSchema, // Nested discriminated union
        'amount': Ack.double(),
      }),
    },
  );
  
  // Test valid nested structure
  final orderWithCard = eventSchema.parse({
    'type': 'order',
    'orderId': 'ORD-123',
    'payment': {
      'method': 'card',
      'cardNumber': '4111111111111111',
      'cvv': '123',
    },
  });
  
  expect(orderWithCard['type'], equals('order'));
  expect(orderWithCard['payment']['method'], equals('card'));
  
  // Test different nested variant
  final refundWithPaypal = eventSchema.parse({
    'type': 'refund',
    'refundId': 'REF-456',
    'originalPayment': {
      'method': 'paypal',
      'email': 'user@example.com',
    },
    'amount': 99.99,
  });
  
  expect(refundWithPaypal['type'], equals('refund'));
  expect(refundWithPaypal['originalPayment']['method'], equals('paypal'));
  
  // Test invalid nested discriminator
  expect(
    () => eventSchema.parse({
      'type': 'order',
      'orderId': 'ORD-123',
      'payment': {
        'method': 'unknown', // Invalid payment method
        'data': 'test',
      },
    }),
    throwsA(isA<ValidationException>()
      .having((e) => e.message, 'message', contains('discriminator'))),
  );
});
```

#### Test: Discriminator with enum values
```dart
test('should support enum discriminators', () {
  enum AnimalType { dog, cat, bird }
  
  final animalSchema = Ack.discriminated(
    discriminatorKey: 'type',
    schemas: {
      'dog': Ack.object({
        'type': Ack.literal('dog'),
        'breed': Ack.string(),
        'goodBoy': Ack.bool(),
      }),
      'cat': Ack.object({
        'type': Ack.literal('cat'),
        'breed': Ack.string(),
        'indoor': Ack.bool(),
      }),
      'bird': Ack.object({
        'type': Ack.literal('bird'),
        'species': Ack.string(),
        'canFly': Ack.bool(),
      }),
    },
  );
  
  // Test with enum values
  for (final type in AnimalType.values) {
    final data = switch (type) {
      AnimalType.dog => {
        'type': type.name,
        'breed': 'Golden Retriever',
        'goodBoy': true,
      },
      AnimalType.cat => {
        'type': type.name,
        'breed': 'Persian',
        'indoor': true,
      },
      AnimalType.bird => {
        'type': type.name,
        'species': 'Parrot',
        'canFly': true,
      },
    };
    
    final result = animalSchema.parse(data);
    expect(result['type'], equals(type.name));
  }
});
```

#### Test: Discriminator with numeric values
```dart
test('should support numeric discriminators', () {
  final statusSchema = Ack.discriminated(
    discriminatorKey: 'code',
    schemas: {
      '200': Ack.object({
        'code': Ack.literal(200),
        'data': Ack.any(),
        'message': Ack.literal('Success'),
      }),
      '400': Ack.object({
        'code': Ack.literal(400),
        'error': Ack.string(),
        'details': Ack.list(Ack.string()).optional(),
      }),
      '500': Ack.object({
        'code': Ack.literal(500),
        'error': Ack.string(),
        'stack': Ack.string().optional(),
      }),
    },
  );
  
  // Test numeric discriminators
  final success = statusSchema.parse({
    'code': 200,
    'data': {'result': 'ok'},
    'message': 'Success',
  });
  expect(success['code'], equals(200));
  
  final badRequest = statusSchema.parse({
    'code': 400,
    'error': 'Invalid input',
    'details': ['Field X is required', 'Field Y must be positive'],
  });
  expect(badRequest['code'], equals(400));
  
  final serverError = statusSchema.parse({
    'code': 500,
    'error': 'Internal server error',
    'stack': 'Error at line 42...',
  });
  expect(serverError['code'], equals(500));
  
  // Test invalid code
  expect(
    () => statusSchema.parse({
      'code': 404, // Not in schema
      'error': 'Not found',
    }),
    throwsA(isA<ValidationException>()),
  );
});
```

#### Test: Discriminator case sensitivity
```dart
test('should handle case sensitivity in discriminators correctly', () {
  final schema = Ack.discriminated(
    discriminatorKey: 'TYPE',
    schemas: {
      'User': Ack.object({
        'TYPE': Ack.literal('User'),
        'name': Ack.string(),
      }),
      'user': Ack.object({
        'TYPE': Ack.literal('user'),
        'username': Ack.string(),
      }),
      'USER': Ack.object({
        'TYPE': Ack.literal('USER'),
        'fullName': Ack.string(),
      }),
    },
  );
  
  // Each case should match exactly
  expect(
    schema.parse({'TYPE': 'User', 'name': 'John'}),
    equals({'TYPE': 'User', 'name': 'John'}),
  );
  
  expect(
    schema.parse({'TYPE': 'user', 'username': 'john123'}),
    equals({'TYPE': 'user', 'username': 'john123'}),
  );
  
  expect(
    schema.parse({'TYPE': 'USER', 'fullName': 'John Doe'}),
    equals({'TYPE': 'USER', 'fullName': 'John Doe'}),
  );
  
  // Wrong case should fail
  expect(
    () => schema.parse({'TYPE': 'UsEr', 'name': 'John'}),
    throwsA(isA<ValidationException>()),
  );
});
```

### 3.2 Error Handling Improvements

#### Test: Detailed error messages for discriminated validation failures
```dart
test('should provide detailed error messages for validation failures', () {
  final schema = Ack.discriminated(
    discriminatorKey: 'shape',
    schemas: {
      'circle': Ack.object({
        'shape': Ack.literal('circle'),
        'radius': Ack.double().positive(),
      }),
      'rectangle': Ack.object({
        'shape': Ack.literal('rectangle'),
        'width': Ack.double().positive(),
        'height': Ack.double().positive(),
      }),
      'triangle': Ack.object({
        'shape': Ack.literal('triangle'),
        'base': Ack.double().positive(),
        'height': Ack.double().positive(),
      }),
    },
  );
  
  // Test missing discriminator
  try {
    schema.parse({'radius': 5.0});
    fail('Should have thrown');
  } catch (e) {
    expect(e, isA<ValidationException>());
    expect(e.toString(), contains('discriminator'));
    expect(e.toString(), contains('shape'));
  }
  
  // Test invalid discriminator value
  try {
    schema.parse({'shape': 'hexagon', 'sides': 6});
    fail('Should have thrown');
  } catch (e) {
    expect(e, isA<ValidationException>());
    expect(e.toString(), contains('hexagon'));
    expect(e.toString(), contains('circle, rectangle, triangle'));
  }
  
  // Test schema validation failure
  try {
    schema.parse({'shape': 'circle', 'radius': -5});
    fail('Should have thrown');
  } catch (e) {
    expect(e, isA<ValidationException>());
    expect(e.toString(), contains('positive'));
  }
});
```

#### Test: Error paths in nested discriminated schemas
```dart
test('should track error paths in nested discriminated unions', () {
  final innerSchema = Ack.discriminated(
    discriminatorKey: 'subtype',
    schemas: {
      'a': Ack.object({
        'subtype': Ack.literal('a'),
        'value': Ack.int().positive(),
      }),
      'b': Ack.object({
        'subtype': Ack.literal('b'),
        'value': Ack.string().minLength(5),
      }),
    },
  );
  
  final outerSchema = Ack.discriminated(
    discriminatorKey: 'type',
    schemas: {
      'nested': Ack.object({
        'type': Ack.literal('nested'),
        'data': innerSchema,
      }),
      'simple': Ack.object({
        'type': Ack.literal('simple'),
        'value': Ack.string(),
      }),
    },
  );
  
  // Test error in nested union
  try {
    outerSchema.parse({
      'type': 'nested',
      'data': {
        'subtype': 'b',
        'value': 'hi', // Too short
      },
    });
    fail('Should have thrown');
  } catch (e) {
    expect(e, isA<ValidationException>());
    final error = e as ValidationException;
    expect(error.errors.first.path, equals(['data', 'value']));
    expect(error.errors.first.message, contains('at least 5'));
  }
});
```

#### Test: Discriminator mismatch error clarity
```dart
test('should provide clear errors for discriminator mismatches', () {
  final schema = Ack.discriminated(
    discriminatorKey: 'version',
    schemas: {
      'v1': Ack.object({
        'version': Ack.literal('v1'),
        'oldField': Ack.string(),
      }),
      'v2': Ack.object({
        'version': Ack.literal('v2'),
        'newField': Ack.string(),
        'extraField': Ack.int(),
      }),
    },
  );
  
  // Test using wrong fields for discriminator
  try {
    schema.parse({
      'version': 'v1',
      'newField': 'test', // This field belongs to v2
      'extraField': 123,
    });
    fail('Should have thrown');
  } catch (e) {
    expect(e, isA<ValidationException>());
    expect(e.toString(), contains('oldField'));
  }
});
```

#### Test: Missing discriminator field suggestions
```dart
test('should suggest discriminator field when missing', () {
  final schema = Ack.discriminated(
    discriminatorKey: 'eventType',
    schemas: {
      'click': Ack.object({
        'eventType': Ack.literal('click'),
        'element': Ack.string(),
      }),
      'scroll': Ack.object({
        'eventType': Ack.literal('scroll'),
        'position': Ack.int(),
      }),
    },
  );
  
  // Test with similar field name
  try {
    schema.parse({
      'event_type': 'click', // Wrong field name
      'element': 'button',
    });
    fail('Should have thrown');
  } catch (e) {
    expect(e, isA<ValidationException>());
    expect(e.toString(), contains('eventType')); // Should mention correct field
    expect(e.toString(), contains('discriminator'));
  }
  
  // Test with typo in discriminator value
  try {
    schema.parse({
      'eventType': 'clik', // Typo
      'element': 'button',
    });
    fail('Should have thrown');
  } catch (e) {
    expect(e, isA<ValidationException>());
    expect(e.toString(), contains('click')); // Should suggest correct value
  }
});
```

### 3.3 Schema Integration

#### Test: Discriminated union with transformation
```dart
test('should support transformations with discriminated unions', () {
  final schema = Ack.discriminated(
    discriminatorKey: 'type',
    schemas: {
      'string': Ack.object({
        'type': Ack.literal('string'),
        'value': Ack.string(),
      }),
      'number': Ack.object({
        'type': Ack.literal('number'),
        'value': Ack.double(),
      }),
    },
  ).transform<String>((data) {
    // Transform to string representation
    return switch (data['type']) {
      'string' => 'String: ${data['value']}',
      'number' => 'Number: ${data['value']}',
      _ => throw Exception('Unknown type'),
    };
  });
  
  expect(
    schema.parse({'type': 'string', 'value': 'hello'}),
    equals('String: hello'),
  );
  
  expect(
    schema.parse({'type': 'number', 'value': 42.5}),
    equals('Number: 42.5'),
  );
});
```

#### Test: Discriminated union with refinements
```dart
test('should support refinements on discriminated unions', () {
  final schema = Ack.discriminated(
    discriminatorKey: 'role',
    schemas: {
      'admin': Ack.object({
        'role': Ack.literal('admin'),
        'permissions': Ack.list(Ack.string()),
      }),
      'user': Ack.object({
        'role': Ack.literal('user'),
        'restrictions': Ack.list(Ack.string()),
      }),
    },
  ).refine((data) {
    // Admins must have at least one permission
    if (data['role'] == 'admin') {
      final permissions = data['permissions'] as List;
      return permissions.isNotEmpty;
    }
    // Users cannot have dangerous restrictions
    if (data['role'] == 'user') {
      final restrictions = data['restrictions'] as List;
      return !restrictions.contains('delete_all');
    }
    return true;
  }, 'Invalid role configuration');
  
  // Valid cases
  expect(
    schema.parse({
      'role': 'admin',
      'permissions': ['read', 'write'],
    }),
    isA<Map>(),
  );
  
  expect(
    schema.parse({
      'role': 'user',
      'restrictions': ['no_export'],
    }),
    isA<Map>(),
  );
  
  // Invalid cases
  expect(
    () => schema.parse({
      'role': 'admin',
      'permissions': [], // Empty permissions
    }),
    throwsA(isA<ValidationException>()
      .having((e) => e.message, 'message', contains('Invalid role configuration'))),
  );
  
  expect(
    () => schema.parse({
      'role': 'user',
      'restrictions': ['delete_all'], // Dangerous restriction
    }),
    throwsA(isA<ValidationException>()),
  );
});
```

#### Test: Advanced JSON schema features
```dart
test('should generate proper JSON schema with discriminator metadata', () {
  final schema = Ack.discriminated(
    discriminatorKey: 'animal',
    schemas: {
      'dog': Ack.object({
        'animal': Ack.literal('dog'),
        'breed': Ack.string(),
        'barks': Ack.bool(),
      }),
      'cat': Ack.object({
        'animal': Ack.literal('cat'),
        'breed': Ack.string(),
        'meows': Ack.bool(),
      }),
    },
  );
  
  final jsonSchema = schema.toJson();
  
  // Should use oneOf
  expect(jsonSchema['oneOf'], isA<List>());
  expect(jsonSchema['oneOf'].length, equals(2));
  
  // Should include discriminator metadata
  expect(jsonSchema['discriminator'], isNotNull);
  expect(jsonSchema['discriminator']['propertyName'], equals('animal'));
  
  // Each schema should be properly formatted
  final dogSchema = jsonSchema['oneOf'][0];
  expect(dogSchema['properties']['animal']['const'], equals('dog'));
  expect(dogSchema['properties']['breed']['type'], equals('string'));
  expect(dogSchema['properties']['barks']['type'], equals('boolean'));
  
  final catSchema = jsonSchema['oneOf'][1];
  expect(catSchema['properties']['animal']['const'], equals('cat'));
  expect(catSchema['properties']['breed']['type'], equals('string'));
  expect(catSchema['properties']['meows']['type'], equals('boolean'));
});
```

#### Test: Discriminated union with default values
```dart
test('should handle default values in discriminated unions', () {
  final schema = Ack.discriminated(
    discriminatorKey: 'status',
    schemas: {
      'pending': Ack.object({
        'status': Ack.literal('pending'),
        'reason': Ack.string().withDefault('Processing'),
      }),
      'completed': Ack.object({
        'status': Ack.literal('completed'),
        'result': Ack.string(),
        'score': Ack.int().withDefault(100),
      }),
    },
  );
  
  // Test defaults are applied
  final pending = schema.parse({'status': 'pending'});
  expect(pending['reason'], equals('Processing'));
  
  final completed = schema.parse({
    'status': 'completed',
    'result': 'Success',
  });
  expect(completed['score'], equals(100));
  
  // Test explicit values override defaults
  final explicitPending = schema.parse({
    'status': 'pending',
    'reason': 'Waiting for approval',
  });
  expect(explicitPending['reason'], equals('Waiting for approval'));
});
```

### 3.4 Performance Cases

#### Test: Discriminated union with many variants (50+)
```dart
test('should handle discriminated unions with many variants efficiently', () {
  // Generate a large discriminated union
  final schemas = <String, AckSchema>{};
  
  for (int i = 0; i < 100; i++) {
    schemas['type$i'] = Ack.object({
      'type': Ack.literal('type$i'),
      'data': Ack.string(),
      'index': Ack.literal(i),
    });
  }
  
  final schema = Ack.discriminated(
    discriminatorKey: 'type',
    schemas: schemas,
  );
  
  // Test performance with various types
  final stopwatch = Stopwatch()..start();
  
  for (int i = 0; i < 1000; i++) {
    final typeIndex = i % 100;
    final result = schema.parse({
      'type': 'type$typeIndex',
      'data': 'test data $i',
      'index': typeIndex,
    });
    
    expect(result['type'], equals('type$typeIndex'));
  }
  
  stopwatch.stop();
  
  // Should complete quickly even with many variants
  expect(stopwatch.elapsedMilliseconds, lessThan(100));
  print('Validated 1000 items in ${stopwatch.elapsedMilliseconds}ms');
});
```

#### Test: Discriminated union lookup optimization
```dart
test('should optimize discriminator lookups', () {
  final schema = Ack.discriminated(
    discriminatorKey: 'cmd',
    schemas: {
      'create': Ack.object({
        'cmd': Ack.literal('create'),
        'resource': Ack.string(),
      }),
      'update': Ack.object({
        'cmd': Ack.literal('update'),
        'id': Ack.string(),
        'changes': Ack.any(),
      }),
      'delete': Ack.object({
        'cmd': Ack.literal('delete'),
        'id': Ack.string(),
      }),
      'list': Ack.object({
        'cmd': Ack.literal('list'),
        'filters': Ack.any().optional(),
      }),
    },
  );
  
  // Test that discriminator is checked first (fast path)
  final invalidData = {
    'cmd': 'invalid',
    'lots': 'of',
    'other': 'data',
    'that': 'should',
    'not': 'be',
    'validated': 'first',
  };
  
  final stopwatch = Stopwatch()..start();
  
  try {
    schema.parse(invalidData);
  } catch (e) {
    // Expected to fail
  }
  
  stopwatch.stop();
  
  // Should fail quickly by checking discriminator first
  expect(stopwatch.elapsedMicroseconds, lessThan(1000)); // Less than 1ms
});
```

#### Test: Discriminated union memory usage
```dart
test('should handle memory efficiently with large discriminated unions', () {
  // Create schemas with large data structures
  final schema = Ack.discriminated(
    discriminatorKey: 'dataType',
    schemas: {
      'matrix': Ack.object({
        'dataType': Ack.literal('matrix'),
        'data': Ack.list(Ack.list(Ack.double())),
      }),
      'tensor': Ack.object({
        'dataType': Ack.literal('tensor'),
        'shape': Ack.list(Ack.int()),
        'data': Ack.list(Ack.double()),
      }),
      'sparse': Ack.object({
        'dataType': Ack.literal('sparse'),
        'indices': Ack.list(Ack.list(Ack.int())),
        'values': Ack.list(Ack.double()),
      }),
    },
  );
  
  // Test with large data structures
  final largeMatrix = {
    'dataType': 'matrix',
    'data': List.generate(100, (_) => List.generate(100, (_) => 1.0)),
  };
  
  final largeTensor = {
    'dataType': 'tensor',
    'shape': [10, 10, 10, 10],
    'data': List.generate(10000, (_) => 1.0),
  };
  
  // Should validate without excessive memory usage
  expect(() => schema.parse(largeMatrix), returnsNormally);
  expect(() => schema.parse(largeTensor), returnsNormally);
  
  // Test multiple validations don't leak memory
  for (int i = 0; i < 100; i++) {
    schema.parse({
      'dataType': 'sparse',
      'indices': [[i, i]],
      'values': [i.toDouble()],
    });
  }
});
```

## Validation Checklist

- [ ] Nested discriminated unions working
- [ ] Non-string discriminators supported
- [ ] Enum discriminators tested
- [ ] Numeric discriminators tested
- [ ] Case sensitivity handled correctly
- [ ] Error messages improved
- [ ] Performance with many variants tested
- [ ] Integration with transformations and refinements
- [ ] JSON schema generation enhanced
- [ ] Tests added to `discriminated_object_schema_test.dart`
- [ ] All tests passing
- [ ] No regressions

## Success Metrics

- 10+ new test cases added
- Support for all discriminator types
- Performance acceptable with 100+ variants
- Error messages clear and helpful
- Nested unions work seamlessly