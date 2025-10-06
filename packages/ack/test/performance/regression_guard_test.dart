import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Performance Regression Guards', () {
    test('string validation with multiple constraints should remain fast', () {
      final schema = Ack.string()
          .minLength(5)
          .maxLength(50)
          .email()
          .endsWith('.com');

      const testEmail = 'test.user@example.com';

      // Warm up
      for (int i = 0; i < 100; i++) {
        schema.safeParse(testEmail);
      }

      final stopwatch = Stopwatch()..start();
      const iterations = 10000;

      for (int i = 0; i < iterations; i++) {
        schema.safeParse(testEmail);
      }

      stopwatch.stop();

      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;

      // Multiple string constraints should still be fast
      expect(avgMicroseconds, lessThan(10));
    });

    test('discriminated union validation should be efficient', () {
      final schema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'user': Ack.object({
            'type': Ack.literal('user'),
            'name': Ack.string(),
            'age': Ack.integer(),
          }),
          'admin': Ack.object({
            'type': Ack.literal('admin'),
            'name': Ack.string(),
            'permissions': Ack.list(Ack.string()),
          }),
          'guest': Ack.object({
            'type': Ack.literal('guest'),
            'sessionId': Ack.string(),
          }),
        },
      );

      final testData = [
        {'type': 'user', 'name': 'John', 'age': 30},
        {
          'type': 'admin',
          'name': 'Jane',
          'permissions': ['read', 'write'],
        },
        {'type': 'guest', 'sessionId': 'abc123'},
      ];

      final stopwatch = Stopwatch()..start();
      const iterations = 5000;

      for (int i = 0; i < iterations; i++) {
        schema.parse(testData[i % 3]);
      }

      stopwatch.stop();

      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;

      // Discriminated unions should dispatch quickly. CI runners can be noisier
      // than local dev machines, so we allow a slightly higher ceiling while
      // still catching major regressions.
      expect(avgMicroseconds, lessThan(35));
    });

    test('transform operations should not add significant overhead', () {
      final baseSchema = Ack.object({'x': Ack.integer(), 'y': Ack.integer()});

      final transformedSchema = baseSchema.transform<int>((point) {
        return (point!['x'] as int) + (point['y'] as int);
      });

      final testData = {'x': 10, 'y': 20};

      // Measure base schema
      final baseStopwatch = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        baseSchema.parse(testData);
      }
      baseStopwatch.stop();

      // Measure transformed schema
      final transformStopwatch = Stopwatch()..start();
      for (int i = 0; i < 10000; i++) {
        transformedSchema.parse(testData);
      }
      transformStopwatch.stop();

      final overhead =
          transformStopwatch.elapsedMicroseconds /
          baseStopwatch.elapsedMicroseconds;

      // Transform should add less than 50% overhead
      expect(overhead, lessThan(1.5));
    });

    test('refine operations should short-circuit on validation failure', () {
      final schema = Ack.object({'value': Ack.integer()}).refine((data) {
        // This should not be called if basic validation fails
        fail('Refine should not run on invalid data');
      });

      // This should fail on type validation before refine
      expect(
        () => schema.parse({'value': 'not-a-number'}),
        throwsA(isA<AckException>()),
      );
    });
  });
}
