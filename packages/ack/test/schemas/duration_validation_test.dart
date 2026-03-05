import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Duration Validation', () {
    group('Basic parsing', () {
      test('parses int milliseconds into Duration', () {
        final schema = Ack.duration();
        final result = schema.parse(1500)!;

        expect(result, isA<Duration>());
        expect(result.inMilliseconds, 1500);
      });

      test('round-trips milliseconds for zero and negative values', () {
        final schema = Ack.duration();

        expect(schema.parse(0)!.inMilliseconds, 0);
        expect(schema.parse(-500)!.inMilliseconds, -500);
      });
    });

    group('Rejects invalid input', () {
      test('rejects string input', () {
        final schema = Ack.duration();
        final result = schema.safeParse('not-a-number');

        expect(result.isFail, isTrue);
      });

      test('rejects null input when not nullable', () {
        final schema = Ack.duration();
        final result = schema.safeParse(null);

        expect(result.isFail, isTrue);
      });

      test('accepts null when nullable', () {
        final schema = Ack.anyOf([Ack.duration(), Ack.any().nullable()]);
        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
      });
    });

    group('.min() constraint', () {
      final schema = Ack.duration().min(Duration(milliseconds: 1500));

      test('accepts duration exactly at min boundary (inclusive)', () {
        final result = schema.safeParse(1500);

        expect(result.isOk, isTrue);
        expect(result.getOrThrow()!.inMilliseconds, 1500);
      });

      test('accepts duration above min', () {
        expect(schema.safeParse(2000).isOk, isTrue);
      });

      test('rejects duration below min', () {
        final result = schema.safeParse(1499);

        expect(result.isFail, isTrue);
        final error = result.getError() as SchemaConstraintsError;
        expect(error.constraints.first.message, contains('1500 milliseconds'));
      });
    });

    group('.max() constraint', () {
      final schema = Ack.duration().max(Duration(milliseconds: 2000));

      test('accepts duration exactly at max boundary (inclusive)', () {
        expect(schema.safeParse(2000).isOk, isTrue);
      });

      test('accepts duration below max', () {
        expect(schema.safeParse(1999).isOk, isTrue);
      });

      test('rejects duration above max', () {
        final result = schema.safeParse(2001);

        expect(result.isFail, isTrue);
        final error = result.getError() as SchemaConstraintsError;
        expect(error.constraints.first.message, contains('2000 milliseconds'));
      });
    });

    group('Range validation (.min().max())', () {
      final schema = Ack.duration()
          .min(Duration(seconds: 1))
          .max(Duration(seconds: 2));

      test('accepts duration within range', () {
        expect(schema.safeParse(1500).isOk, isTrue);
      });

      test('accepts duration at min boundary', () {
        expect(schema.safeParse(1000).isOk, isTrue);
      });

      test('accepts duration at max boundary', () {
        expect(schema.safeParse(2000).isOk, isTrue);
      });

      test('rejects duration outside range', () {
        expect(schema.safeParse(999).isFail, isTrue);
        expect(schema.safeParse(2001).isFail, isTrue);
      });
    });

    group('Composition', () {
      test('works with optional() in object schema', () {
        final objSchema = Ack.object({'timeoutMs': Ack.duration().optional()});

        expect(objSchema.safeParse({}).isOk, isTrue);
        expect(objSchema.safeParse({'timeoutMs': 1500}).isOk, isTrue);

        final parsed = objSchema.parse({'timeoutMs': 1500})!;
        expect(parsed['timeoutMs'], isA<Duration>());
      });

      test('preserves constraints with optional()', () {
        final timeoutSchema = Ack.duration()
            .min(Duration(milliseconds: 1000))
            .optional();
        final objSchema = Ack.object({'timeoutMs': timeoutSchema});

        expect(objSchema.safeParse({}).isOk, isTrue);
        expect(objSchema.safeParse({'timeoutMs': 1000}).isOk, isTrue);
        expect(objSchema.safeParse({'timeoutMs': 999}).isFail, isTrue);
      });
    });

    group('Error quality', () {
      test('min error includes clear ms values', () {
        final schema = Ack.duration().min(Duration(milliseconds: 1500));
        final result = schema.safeParse(1000);

        final error = result.getError() as SchemaConstraintsError;
        final message = error.constraints.first.message;
        expect(message, contains('at least 1500 milliseconds'));
        expect(message, contains('got 1000 milliseconds'));
      });

      test('max error includes clear ms values', () {
        final schema = Ack.duration().max(Duration(milliseconds: 500));
        final result = schema.safeParse(600);

        final error = result.getError() as SchemaConstraintsError;
        final message = error.constraints.first.message;
        expect(message, contains('at most 500 milliseconds'));
        expect(message, contains('got 600 milliseconds'));
      });

      test('error context includes comparisonType, value, and reference', () {
        final schema = Ack.duration().min(Duration(milliseconds: 1500));
        final result = schema.safeParse(1000);

        final error = result.getError() as SchemaConstraintsError;
        final context = error.constraints.first.context;
        expect(context?['comparisonType'], 'min');
        expect(context?['value'], 1000);
        expect(context?['reference'], 1500);
      });

      test('uses duration_min constraint key', () {
        final schema = Ack.duration().min(Duration(milliseconds: 1500));
        final result = schema.safeParse(1000);

        final error = result.getError() as SchemaConstraintsError;
        expect(error.constraints.first.constraintKey, 'duration_min');
      });

      test('uses duration_max constraint key', () {
        final schema = Ack.duration().max(Duration(milliseconds: 500));
        final result = schema.safeParse(600);

        final error = result.getError() as SchemaConstraintsError;
        expect(error.constraints.first.constraintKey, 'duration_max');
      });
    });

    group('JSON Schema', () {
      test('emits type integer and x-transformed', () {
        final schema = Ack.duration();
        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['type'], 'integer');
        expect(jsonSchema['x-transformed'], isTrue);
      });

      test('emits minimum with milliseconds value', () {
        final schema = Ack.duration().min(Duration(milliseconds: 1500));
        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['minimum'], 1500);
      });

      test('emits maximum with milliseconds value', () {
        final schema = Ack.duration().max(Duration(milliseconds: 2000));
        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['maximum'], 2000);
      });
    });

    group('Real-world use cases', () {
      test('timeout validation', () {
        final schema = Ack.duration()
            .min(Duration(milliseconds: 100))
            .max(Duration(seconds: 30));

        expect(schema.safeParse(100).isOk, isTrue);
        expect(schema.safeParse(15000).isOk, isTrue);
        expect(schema.safeParse(50).isFail, isTrue);
        expect(schema.safeParse(31000).isFail, isTrue);
      });

      test('polling interval validation', () {
        final schema = Ack.duration()
            .min(Duration(milliseconds: 500))
            .max(Duration(minutes: 1));

        expect(schema.safeParse(500).isOk, isTrue);
        expect(schema.safeParse(10000).isOk, isTrue);
        expect(schema.safeParse(499).isFail, isTrue);
        expect(schema.safeParse(61000).isFail, isTrue);
      });

      test('animation durations in object schema', () {
        final schema = Ack.object({
          'fadeIn': Ack.duration().max(Duration(seconds: 1)),
          'delay': Ack.duration().min(Duration.zero).optional(),
          'fadeOut': Ack.duration().max(Duration(seconds: 1)),
        });

        final valid = {'fadeIn': 300, 'delay': 100, 'fadeOut': 250};
        final result = schema.safeParse(valid);
        expect(result.isOk, isTrue);

        final parsed = result.getOrThrow()!;
        expect(parsed['fadeIn'], isA<Duration>());
        expect(parsed['delay'], isA<Duration>());
        expect(parsed['fadeOut'], isA<Duration>());

        expect(
          schema.safeParse({'fadeIn': 1500, 'fadeOut': 250}).isFail,
          isTrue,
        );
      });
    });
  });
}
