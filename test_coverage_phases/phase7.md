# Phase 7: Integration Testing 🔗

## Overview
This phase focuses on systematic integration and performance testing to ensure all features work well together and meet performance requirements.

## Current Status
- Limited integration tests in `comprehensive_json_schema_test.dart`
- Basic performance tests exist (50 properties, 5 levels deep)
- No dedicated integration test directory
- No systematic performance benchmarks

## Implementation Plan

### 7.1 Cross-Feature Integration

#### Test: Transformation + Discriminated Union
```dart
// File: packages/ack/test/integration/transform_discriminated_test.dart

void main() {
  group('Transformation with Discriminated Union', () {
    test('should transform discriminated union results', () {
      final eventSchema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'click': Ack.object({
            'type': Ack.literal('click'),
            'x': Ack.int(),
            'y': Ack.int(),
          }),
          'scroll': Ack.object({
            'type': Ack.literal('scroll'),
            'delta': Ack.double(),
          }),
        },
      ).transform<String>((event) {
        return switch (event['type']) {
          'click' => 'Click at (${event['x']}, ${event['y']})',
          'scroll' => 'Scroll by ${event['delta']}',
          _ => 'Unknown event',
        };
      });
      
      expect(
        eventSchema.parse({'type': 'click', 'x': 100, 'y': 200}),
        equals('Click at (100, 200)'),
      );
      
      expect(
        eventSchema.parse({'type': 'scroll', 'delta': 50.5}),
        equals('Scroll by 50.5'),
      );
    });
    
    test('should validate before transforming discriminated unions', () {
      final schema = Ack.discriminated(
        discriminatorKey: 'status',
        schemas: {
          'success': Ack.object({
            'status': Ack.literal('success'),
            'data': Ack.string(),
          }),
          'error': Ack.object({
            'status': Ack.literal('error'),
            'code': Ack.int(),
          }),
        },
      ).transform<int>((result) {
        return result['status'] == 'success' ? 0 : result['code'] as int;
      });
      
      // Invalid discriminator should fail before transform
      expect(
        () => schema.parse({'status': 'unknown', 'data': 'test'}),
        throwsA(isA<ValidationException>()),
      );
      
      // Invalid schema should fail before transform
      expect(
        () => schema.parse({'status': 'error', 'code': 'not-a-number'}),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

#### Test: Object Extension + Transformation
```dart
// File: packages/ack/test/integration/object_transform_test.dart

void main() {
  group('Object Extensions with Transformation', () {
    test('should transform extended objects', () {
      final baseSchema = Ack.object({
        'firstName': Ack.string(),
        'lastName': Ack.string(),
      });
      
      final extendedSchema = baseSchema
        .extend({
          'age': Ack.int().min(0),
          'email': Ack.string().email(),
        })
        .transform<Map<String, dynamic>>((data) {
          return {
            ...data,
            'fullName': '${data['firstName']} ${data['lastName']}',
            'isAdult': (data['age'] as int) >= 18,
          };
        });
      
      final result = extendedSchema.parse({
        'firstName': 'John',
        'lastName': 'Doe',
        'age': 25,
        'email': 'john@example.com',
      });
      
      expect(result['fullName'], equals('John Doe'));
      expect(result['isAdult'], isTrue);
      expect(result['email'], equals('john@example.com'));
    });
    
    test('should handle pick/omit with transformations', () {
      final schema = Ack.object({
        'id': Ack.string(),
        'password': Ack.string(),
        'email': Ack.string(),
        'profile': Ack.object({
          'name': Ack.string(),
          'bio': Ack.string(),
        }),
      });
      
      // Create public view by omitting sensitive data and transforming
      final publicSchema = schema
        .omit(['password'])
        .transform<Map<String, dynamic>>((data) {
          return {
            ...data,
            'displayName': data['profile']['name'],
            'profileUrl': '/users/${data['id']}',
          };
        });
      
      final result = publicSchema.parse({
        'id': '123',
        'email': 'user@example.com',
        'profile': {
          'name': 'Jane User',
          'bio': 'Developer',
        },
      });
      
      expect(result.containsKey('password'), isFalse);
      expect(result['displayName'], equals('Jane User'));
      expect(result['profileUrl'], equals('/users/123'));
    });
  });
}
```

#### Test: Object Extension + Discriminated Union
```dart
// File: packages/ack/test/integration/object_discriminated_test.dart

void main() {
  group('Object Extensions with Discriminated Unions', () {
    test('should extend discriminated union schemas', () {
      final baseUserSchema = Ack.object({
        'id': Ack.string(),
        'name': Ack.string(),
      });
      
      final userTypeSchema = Ack.discriminated(
        discriminatorKey: 'role',
        schemas: {
          'admin': baseUserSchema.extend({
            'role': Ack.literal('admin'),
            'permissions': Ack.list(Ack.string()),
          }),
          'customer': baseUserSchema.extend({
            'role': Ack.literal('customer'),
            'subscription': Ack.string().enum(['free', 'pro', 'enterprise']),
          }),
        },
      );
      
      // Add common fields to all variants
      final enhancedSchema = userTypeSchema.transform<Map>((user) {
        return {
          ...user,
          'lastActive': DateTime.now().toIso8601String(),
          'apiVersion': 'v2',
        };
      });
      
      final admin = enhancedSchema.parse({
        'id': '1',
        'name': 'Admin User',
        'role': 'admin',
        'permissions': ['read', 'write', 'delete'],
      });
      
      expect(admin['role'], equals('admin'));
      expect(admin['apiVersion'], equals('v2'));
      expect(admin.containsKey('lastActive'), isTrue);
    });
  });
}
```

#### Test: All features in single complex schema
```dart
// File: packages/ack/test/integration/complex_schema_test.dart

void main() {
  group('Complex Schema Integration', () {
    test('should handle all features in a real-world schema', () {
      // E-commerce order schema with all features
      final addressSchema = Ack.object({
        'street': Ack.string(),
        'city': Ack.string(),
        'country': Ack.string(),
        'postalCode': Ack.string().pattern(RegExp(r'^\d{5}(-\d{4})?$')),
      });
      
      final productSchema = Ack.object({
        'id': Ack.string().uuid(),
        'name': Ack.string(),
        'price': Ack.double().positive(),
        'quantity': Ack.int().positive(),
      }).transform<Map>((product) {
        return {
          ...product,
          'total': (product['price'] as double) * (product['quantity'] as int),
        };
      });
      
      final paymentSchema = Ack.discriminated(
        discriminatorKey: 'method',
        schemas: {
          'card': Ack.object({
            'method': Ack.literal('card'),
            'last4': Ack.string().pattern(RegExp(r'^\d{4}$')),
            'brand': Ack.string().enum(['visa', 'mastercard', 'amex']),
          }),
          'paypal': Ack.object({
            'method': Ack.literal('paypal'),
            'email': Ack.string().email(),
          }),
        },
      );
      
      final orderSchema = Ack.object({
        'orderId': Ack.string().uuid(),
        'customer': Ack.object({
          'email': Ack.string().email(),
          'name': Ack.string(),
        }),
        'items': Ack.list(productSchema).minItems(1),
        'shippingAddress': addressSchema,
        'billingAddress': addressSchema.partial(), // Optional fields
        'payment': paymentSchema,
        'notes': Ack.string().optional(),
      })
      .strict() // No additional properties
      .refine((order) {
        // Custom validation: total must be positive
        final items = order['items'] as List;
        final total = items.fold<double>(0, (sum, item) => sum + item['total']);
        return total > 0;
      }, 'Order total must be positive')
      .transform<Map>((order) {
        // Calculate order summary
        final items = order['items'] as List;
        final subtotal = items.fold<double>(0, (sum, item) => sum + item['total']);
        final tax = subtotal * 0.08;
        final shipping = items.length > 5 ? 0 : 10.0;
        
        return {
          ...order,
          'summary': {
            'subtotal': subtotal,
            'tax': tax,
            'shipping': shipping,
            'total': subtotal + tax + shipping,
          },
          'processedAt': DateTime.now().toIso8601String(),
        };
      });
      
      // Test with valid order
      final order = orderSchema.parse({
        'orderId': '550e8400-e29b-41d4-a716-446655440000',
        'customer': {
          'email': 'customer@example.com',
          'name': 'John Doe',
        },
        'items': [
          {
            'id': '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
            'name': 'Widget',
            'price': 29.99,
            'quantity': 2,
          },
          {
            'id': '6ba7b814-9dad-11d1-80b4-00c04fd430c8',
            'name': 'Gadget',
            'price': 49.99,
            'quantity': 1,
          },
        ],
        'shippingAddress': {
          'street': '123 Main St',
          'city': 'Anytown',
          'country': 'USA',
          'postalCode': '12345',
        },
        'payment': {
          'method': 'card',
          'last4': '1234',
          'brand': 'visa',
        },
      });
      
      expect(order['summary']['subtotal'], equals(109.97));
      expect(order['summary']['total'], greaterThan(100));
      expect(order.containsKey('processedAt'), isTrue);
    });
  });
}
```

#### Test: Feature interaction edge cases
```dart
test('should handle edge cases in feature interactions', () {
  // Nested transformations with partial schemas
  final schema = Ack.object({
    'data': Ack.object({
      'value': Ack.string(),
      'metadata': Ack.object({
        'created': Ack.string().datetime(),
        'tags': Ack.list(Ack.string()),
      }),
    }),
  })
  .partial() // Make all fields optional
  .transform<Map>((obj) {
    // Handle missing data gracefully
    final data = obj['data'] as Map?;
    return {
      'hasData': data != null,
      'value': data?['value'] ?? 'default',
      'tagCount': (data?['metadata']?['tags'] as List?)?.length ?? 0,
    };
  });
  
  // Test with full data
  expect(
    schema.parse({
      'data': {
        'value': 'test',
        'metadata': {
          'created': '2024-01-01T00:00:00Z',
          'tags': ['a', 'b', 'c'],
        },
      },
    }),
    equals({
      'hasData': true,
      'value': 'test',
      'tagCount': 3,
    }),
  );
  
  // Test with missing data
  expect(
    schema.parse({}),
    equals({
      'hasData': false,
      'value': 'default',
      'tagCount': 0,
    }),
  );
});
```

#### Test: Validation error propagation across features
```dart
test('should propagate validation errors correctly across features', () {
  final schema = Ack.discriminated(
    discriminatorKey: 'type',
    schemas: {
      'user': Ack.object({
        'type': Ack.literal('user'),
        'profile': Ack.object({
          'age': Ack.int().min(18),
        }),
      }),
    },
  )
  .transform<Map>((data) => data)
  .refine((data) => data['profile']['age'] < 100, 'Age too high');
  
  // Test validation at different levels
  try {
    schema.parse({
      'type': 'user',
      'profile': {
        'age': 150,
      },
    });
    fail('Should have thrown');
  } catch (e) {
    expect(e, isA<ValidationException>());
    final errors = (e as ValidationException).errors;
    expect(errors.any((err) => err.message.contains('Age too high')), isTrue);
  }
});
```

### 7.2 Performance Testing

#### Test: Benchmark suite for validation performance
```dart
// File: packages/ack/test/performance/validation_benchmark_test.dart

import 'package:benchmark_harness/benchmark_harness.dart';

class SimpleValidationBenchmark extends BenchmarkBase {
  late final AckSchema schema;
  late final dynamic data;
  
  SimpleValidationBenchmark() : super('SimpleValidation');
  
  @override
  void setup() {
    schema = Ack.object({
      'id': Ack.string(),
      'name': Ack.string(),
      'age': Ack.int().min(0).max(150),
      'email': Ack.string().email(),
    });
    
    data = {
      'id': '123',
      'name': 'Test User',
      'age': 25,
      'email': 'test@example.com',
    };
  }
  
  @override
  void run() {
    schema.parse(data);
  }
}

class ComplexValidationBenchmark extends BenchmarkBase {
  late final AckSchema schema;
  late final dynamic data;
  
  ComplexValidationBenchmark() : super('ComplexValidation');
  
  @override
  void setup() {
    // Create complex nested schema
    final addressSchema = Ack.object({
      'street': Ack.string(),
      'city': Ack.string(),
      'state': Ack.string().length(2),
      'zip': Ack.string().pattern(RegExp(r'^\d{5}$')),
    });
    
    schema = Ack.object({
      'user': Ack.object({
        'id': Ack.string().uuid(),
        'profile': Ack.object({
          'firstName': Ack.string(),
          'lastName': Ack.string(),
          'age': Ack.int().min(0).max(150),
          'emails': Ack.list(Ack.string().email()).minItems(1).maxItems(5),
          'addresses': Ack.list(addressSchema),
        }),
      }),
      'metadata': Ack.object({
        'created': Ack.string().datetime(),
        'tags': Ack.list(Ack.string()).unique(),
      }),
    });
    
    data = {
      'user': {
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'profile': {
          'firstName': 'John',
          'lastName': 'Doe',
          'age': 30,
          'emails': ['john@example.com', 'john.doe@work.com'],
          'addresses': [
            {
              'street': '123 Main St',
              'city': 'Anytown',
              'state': 'CA',
              'zip': '12345',
            },
          ],
        },
      },
      'metadata': {
        'created': '2024-01-01T00:00:00Z',
        'tags': ['user', 'premium', 'verified'],
      },
    };
  }
  
  @override
  void run() {
    schema.parse(data);
  }
}

void main() {
  group('Performance Benchmarks', () {
    test('run validation benchmarks', () {
      SimpleValidationBenchmark().report();
      ComplexValidationBenchmark().report();
      
      // Add assertions for performance thresholds
      final simple = SimpleValidationBenchmark();
      final simpleTime = simple.measure();
      expect(simpleTime, lessThan(1000)); // Less than 1 microsecond
      
      final complex = ComplexValidationBenchmark();
      final complexTime = complex.measure();
      expect(complexTime, lessThan(10000)); // Less than 10 microseconds
    });
  });
}
```

#### Test: Memory usage with large schemas
```dart
// File: packages/ack/test/performance/memory_usage_test.dart

void main() {
  group('Memory Usage Tests', () {
    test('should handle large schemas efficiently', () {
      // Create schema with 1000 properties
      final properties = <String, AckSchema>{};
      for (int i = 0; i < 1000; i++) {
        properties['field$i'] = Ack.string().minLength(1).maxLength(100);
      }
      
      final schema = Ack.object(properties);
      
      // Create test data
      final data = <String, dynamic>{};
      for (int i = 0; i < 1000; i++) {
        data['field$i'] = 'value$i';
      }
      
      // Measure memory before
      final memBefore = getCurrentMemoryUsage();
      
      // Validate multiple times
      for (int i = 0; i < 100; i++) {
        schema.parse(data);
      }
      
      // Measure memory after
      final memAfter = getCurrentMemoryUsage();
      
      // Memory increase should be minimal
      final increase = memAfter - memBefore;
      expect(increase, lessThan(10 * 1024 * 1024)); // Less than 10MB
    });
    
    test('should not leak memory with repeated validations', () {
      final schema = Ack.object({
        'data': Ack.list(Ack.string()).minItems(100),
      });
      
      final data = {
        'data': List.generate(100, (i) => 'item$i'),
      };
      
      // Run many validations
      final memSamples = <int>[];
      
      for (int i = 0; i < 10; i++) {
        // Force GC
        forceGarbageCollection();
        
        // Measure memory
        memSamples.add(getCurrentMemoryUsage());
        
        // Run validations
        for (int j = 0; j < 1000; j++) {
          schema.parse(data);
        }
      }
      
      // Memory should stabilize (not continuously increase)
      final firstHalf = memSamples.take(5).reduce((a, b) => a + b) ~/ 5;
      final secondHalf = memSamples.skip(5).reduce((a, b) => a + b) ~/ 5;
      
      // Allow for some variation but not continuous growth
      expect((secondHalf - firstHalf).abs(), lessThan(1024 * 1024)); // 1MB tolerance
    });
  });
}
```

#### Test: Validation speed with deep nesting
```dart
// File: packages/ack/test/performance/deep_nesting_test.dart

void main() {
  group('Deep Nesting Performance', () {
    test('should handle 10+ levels of nesting efficiently', () {
      // Create deeply nested schema
      AckSchema createNestedSchema(int depth) {
        if (depth == 0) {
          return Ack.string();
        }
        
        return Ack.object({
          'value': Ack.string(),
          'nested': createNestedSchema(depth - 1),
        });
      }
      
      final schema = createNestedSchema(15); // 15 levels deep
      
      // Create deeply nested data
      dynamic createNestedData(int depth) {
        if (depth == 0) {
          return 'leaf-value';
        }
        
        return {
          'value': 'level-$depth',
          'nested': createNestedData(depth - 1),
        };
      }
      
      final data = createNestedData(15);
      
      // Measure validation time
      final stopwatch = Stopwatch()..start();
      
      for (int i = 0; i < 100; i++) {
        schema.parse(data);
      }
      
      stopwatch.stop();
      
      // Should complete in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // 100ms for 100 validations
      
      // Average time per validation
      final avgTime = stopwatch.elapsedMicroseconds / 100;
      print('Deep nesting (15 levels) avg time: ${avgTime}μs');
      expect(avgTime, lessThan(1000)); // Less than 1ms per validation
    });
  });
}
```

#### Profile: Hot paths in validation
```dart
// File: packages/ack/test/performance/profiling_test.dart

void main() {
  group('Performance Profiling', () {
    test('identify validation hot paths', () {
      final profiler = ValidationProfiler();
      
      // Complex schema to profile
      final schema = Ack.object({
        'users': Ack.list(
          Ack.object({
            'id': Ack.string().uuid(),
            'email': Ack.string().email(),
            'age': Ack.int().min(0).max(150),
            'tags': Ack.list(Ack.string()).unique(),
            'settings': Ack.object({
              'theme': Ack.string().enum(['light', 'dark']),
              'notifications': Ack.bool(),
            }),
          }),
        ).minItems(1).maxItems(1000),
      });
      
      // Test data
      final data = {
        'users': List.generate(100, (i) => {
          'id': '550e8400-e29b-41d4-a716-446655440$i'.padLeft(36, '0'),
          'email': 'user$i@example.com',
          'age': 20 + (i % 60),
          'tags': ['tag${i % 10}', 'tag${(i + 1) % 10}'],
          'settings': {
            'theme': i % 2 == 0 ? 'light' : 'dark',
            'notifications': i % 3 == 0,
          },
        }),
      };
      
      // Profile validation
      profiler.profile(() => schema.parse(data), iterations: 1000);
      
      // Analyze results
      final report = profiler.getReport();
      
      print('Performance Profile Report:');
      print('Total time: ${report.totalTime}ms');
      print('Average time: ${report.averageTime}ms');
      print('Min time: ${report.minTime}ms');
      print('Max time: ${report.maxTime}ms');
      
      // Hot paths should be identified
      expect(report.hotPaths, isNotEmpty);
      expect(report.hotPaths.first.name, contains('email')); // Email validation is expensive
    });
  });
}

class ValidationProfiler {
  final List<int> _times = [];
  
  void profile(Function() validation, {int iterations = 100}) {
    for (int i = 0; i < iterations; i++) {
      final stopwatch = Stopwatch()..start();
      validation();
      stopwatch.stop();
      _times.add(stopwatch.elapsedMicroseconds);
    }
  }
  
  ProfileReport getReport() {
    _times.sort();
    return ProfileReport(
      totalTime: _times.reduce((a, b) => a + b) / 1000,
      averageTime: _times.reduce((a, b) => a + b) / _times.length / 1000,
      minTime: _times.first / 1000,
      maxTime: _times.last / 1000,
      p50: _times[_times.length ~/ 2] / 1000,
      p95: _times[(_times.length * 0.95).floor()] / 1000,
      p99: _times[(_times.length * 0.99).floor()] / 1000,
      hotPaths: [], // Would need actual profiling data
    );
  }
}
```

#### Compare: Performance with other validation libraries
```dart
// File: packages/ack/test/performance/comparison_test.dart

void main() {
  group('Library Performance Comparison', () {
    test('compare with hand-written validation', () {
      // Ack schema
      final ackSchema = Ack.object({
        'name': Ack.string().minLength(3).maxLength(50),
        'age': Ack.int().min(0).max(150),
        'email': Ack.string().email(),
      });
      
      // Hand-written validation
      bool handWrittenValidation(Map<String, dynamic> data) {
        if (data['name'] is! String) return false;
        final name = data['name'] as String;
        if (name.length < 3 || name.length > 50) return false;
        
        if (data['age'] is! int) return false;
        final age = data['age'] as int;
        if (age < 0 || age > 150) return false;
        
        if (data['email'] is! String) return false;
        final email = data['email'] as String;
        if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(email)) return false;
        
        return true;
      }
      
      final testData = {
        'name': 'John Doe',
        'age': 30,
        'email': 'john@example.com',
      };
      
      // Benchmark Ack
      final ackStopwatch = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        ackSchema.tryParse(testData);
      }
      ackStopwatch.stop();
      
      // Benchmark hand-written
      final handStopwatch = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        handWrittenValidation(testData);
      }
      handStopwatch.stop();
      
      print('Ack time: ${ackStopwatch.elapsedMilliseconds}ms');
      print('Hand-written time: ${handStopwatch.elapsedMilliseconds}ms');
      print('Overhead: ${(ackStopwatch.elapsedMilliseconds / handStopwatch.elapsedMilliseconds * 100).toStringAsFixed(1)}%');
      
      // Ack should be within reasonable overhead
      expect(
        ackStopwatch.elapsedMilliseconds,
        lessThan(handStopwatch.elapsedMilliseconds * 3), // Less than 3x overhead
      );
    });
  });
}
```

#### Test: Performance of discriminated unions with 100+ variants
```dart
test('should handle discriminated unions with 100+ variants efficiently', () {
  // Already implemented in Phase 3
  // This is a reference to ensure it's included in performance suite
});
```

### 7.3 Real-World Scenarios

#### Test: API request/response validation
```dart
// File: packages/ack/test/integration/api_validation_test.dart

void main() {
  group('API Request/Response Validation', () {
    test('should validate REST API patterns', () {
      // Request validation schemas
      final createUserRequest = Ack.object({
        'username': Ack.string().minLength(3).maxLength(20).pattern(RegExp(r'^[a-zA-Z0-9_]+$')),
        'email': Ack.string().email(),
        'password': Ack.string().minLength(8).refine(
          (pwd) => RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(pwd),
          'Password must contain uppercase, lowercase, and number',
        ),
        'profile': Ack.object({
          'firstName': Ack.string(),
          'lastName': Ack.string(),
          'dateOfBirth': Ack.string().datetime().optional(),
        }),
      }).strict();
      
      // Response validation schemas
      final apiResponse = <T extends AckSchema>(T dataSchema) => Ack.discriminated(
        discriminatorKey: 'status',
        schemas: {
          'success': Ack.object({
            'status': Ack.literal('success'),
            'data': dataSchema,
            'metadata': Ack.object({
              'timestamp': Ack.string().datetime(),
              'version': Ack.string(),
            }),
          }),
          'error': Ack.object({
            'status': Ack.literal('error'),
            'error': Ack.object({
              'code': Ack.string(),
              'message': Ack.string(),
              'details': Ack.any().optional(),
            }),
          }),
        },
      );
      
      // Paginated response schema
      final paginatedResponse = <T extends AckSchema>(T itemSchema) => Ack.object({
        'items': Ack.list(itemSchema),
        'pagination': Ack.object({
          'page': Ack.int().positive(),
          'pageSize': Ack.int().positive().max(100),
          'totalItems': Ack.int().min(0),
          'totalPages': Ack.int().min(0),
        }),
      });
      
      // Test request validation
      final validRequest = createUserRequest.parse({
        'username': 'john_doe',
        'email': 'john@example.com',
        'password': 'SecurePass123',
        'profile': {
          'firstName': 'John',
          'lastName': 'Doe',
        },
      });
      
      expect(validRequest['username'], equals('john_doe'));
      
      // Test response validation
      final userSchema = Ack.object({
        'id': Ack.string().uuid(),
        'username': Ack.string(),
        'email': Ack.string().email(),
        'createdAt': Ack.string().datetime(),
      });
      
      final successResponse = apiResponse(userSchema).parse({
        'status': 'success',
        'data': {
          'id': '550e8400-e29b-41d4-a716-446655440000',
          'username': 'john_doe',
          'email': 'john@example.com',
          'createdAt': '2024-01-01T00:00:00Z',
        },
        'metadata': {
          'timestamp': '2024-01-01T00:00:00Z',
          'version': '1.0.0',
        },
      });
      
      expect(successResponse['status'], equals('success'));
    });
  });
}
```

#### Test: Form validation scenarios
```dart
// File: packages/ack/test/integration/form_validation_test.dart

void main() {
  group('Form Validation with Complex Dependencies', () {
    test('should handle conditional form fields', () {
      final registrationForm = Ack.object({
        'accountType': Ack.string().enum(['personal', 'business']),
        'email': Ack.string().email(),
        'password': Ack.string().minLength(8),
        'confirmPassword': Ack.string(),
        
        // Personal account fields
        'firstName': Ack.when(
          (data) => data['accountType'] == 'personal',
          Ack.string(),
          Ack.forbidden(),
        ),
        'lastName': Ack.when(
          (data) => data['accountType'] == 'personal',
          Ack.string(),
          Ack.forbidden(),
        ),
        
        // Business account fields
        'companyName': Ack.when(
          (data) => data['accountType'] == 'business',
          Ack.string(),
          Ack.forbidden(),
        ),
        'taxId': Ack.when(
          (data) => data['accountType'] == 'business',
          Ack.string().pattern(RegExp(r'^\d{2}-\d{7}$')),
          Ack.forbidden(),
        ),
        
        // Optional fields
        'newsletter': Ack.bool().withDefault(false),
        'referralCode': Ack.string().optional(),
      }).refine((data) {
        // Password confirmation must match
        return data['password'] == data['confirmPassword'];
      }, 'Passwords do not match');
      
      // Test personal account
      final personalAccount = registrationForm.parse({
        'accountType': 'personal',
        'email': 'user@example.com',
        'password': 'SecurePass123',
        'confirmPassword': 'SecurePass123',
        'firstName': 'John',
        'lastName': 'Doe',
      });
      
      expect(personalAccount['accountType'], equals('personal'));
      expect(personalAccount['newsletter'], isFalse); // Default applied
      
      // Test business account
      final businessAccount = registrationForm.parse({
        'accountType': 'business',
        'email': 'contact@company.com',
        'password': 'SecurePass123',
        'confirmPassword': 'SecurePass123',
        'companyName': 'Acme Corp',
        'taxId': '12-3456789',
        'newsletter': true,
      });
      
      expect(businessAccount['accountType'], equals('business'));
    });
    
    test('should validate multi-step form data', () {
      // Step schemas
      final step1Schema = Ack.object({
        'email': Ack.string().email(),
        'acceptTerms': Ack.literal(true),
      });
      
      final step2Schema = Ack.object({
        'plan': Ack.string().enum(['basic', 'pro', 'enterprise']),
        'billing': Ack.string().enum(['monthly', 'yearly']),
      });
      
      final step3Schema = Ack.object({
        'cardNumber': Ack.string().pattern(RegExp(r'^\d{16}$')),
        'expiryMonth': Ack.int().min(1).max(12),
        'expiryYear': Ack.int().min(2024).max(2034),
        'cvv': Ack.string().pattern(RegExp(r'^\d{3,4}$')),
      });
      
      // Combined form schema
      final completeFormSchema = Ack.object({
        'step1': step1Schema,
        'step2': step2Schema,
        'step3': step3Schema,
      }).transform<Map>((data) {
        // Calculate final pricing
        final plan = data['step2']['plan'];
        final billing = data['step2']['billing'];
        
        const prices = {
          'basic': {'monthly': 9.99, 'yearly': 99.99},
          'pro': {'monthly': 19.99, 'yearly': 199.99},
          'enterprise': {'monthly': 49.99, 'yearly': 499.99},
        };
        
        return {
          ...data,
          'summary': {
            'price': prices[plan]![billing],
            'savings': billing == 'yearly' ? prices[plan]!['monthly']! * 12 - prices[plan]!['yearly']! : 0,
          },
        };
      });
      
      // Test complete form
      final formData = completeFormSchema.parse({
        'step1': {
          'email': 'user@example.com',
          'acceptTerms': true,
        },
        'step2': {
          'plan': 'pro',
          'billing': 'yearly',
        },
        'step3': {
          'cardNumber': '4111111111111111',
          'expiryMonth': 12,
          'expiryYear': 2025,
          'cvv': '123',
        },
      });
      
      expect(formData['summary']['price'], equals(199.99));
      expect(formData['summary']['savings'], greaterThan(0));
    });
  });
}
```

#### Test: Configuration file validation
```dart
// File: packages/ack/test/integration/config_validation_test.dart

void main() {
  group('Configuration File Validation', () {
    test('should validate complex application config', () {
      final configSchema = Ack.object({
        'app': Ack.object({
          'name': Ack.string(),
          'version': Ack.string().pattern(RegExp(r'^\d+\.\d+\.\d+$')),
          'environment': Ack.string().enum(['development', 'staging', 'production']),
        }),
        
        'server': Ack.object({
          'host': Ack.string().ip(),
          'port': Ack.int().min(1).max(65535),
          'ssl': Ack.object({
            'enabled': Ack.bool(),
            'cert': Ack.when(
              (data) => data['enabled'] == true,
              Ack.string().minLength(1),
              Ack.forbidden(),
            ),
            'key': Ack.when(
              (data) => data['enabled'] == true,
              Ack.string().minLength(1),
              Ack.forbidden(),
            ),
          }),
        }),
        
        'database': Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'postgres': Ack.object({
              'type': Ack.literal('postgres'),
              'host': Ack.string(),
              'port': Ack.int().withDefault(5432),
              'database': Ack.string(),
              'username': Ack.string(),
              'password': Ack.string(),
              'ssl': Ack.bool().withDefault(true),
            }),
            'mongodb': Ack.object({
              'type': Ack.literal('mongodb'),
              'uri': Ack.string().pattern(RegExp(r'^mongodb(\+srv)?://')),
              'database': Ack.string(),
              'options': Ack.object({
                'retryWrites': Ack.bool().withDefault(true),
                'w': Ack.string().withDefault('majority'),
              }).partial(),
            }),
          },
        ),
        
        'features': Ack.object({
          'authentication': Ack.bool(),
          'rateLimit': Ack.object({
            'enabled': Ack.bool(),
            'maxRequests': Ack.int().positive(),
            'windowMs': Ack.int().positive(),
          }).partial(),
        }),
        
        'logging': Ack.object({
          'level': Ack.string().enum(['debug', 'info', 'warn', 'error']),
          'format': Ack.string().enum(['json', 'text']),
          'destinations': Ack.list(
            Ack.discriminated(
              discriminatorKey: 'type',
              schemas: {
                'console': Ack.object({
                  'type': Ack.literal('console'),
                  'colorize': Ack.bool().withDefault(true),
                }),
                'file': Ack.object({
                  'type': Ack.literal('file'),
                  'path': Ack.string(),
                  'maxSize': Ack.string().pattern(RegExp(r'^\d+[KMG]B$')),
                  'maxFiles': Ack.int().positive(),
                }),
              },
            ),
          ),
        }),
      }).strict();
      
      // Test valid config
      final config = configSchema.parse({
        'app': {
          'name': 'MyApp',
          'version': '1.2.3',
          'environment': 'production',
        },
        'server': {
          'host': '0.0.0.0',
          'port': 3000,
          'ssl': {
            'enabled': true,
            'cert': '/path/to/cert.pem',
            'key': '/path/to/key.pem',
          },
        },
        'database': {
          'type': 'postgres',
          'host': 'localhost',
          'database': 'myapp',
          'username': 'dbuser',
          'password': 'dbpass',
        },
        'features': {
          'authentication': true,
          'rateLimit': {
            'enabled': true,
            'maxRequests': 100,
            'windowMs': 60000,
          },
        },
        'logging': {
          'level': 'info',
          'format': 'json',
          'destinations': [
            {
              'type': 'console',
            },
            {
              'type': 'file',
              'path': '/var/log/app.log',
              'maxSize': '10MB',
              'maxFiles': 5,
            },
          ],
        },
      });
      
      expect(config['database']['port'], equals(5432)); // Default applied
      expect(config['database']['ssl'], isTrue); // Default applied
    });
  });
}
```

#### Test: Database model validation
```dart
// File: packages/ack/test/integration/database_validation_test.dart

void main() {
  group('Database Model Validation with Relations', () {
    test('should validate models with relationships', () {
      // Define model schemas
      final userSchema = Ack.object({
        'id': Ack.string().uuid(),
        'username': Ack.string().minLength(3).maxLength(20),
        'email': Ack.string().email(),
        'createdAt': Ack.string().datetime(),
        'updatedAt': Ack.string().datetime(),
      });
      
      final postSchema = Ack.object({
        'id': Ack.string().uuid(),
        'title': Ack.string().minLength(1).maxLength(200),
        'content': Ack.string(),
        'authorId': Ack.string().uuid(),
        'author': userSchema.optional(), // Populated via join
        'tags': Ack.list(Ack.string()).withDefault([]),
        'published': Ack.bool().withDefault(false),
        'publishedAt': Ack.string().datetime().nullable(),
        'createdAt': Ack.string().datetime(),
        'updatedAt': Ack.string().datetime(),
      });
      
      final commentSchema = Ack.object({
        'id': Ack.string().uuid(),
        'postId': Ack.string().uuid(),
        'post': postSchema.optional(), // Populated via join
        'userId': Ack.string().uuid(),
        'user': userSchema.optional(), // Populated via join
        'content': Ack.string().minLength(1).maxLength(1000),
        'createdAt': Ack.string().datetime(),
      });
      
      // Schema for populated query result
      final postWithCommentsSchema = postSchema.extend({
        'author': userSchema, // Required when populated
        'comments': Ack.list(
          commentSchema.extend({
            'user': userSchema, // Required when populated
          }),
        ).withDefault([]),
        'commentCount': Ack.int().min(0),
      });
      
      // Test populated data
      final populatedPost = postWithCommentsSchema.parse({
        'id': '123e4567-e89b-12d3-a456-426614174000',
        'title': 'Understanding Ack Validation',
        'content': 'Ack is a powerful validation library...',
        'authorId': '123e4567-e89b-12d3-a456-426614174001',
        'author': {
          'id': '123e4567-e89b-12d3-a456-426614174001',
          'username': 'johndoe',
          'email': 'john@example.com',
          'createdAt': '2024-01-01T00:00:00Z',
          'updatedAt': '2024-01-01T00:00:00Z',
        },
        'tags': ['validation', 'dart', 'flutter'],
        'published': true,
        'publishedAt': '2024-01-02T00:00:00Z',
        'comments': [
          {
            'id': '123e4567-e89b-12d3-a456-426614174002',
            'postId': '123e4567-e89b-12d3-a456-426614174000',
            'userId': '123e4567-e89b-12d3-a456-426614174003',
            'user': {
              'id': '123e4567-e89b-12d3-a456-426614174003',
              'username': 'janedoe',
              'email': 'jane@example.com',
              'createdAt': '2024-01-01T00:00:00Z',
              'updatedAt': '2024-01-01T00:00:00Z',
            },
            'content': 'Great article!',
            'createdAt': '2024-01-03T00:00:00Z',
          },
        ],
        'commentCount': 1,
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2024-01-02T00:00:00Z',
      });
      
      expect(populatedPost['author']['username'], equals('johndoe'));
      expect(populatedPost['comments'], hasLength(1));
    });
  });
}
```

#### Test: Streaming data validation
```dart
test('should validate streaming data efficiently', () async {
  final eventSchema = Ack.object({
    'id': Ack.string().uuid(),
    'timestamp': Ack.string().datetime(),
    'type': Ack.string().enum(['click', 'view', 'purchase']),
    'userId': Ack.string(),
    'data': Ack.any(),
  });
  
  // Simulate streaming data
  final eventStream = Stream.periodic(
    Duration(milliseconds: 10),
    (i) => {
      'id': '550e8400-e29b-41d4-a716-4466554400${i.toString().padLeft(2, '0')}',
      'timestamp': DateTime.now().toIso8601String(),
      'type': ['click', 'view', 'purchase'][i % 3],
      'userId': 'user${i % 10}',
      'data': {'index': i},
    },
  ).take(1000);
  
  // Validate streaming data
  int validCount = 0;
  int invalidCount = 0;
  
  await for (final event in eventStream) {
    try {
      eventSchema.parse(event);
      validCount++;
    } catch (e) {
      invalidCount++;
    }
  }
  
  expect(validCount, equals(1000));
  expect(invalidCount, equals(0));
});
```

#### Test: Partial validation scenarios
```dart
test('should support partial validation for drafts', () {
  // Full schema for complete documents
  final articleSchema = Ack.object({
    'title': Ack.string().minLength(1).maxLength(200),
    'content': Ack.string().minLength(100),
    'author': Ack.object({
      'id': Ack.string().uuid(),
      'name': Ack.string(),
    }),
    'tags': Ack.list(Ack.string()).minItems(1).maxItems(10),
    'publishedAt': Ack.string().datetime(),
  });
  
  // Draft schema - all fields optional, relaxed constraints
  final draftSchema = articleSchema
    .partial()
    .extend({
      'isDraft': Ack.literal(true),
      'savedAt': Ack.string().datetime(),
    });
  
  // Validation levels
  final validationLevels = {
    'minimal': draftSchema,
    'moderate': draftSchema.refine((draft) {
      // At least title or content should be present
      return draft.containsKey('title') || draft.containsKey('content');
    }, 'Draft must have at least title or content'),
    'strict': articleSchema,
  };
  
  // Test progressive validation
  final emptyDraft = {
    'isDraft': true,
    'savedAt': '2024-01-01T00:00:00Z',
  };
  
  expect(() => validationLevels['minimal']!.parse(emptyDraft), returnsNormally);
  expect(() => validationLevels['moderate']!.parse(emptyDraft), throwsA(isA<ValidationException>()));
  
  final partialDraft = {
    'title': 'Work in Progress',
    'isDraft': true,
    'savedAt': '2024-01-01T00:00:00Z',
  };
  
  expect(() => validationLevels['moderate']!.parse(partialDraft), returnsNormally);
  expect(() => validationLevels['strict']!.parse(partialDraft), throwsA(isA<ValidationException>()));
});
```

## Validation Checklist

- [ ] Cross-feature integration tests implemented
- [ ] Performance benchmarks created
- [ ] Memory usage tests added
- [ ] Deep nesting performance verified
- [ ] Hot paths profiled
- [ ] Real-world scenarios tested
- [ ] API validation patterns implemented
- [ ] Form validation with dependencies
- [ ] Configuration file validation
- [ ] Database model validation
- [ ] Streaming data validation
- [ ] Partial validation scenarios
- [ ] 20+ integration tests added
- [ ] Performance meets targets

## Success Metrics

- All features work seamlessly together
- Performance benchmarks established
- Memory usage is efficient
- Real-world patterns validated
- No performance regressions
- Clear performance baselines set