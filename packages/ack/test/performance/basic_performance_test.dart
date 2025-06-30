import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Basic Performance Tests', () {
    test('should validate simple schemas quickly', () {
      final schema = Ack.object({
        'name': Ack.string(),
        'age': Ack.integer().min(0).max(150),
        'email': Ack.string().email(),
      });

      final data = {
        'name': 'John Doe',
        'age': 30,
        'email': 'john@example.com',
      };

      // Warm up
      for (int i = 0; i < 100; i++) {
        schema.parse(data);
      }

      // Measure
      final stopwatch = Stopwatch()..start();
      const iterations = 10000;
      
      for (int i = 0; i < iterations; i++) {
        schema.parse(data);
      }
      
      stopwatch.stop();
      
      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;
      print('Simple schema validation: ${avgMicroseconds.toStringAsFixed(2)}μs per validation');
      
      // Should be fast - less than 100 microseconds per validation
      expect(avgMicroseconds, lessThan(100));
    });

    test('should handle deeply nested schemas without stack overflow', () {
      // Create a deeply nested schema (10 levels)
      AckSchema createNestedSchema(int depth) {
        if (depth == 0) {
          return Ack.string();
        }
        return Ack.object({
          'value': Ack.string(),
          'nested': createNestedSchema(depth - 1),
        });
      }

      final deepSchema = createNestedSchema(10);
      
      // Create corresponding nested data
      dynamic createNestedData(int depth) {
        if (depth == 0) {
          return 'leaf';
        }
        return {
          'value': 'level-$depth',
          'nested': createNestedData(depth - 1),
        };
      }

      final deepData = createNestedData(10);
      
      // Should not throw stack overflow
      expect(() => deepSchema.parse(deepData), returnsNormally);
    });

    test('should validate large arrays efficiently', () {
      final schema = Ack.list(
        Ack.object({
          'id': Ack.string().uuid(),
          'name': Ack.string(),
          'active': Ack.boolean(),
        })
      );

      // Create large array
      final largeArray = List.generate(1000, (i) => {
        'id': '550e8400-e29b-41d4-a716-446655440${i.toString().padLeft(3, '0')}',
        'name': 'Item $i',
        'active': i % 2 == 0,
      });

      final stopwatch = Stopwatch()..start();
      schema.parse(largeArray);
      stopwatch.stop();
      
      print('Large array (1000 items) validation: ${stopwatch.elapsedMilliseconds}ms');
      
      // Should complete in reasonable time (less than 100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('should not have memory leaks with repeated validations', () {
      final schema = Ack.object({
        'data': Ack.list(Ack.string()),
      });

      final testData = {
        'data': List.generate(100, (i) => 'item-$i'),
      };

      // Run many validations to check for memory leaks
      // In a real scenario, we'd use memory profiling tools
      // This is a basic smoke test
      expect(() {
        for (int i = 0; i < 10000; i++) {
          schema.parse(testData);
        }
      }, returnsNormally);
    });

    test('complex schema performance should scale linearly', () {
      // Test with different sizes to ensure linear scaling
      final measurements = <int, double>{};

      for (final size in [10, 50, 100]) {
        final properties = <String, AckSchema>{};
        for (int i = 0; i < size; i++) {
          properties['field$i'] = Ack.string().minLength(1).maxLength(100);
        }
        
        final schema = Ack.object(properties);
        
        final data = <String, dynamic>{};
        for (int i = 0; i < size; i++) {
          data['field$i'] = 'value$i';
        }

        // Warm up
        for (int i = 0; i < 10; i++) {
          schema.parse(data);
        }

        // Measure
        final stopwatch = Stopwatch()..start();
        const iterations = 1000;
        
        for (int i = 0; i < iterations; i++) {
          schema.parse(data);
        }
        
        stopwatch.stop();
        measurements[size] = stopwatch.elapsedMicroseconds / iterations;
      }

      print('Performance scaling:');
      measurements.forEach((size, time) {
        print('  $size fields: ${time.toStringAsFixed(2)}μs');
      });

      // Check that performance scales roughly linearly
      // Time for 100 fields should be less than 15x time for 10 fields
      expect(measurements[100]! / measurements[10]!, lessThan(15));
    });
  });
}