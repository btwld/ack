import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('DateTime Validation', () {
    group('Ack.date() - Format Validation', () {
      test('parses valid ISO 8601 date (YYYY-MM-DD)', () {
        final schema = Ack.date();
        final result = schema.parse('2025-06-15')!;
        expect(result, isA<DateTime>());
        expect(result.year, 2025);
        expect(result.month, 6);
        expect(result.day, 15);
      });

      test('rejects invalid date format', () {
        final schema = Ack.date();
        expect(() => schema.parse('not-a-date'), throwsA(isA<AckException>()));
      });

      test('rejects datetime string (has time component)', () {
        final schema = Ack.date();
        final result = schema.safeParse('2025-06-15T10:30:00Z');
        expect(result.isFail, isTrue);
        expect(
          result.getError().message,
          contains('Invalid ISO 8601 date format'),
        );
      });

      test('rejects date with wrong format (slash separators)', () {
        final schema = Ack.date();
        final result = schema.safeParse('2025/06/15');
        expect(result.isFail, isTrue);
      });

      test('rejects incomplete date', () {
        final schema = Ack.date();
        final result = schema.safeParse('2025-06');
        expect(result.isFail, isTrue);
      });

      test('parses date at year boundaries correctly', () {
        final schema = Ack.date();
        final result1 = schema.parse('2025-01-01')!;
        expect(result1.month, 1);
        expect(result1.day, 1);

        final result2 = schema.parse('2025-12-31')!;
        expect(result2.month, 12);
        expect(result2.day, 31);
      });
    });

    group('Ack.datetime() - Format Validation', () {
      test('parses valid ISO 8601 datetime with Z timezone', () {
        final schema = Ack.datetime();
        final result = schema.parse('2025-06-15T10:30:00Z')!;
        expect(result, isA<DateTime>());
        expect(result.year, 2025);
        expect(result.month, 6);
        expect(result.day, 15);
      });

      test('parses datetime with offset timezone', () {
        final schema = Ack.datetime();
        final result = schema.parse('2025-06-15T10:30:00+05:30');
        expect(result, isA<DateTime>());
      });

      test('parses datetime with negative offset', () {
        final schema = Ack.datetime();
        final result = schema.parse('2025-06-15T10:30:00-08:00');
        expect(result, isA<DateTime>());
      });

      test('rejects date-only string (missing time)', () {
        final schema = Ack.datetime();
        final result = schema.safeParse('2025-06-15');
        expect(result.isFail, isTrue);
        expect(
          result.getError().message,
          contains('Invalid ISO 8601 date-time format'),
        );
      });

      test('rejects datetime without timezone', () {
        final schema = Ack.datetime();
        final result = schema.safeParse('2025-06-15T10:30:00');
        expect(result.isFail, isTrue);
      });

      test('rejects invalid datetime format', () {
        final schema = Ack.datetime();
        expect(
          () => schema.parse('not-a-datetime'),
          throwsA(isA<AckException>()),
        );
      });
    });

    group('.min() Constraint', () {
      final minDate = DateTime(2000, 1, 1);

      test('accepts date exactly matching min (inclusive)', () {
        final schema = Ack.date().min(minDate);
        final result = schema.safeParse('2000-01-01');
        expect(result.isOk, isTrue);
        expect(result.getOrThrow()!.year, 2000);
      });

      test('accepts date after min', () {
        final schema = Ack.date().min(minDate);
        final result = schema.safeParse('2005-06-15');
        expect(result.isOk, isTrue);
      });

      test('accepts date many years after min', () {
        final schema = Ack.date().min(minDate);
        final result = schema.safeParse('2025-12-31');
        expect(result.isOk, isTrue);
      });

      test('rejects date before min', () {
        final schema = Ack.date().min(minDate);
        final result = schema.safeParse('1999-12-31');
        expect(result.isFail, isTrue);

        final error = result.getError() as SchemaConstraintsError;
        expect(
          error.constraints.first.message,
          contains('on or after 2000-01-01'),
        );
      });

      test('rejects date one day before min', () {
        final schema = Ack.date().min(DateTime(2025, 6, 15));
        final result = schema.safeParse('2025-06-14');
        expect(result.isFail, isTrue);
      });
    });

    group('.max() Constraint', () {
      final maxDate = DateTime(2025, 12, 31);

      test('accepts date exactly matching max (inclusive)', () {
        final schema = Ack.date().max(maxDate);
        final result = schema.safeParse('2025-12-31');
        expect(result.isOk, isTrue);
      });

      test('accepts date before max', () {
        final schema = Ack.date().max(maxDate);
        final result = schema.safeParse('2020-01-01');
        expect(result.isOk, isTrue);
      });

      test('accepts date many years before max', () {
        final schema = Ack.date().max(maxDate);
        final result = schema.safeParse('2000-01-01');
        expect(result.isOk, isTrue);
      });

      test('rejects date after max', () {
        final schema = Ack.date().max(maxDate);
        final result = schema.safeParse('2026-01-01');
        expect(result.isFail, isTrue);

        final error = result.getError() as SchemaConstraintsError;
        expect(
          error.constraints.first.message,
          contains('on or before 2025-12-31'),
        );
      });

      test('rejects date one day after max', () {
        final schema = Ack.date().max(DateTime(2025, 6, 15));
        final result = schema.safeParse('2025-06-16');
        expect(result.isFail, isTrue);
      });
    });

    group('Range Validation (.min().max())', () {
      final schema = Ack.date()
          .min(DateTime(2020, 1, 1))
          .max(DateTime(2025, 12, 31));

      test('accepts date within range', () {
        expect(schema.safeParse('2022-06-15').isOk, isTrue);
      });

      test('accepts date at min boundary', () {
        expect(schema.safeParse('2020-01-01').isOk, isTrue);
      });

      test('accepts date at max boundary', () {
        expect(schema.safeParse('2025-12-31').isOk, isTrue);
      });

      test('accepts date in middle of range', () {
        expect(schema.safeParse('2023-07-04').isOk, isTrue);
      });

      test('rejects date before range', () {
        expect(schema.safeParse('2019-12-31').isFail, isTrue);
      });

      test('rejects date after range', () {
        expect(schema.safeParse('2026-01-01').isFail, isTrue);
      });

      test('rejects date far before range', () {
        expect(schema.safeParse('2000-01-01').isFail, isTrue);
      });

      test('rejects date far after range', () {
        expect(schema.safeParse('2030-01-01').isFail, isTrue);
      });
    });

    group('Composition with nullable/optional', () {
      test('works with optional() in object schema', () {
        final objSchema = Ack.object({'date': Ack.date().optional()});
        final result = objSchema.safeParse({});
        expect(result.isOk, isTrue);
      });

      test('optional date field can be provided', () {
        final objSchema = Ack.object({'date': Ack.date().optional()});
        final result = objSchema.safeParse({'date': '2025-06-15'});
        expect(result.isOk, isTrue);
        expect(result.getOrThrow()!['date'], isA<DateTime>());
      });

      test('optional preserves constraints', () {
        final schema = Ack.date().min(DateTime(2020, 1, 1)).optional();
        // Missing field is okay
        final objSchema = Ack.object({'date': schema});
        expect(objSchema.safeParse({}).isOk, isTrue);

        // Valid date passes
        expect(objSchema.safeParse({'date': '2025-06-15'}).isOk, isTrue);

        // Invalid date fails
        expect(objSchema.safeParse({'date': '2019-12-31'}).isFail, isTrue);
      });
    });

    group('Error Quality', () {
      test('provides clear error message with ISO 8601 dates', () {
        final schema = Ack.date().min(DateTime(2025, 1, 1));
        final result = schema.safeParse('2024-12-31');

        expect(result.isFail, isTrue);
        final error = result.getError() as SchemaConstraintsError;
        expect(error.constraints.first.message, contains('2025-01-01'));
        expect(error.constraints.first.message, contains('2024-12-31'));
      });

      test('provides context with structured data', () {
        final schema = Ack.date().min(DateTime(2025, 1, 1));
        final result = schema.safeParse('2024-12-31');

        final error = result.getError() as SchemaConstraintsError;
        final context = error.constraints.first.context;
        expect(context?['comparisonType'], 'min');
        expect(context?['reference'], contains('2025-01-01'));
        expect(context?['value'], contains('2024-12-31'));
      });

      test('error message for max constraint is clear', () {
        final schema = Ack.date().max(DateTime(2025, 12, 31));
        final result = schema.safeParse('2026-01-01');

        final error = result.getError() as SchemaConstraintsError;
        expect(error.constraints.first.message, contains('on or before'));
      });

      test('constraint key is correct', () {
        final schema = Ack.date().min(DateTime(2025, 1, 1));
        final result = schema.safeParse('2024-12-31');

        final error = result.getError() as SchemaConstraintsError;
        expect(error.constraints.first.constraintKey, 'datetime_min');
      });
    });

    group('JSON Schema', () {
      test('emits format: date and x-transformed', () {
        final schema = Ack.date();
        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['format'], 'date');
        expect(jsonSchema['x-transformed'], isTrue);
      });

      test('datetime emits format: date-time', () {
        final schema = Ack.datetime();
        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['format'], 'date-time');
        expect(jsonSchema['x-transformed'], isTrue);
      });

      test('base schema includes type: string', () {
        final schema = Ack.date();
        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['type'], 'string');
      });

      test('includes formatMinimum when min constraint is applied', () {
        final schema = Ack.date().min(DateTime(2025, 1, 1));
        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['formatMinimum'], isNotNull);
        expect(jsonSchema['formatMinimum'], contains('2025-01-01'));
      });

      test('includes formatMaximum when max constraint is applied', () {
        final schema = Ack.date().max(DateTime(2025, 12, 31));
        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['formatMaximum'], isNotNull);
        expect(jsonSchema['formatMaximum'], contains('2025-12-31'));
      });

      test('includes both formatMinimum and formatMaximum for range', () {
        final schema = Ack.date()
            .min(DateTime(2025, 1, 1))
            .max(DateTime(2025, 12, 31));
        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['formatMinimum'], isNotNull);
        expect(jsonSchema['formatMaximum'], isNotNull);
        expect(jsonSchema['formatMinimum'], contains('2025-01-01'));
        expect(jsonSchema['formatMaximum'], contains('2025-12-31'));
      });
    });

    group('Real-World Use Cases', () {
      test('18+ age validation', () {
        final now = DateTime(2025, 1, 1);
        final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
        final schema = Ack.date().max(eighteenYearsAgo);

        // Valid: 19 years old (born Dec 31, 2005)
        expect(schema.safeParse('2005-12-31').isOk, isTrue);

        // Valid: exactly 18 years old (born Jan 1, 2007)
        expect(schema.safeParse('2007-01-01').isOk, isTrue);

        // Invalid: 17 years old (born Jan 2, 2007)
        expect(schema.safeParse('2007-01-02').isFail, isTrue);
      });

      test('future event date validation', () {
        final now = DateTime(2025, 1, 1);
        final schema = Ack.date().min(now);

        // Valid: future date
        expect(schema.safeParse('2025-06-15').isOk, isTrue);

        // Invalid: past date
        expect(schema.safeParse('2024-12-31').isFail, isTrue);

        // Valid: today (inclusive)
        expect(schema.safeParse('2025-01-01').isOk, isTrue);
      });

      test('specific year validation', () {
        final year2025 = Ack.date()
            .min(DateTime(2025, 1, 1))
            .max(DateTime(2025, 12, 31));

        // Valid: within 2025
        expect(year2025.safeParse('2025-06-15').isOk, isTrue);
        expect(year2025.safeParse('2025-01-01').isOk, isTrue);
        expect(year2025.safeParse('2025-12-31').isOk, isTrue);

        // Invalid: before 2025
        expect(year2025.safeParse('2024-12-31').isFail, isTrue);

        // Invalid: after 2025
        expect(year2025.safeParse('2026-01-01').isFail, isTrue);
      });

      test('appointment scheduling (business hours constraint)', () {
        // Appointments must be scheduled at least 24 hours in advance
        final tomorrow = DateTime(2025, 1, 2);
        final schema = Ack.date().min(tomorrow);

        expect(schema.safeParse('2025-01-02').isOk, isTrue);
        expect(schema.safeParse('2025-01-10').isOk, isTrue);
        expect(schema.safeParse('2025-01-01').isFail, isTrue);
      });

      test('historical records (before certain date)', () {
        // Historical records must be before year 2000
        final schema = Ack.date().max(DateTime(1999, 12, 31));

        expect(schema.safeParse('1999-12-31').isOk, isTrue);
        expect(schema.safeParse('1990-01-01').isOk, isTrue);
        expect(schema.safeParse('2000-01-01').isFail, isTrue);
      });

      test('in object schema with multiple date fields', () {
        final schema = Ack.object({
          'startDate': Ack.date(),
          'endDate': Ack.date(),
          'birthdate': Ack.date().max(DateTime(2007, 1, 1)),
        });

        final validData = {
          'startDate': '2025-01-01',
          'endDate': '2025-12-31',
          'birthdate': '2000-01-01',
        };

        final result = schema.safeParse(validData);
        expect(result.isOk, isTrue);

        final parsed = result.getOrThrow()!;
        expect(parsed['startDate'], isA<DateTime>());
        expect(parsed['endDate'], isA<DateTime>());
        expect(parsed['birthdate'], isA<DateTime>());
      });
    });

    group('Datetime with constraints', () {
      test('datetime min constraint works', () {
        final now = DateTime.utc(2025, 1, 1, 10, 30);
        final schema = Ack.datetime().min(now);

        expect(schema.safeParse('2025-01-01T10:30:00Z').isOk, isTrue);
        expect(schema.safeParse('2025-01-01T11:00:00Z').isOk, isTrue);
        expect(schema.safeParse('2025-01-01T10:00:00Z').isFail, isTrue);
      });

      test('datetime max constraint works', () {
        final deadline = DateTime.utc(2025, 12, 31, 23, 59);
        final schema = Ack.datetime().max(deadline);

        expect(schema.safeParse('2025-12-31T23:59:00Z').isOk, isTrue);
        expect(schema.safeParse('2025-12-31T23:58:00Z').isOk, isTrue);
        expect(schema.safeParse('2025-12-31T23:59:01Z').isFail, isTrue);
      });

      test('datetime range validation', () {
        final start = DateTime.utc(2025, 6, 1, 0, 0);
        final end = DateTime.utc(2025, 6, 30, 23, 59);
        final schema = Ack.datetime().min(start).max(end);

        expect(schema.safeParse('2025-06-15T12:00:00Z').isOk, isTrue);
        expect(schema.safeParse('2025-05-31T23:59:59Z').isFail, isTrue);
        expect(schema.safeParse('2025-07-01T00:00:00Z').isFail, isTrue);
      });
    });
  });
}
