import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('AnyOf Null Handling', () {
    test('should accept null through nullable member schema', () {
      // This is the critical test case from the feedback
      // A nullable member schema should be able to accept null
      final schema = Ack.anyOf([Ack.string().nullable(), Ack.integer()]);

      final result = schema.safeParse(null);
      expect(
        result.isOk,
        isTrue,
        reason: 'Nullable member schema should accept null',
      );
      expect(result.getOrNull(), isNull);
    });

    test('should reject null when no member accepts it', () {
      final schema = Ack.anyOf([Ack.string(), Ack.integer()]);

      final result = schema.safeParse(null);
      expect(
        result.isFail,
        isTrue,
        reason: 'Should fail when no member schema accepts null',
      );
    });

    test('should accept null when AnyOfSchema itself is nullable', () {
      final schema = Ack.anyOf([Ack.string(), Ack.integer()]).nullable();

      final result = schema.safeParse(null);
      expect(
        result.isOk,
        isTrue,
        reason: 'AnyOfSchema.nullable() should accept null',
      );
      expect(result.getOrNull(), isNull);
    });

    test(
      'should prefer member schema null acceptance over AnyOfSchema nullable',
      () {
        // When a member schema is nullable, it should match first
        final schema = Ack.anyOf([
          Ack.string().nullable(),
          Ack.integer(),
        ]).nullable(); // AnyOfSchema is also nullable

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);
        expect(result.getOrNull(), isNull);
      },
    );

    test('should work with multiple nullable member schemas', () {
      final schema = Ack.anyOf([
        Ack.string().nullable(),
        Ack.integer().nullable(),
        Ack.boolean(),
      ]);

      final result = schema.safeParse(null);
      expect(
        result.isOk,
        isTrue,
        reason: 'First nullable member should accept null',
      );
    });

    test('should try all schemas before checking AnyOfSchema nullable', () {
      // Even if AnyOfSchema is nullable, member schemas get priority
      final schema = Ack.anyOf([
        Ack.string().minLength(5),
        Ack.integer().min(10),
      ]).nullable();

      // String works
      expect(schema.safeParse('hello').isOk, isTrue);
      // Integer works
      expect(schema.safeParse(10).isOk, isTrue);
      // Null works (via AnyOfSchema nullable)
      expect(schema.safeParse(null).isOk, isTrue);
      // Invalid values still fail
      expect(schema.safeParse('hi').isFail, isTrue);
      expect(schema.safeParse(5).isFail, isTrue);
    });
  });
  // AnyOf defaults are supported; see AnyOf defaults group below.

  group('AnyOf Error Reporting', () {
    test('should collect errors from all member schemas', () {
      final schema = Ack.anyOf([
        Ack.string().minLength(10),
        Ack.integer().min(100),
      ]);

      final result = schema.safeParse(5);
      expect(result.isFail, isTrue);

      final error = result.getError();
      expect(error, isA<SchemaNestedError>());

      final nestedError = error as SchemaNestedError;
      expect(
        nestedError.errors.length,
        equals(2),
        reason: 'Should collect errors from all branches',
      );
    });

    // Default-related error tests are covered in AnyOf defaults group below.
  });

  group('AnyOf defaults', () {
    test('should apply anyOf default when input is null', () {
      const defaultValue = 'default string';
      final schema = Ack.anyOf([
        Ack.string(),
        Ack.integer(),
      ]).copyWith(defaultValue: defaultValue);

      final result = schema.safeParse(null);
      expect(result.isOk, isTrue);
      expect(result.getOrThrow(), equals(defaultValue));
    });

    test('should prefer default over nullable member schema', () {
      const defaultValue = 'default string';
      final schema = Ack.anyOf([
        Ack.string().nullable(),
        Ack.integer(),
      ]).copyWith(defaultValue: defaultValue);

      final result = schema.safeParse(null);
      expect(result.isOk, isTrue);
      expect(result.getOrThrow(), equals(defaultValue));
    });

    test('should fail when default is invalid for all member schemas', () {
      // Use a list as default - neither integer nor double accept lists
      const defaultValue = [1, 2, 3];
      final schema = Ack.anyOf([
        Ack.integer(),
        Ack.double(),
      ]).copyWith(defaultValue: defaultValue);

      final result = schema.safeParse(null);
      expect(result.isFail, isTrue);
      expect(result.getError(), isA<SchemaNestedError>());
    });
  });

  group('AnyOf Edge Cases', () {
    test('should handle empty schemas list gracefully', () {
      final schema = Ack.anyOf([]);

      final result = schema.safeParse('anything');
      expect(result.isFail, isTrue, reason: 'Empty anyOf should always fail');
    });

    test('should handle single schema in anyOf', () {
      final schema = Ack.anyOf([Ack.string().minLength(3)]);

      expect(schema.safeParse('hello').isOk, isTrue);
      expect(schema.safeParse('hi').isFail, isTrue);
    });

    test('should work with deeply nested anyOf', () {
      final schema = Ack.anyOf([
        Ack.anyOf([Ack.string(), Ack.integer()]),
        Ack.boolean(),
      ]);

      expect(schema.safeParse('text').isOk, isTrue);
      expect(schema.safeParse(42).isOk, isTrue);
      expect(schema.safeParse(true).isOk, isTrue);
      expect(schema.safeParse([]).isFail, isTrue);
    });

    test('should handle anyOf with optional member schemas', () {
      final schema = Ack.object({
        'value': Ack.anyOf([Ack.string().optional(), Ack.integer()]),
      });

      // Optional in anyOf is a bit unusual, but should work
      expect(schema.safeParse({'value': 'text'}).isOk, isTrue);
      expect(schema.safeParse({'value': 42}).isOk, isTrue);
    });
  });

  group('AnyOf JSON Schema Generation', () {
    test('should include null type when AnyOfSchema is nullable', () {
      final schema = Ack.anyOf([Ack.string(), Ack.integer()]).nullable();

      final jsonSchema = schema.toJsonSchema();
      expect(jsonSchema['anyOf'], isA<List>());

      final anyOfList = jsonSchema['anyOf'] as List;
      // Nullable anyOf wraps the base anyOf in another anyOf with null
      // Structure: anyOf: [ { anyOf: [string, integer] }, { type: 'null' } ]
      expect(anyOfList.length, equals(2)); // base anyOf + null
      expect(
        anyOfList[1],
        equals({'type': 'null'}),
        reason: 'Last element should be null type',
      );
      expect(anyOfList[0], isA<Map>());
      expect((anyOfList[0] as Map).containsKey('anyOf'), isTrue);
    });

    test('should not include null type when AnyOfSchema is not nullable', () {
      final schema = Ack.anyOf([Ack.string(), Ack.integer()]);

      final jsonSchema = schema.toJsonSchema();
      expect(jsonSchema['anyOf'], isA<List>());

      final anyOfList = jsonSchema['anyOf'] as List;
      expect(anyOfList.length, equals(2)); // string, integer only
    });
  });
}
