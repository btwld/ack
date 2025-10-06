import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Composite Schema Defaults', () {
    group('ObjectSchema defaults', () {
      test('should apply object default when input is null', () {
        final defaultObj = {'name': 'Guest', 'age': 0};
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer(),
        }).copyWith(defaultValue: defaultObj);

        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
        final value = result.getOrThrow();
        expect(value, equals(defaultObj));
      });

      test('should clone object defaults to prevent mutation', () {
        final defaultObj = {'name': 'Guest', 'age': 0};
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer(),
        }).copyWith(defaultValue: defaultObj);

        final result1 = schema.safeParse(null);
        final result2 = schema.safeParse(null);

        expect(result1.isOk, isTrue);
        expect(result2.isOk, isTrue);

        final value1 = result1.getOrThrow();
        final value2 = result2.getOrThrow();

        // Values should be equal but not identical
        expect(value1, equals(value2));
        expect(identical(value1, value2), isFalse);
      });

      test('should validate object default against schema', () {
        final defaultObj = {'name': 'Guest', 'age': 0};
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer(),
        }).copyWith(defaultValue: defaultObj);

        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
        final value = result.getOrThrow()!;
        expect(value['name'], equals('Guest'));
        expect(value['age'], equals(0));
      });

      test('should not apply default when input is provided', () {
        final defaultObj = {'name': 'Guest', 'age': 0};
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer(),
        }).copyWith(defaultValue: defaultObj);

        final result = schema.safeParse({'name': 'Alice', 'age': 30});

        expect(result.isOk, isTrue);
        final value = result.getOrThrow()!;
        expect(value['name'], equals('Alice'));
        expect(value['age'], equals(30));
      });

      test('should emit default in toJsonSchema', () {
        final defaultObj = {'name': 'Guest', 'age': 0};
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer(),
        }).copyWith(defaultValue: defaultObj);

        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['default'], equals(defaultObj));
      });

      test('should handle nested object defaults', () {
        final defaultObj = {
          'user': {
            'name': 'Guest',
            'settings': {'theme': 'dark'},
          },
        };
        final schema = Ack.object({
          'user': Ack.object({
            'name': Ack.string(),
            'settings': Ack.object({'theme': Ack.string()}),
          }),
        }).copyWith(defaultValue: defaultObj);

        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
        final value = result.getOrThrow();
        expect(value, equals(defaultObj));
      });
    });

    group('ListSchema defaults', () {
      test('should apply list default when input is null', () {
        final defaultList = ['a', 'b', 'c'];
        final schema = Ack.list(
          Ack.string(),
        ).copyWith(defaultValue: defaultList);

        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
        final value = result.getOrThrow();
        expect(value, equals(defaultList));
      });

      test('should clone list defaults to prevent mutation', () {
        final defaultList = ['a', 'b', 'c'];
        final schema = Ack.list(
          Ack.string(),
        ).copyWith(defaultValue: defaultList);

        final result1 = schema.safeParse(null);
        final result2 = schema.safeParse(null);

        expect(result1.isOk, isTrue);
        expect(result2.isOk, isTrue);

        final value1 = result1.getOrThrow();
        final value2 = result2.getOrThrow();

        // Values should be equal but not identical
        expect(value1, equals(value2));
        expect(identical(value1, value2), isFalse);
      });

      test('should validate list default items against item schema', () {
        final defaultList = [1, 2, 3];
        final schema = Ack.list(
          Ack.integer(),
        ).copyWith(defaultValue: defaultList);

        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
        final value = result.getOrThrow();
        expect(value, equals(defaultList));
      });

      test('should not apply default when input is provided', () {
        final defaultList = ['a', 'b', 'c'];
        final schema = Ack.list(
          Ack.string(),
        ).copyWith(defaultValue: defaultList);

        final result = schema.safeParse(['x', 'y', 'z']);

        expect(result.isOk, isTrue);
        final value = result.getOrThrow();
        expect(value, equals(['x', 'y', 'z']));
      });

      test('should emit default in toJsonSchema', () {
        final defaultList = ['a', 'b', 'c'];
        final schema = Ack.list(
          Ack.string(),
        ).copyWith(defaultValue: defaultList);

        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['default'], equals(defaultList));
      });

      test('should handle list of objects as default', () {
        final defaultList = [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ];
        final schema = Ack.list(
          Ack.object({'id': Ack.integer(), 'name': Ack.string()}),
        ).copyWith(defaultValue: defaultList);

        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
        final value = result.getOrThrow();
        expect(value, equals(defaultList));
      });
    });

    group('AnyOfSchema defaults', () {
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

      test('should validate default against member schemas', () {
        const defaultValue = 42;
        final schema = Ack.anyOf([
          Ack.integer(),
          Ack.string(),
        ]).copyWith(defaultValue: defaultValue);

        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals(defaultValue));
      });

      test('should clone anyOf defaults when mutable', () {
        final defaultValue = {'type': 'object'};
        final schema = Ack.anyOf([
          Ack.object({'type': Ack.string()}),
          Ack.string(),
        ]).copyWith(defaultValue: defaultValue);

        final result1 = schema.safeParse(null);
        final result2 = schema.safeParse(null);

        expect(result1.isOk, isTrue);
        expect(result2.isOk, isTrue);

        final value1 = result1.getOrThrow();
        final value2 = result2.getOrThrow();

        expect(value1, equals(value2));
        expect(identical(value1, value2), isFalse);
      });

      test('should not apply default when input is provided', () {
        const defaultValue = 'default';
        final schema = Ack.anyOf([
          Ack.integer(),
          Ack.string(),
        ]).copyWith(defaultValue: defaultValue);

        final result = schema.safeParse(100);

        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), equals(100));
      });

      test('should emit default in toJsonSchema', () {
        const defaultValue = 'default';
        final schema = Ack.anyOf([
          Ack.integer(),
          Ack.string(),
        ]).copyWith(defaultValue: defaultValue);

        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['default'], equals(defaultValue));
      });
    });

    group('DiscriminatedObjectSchema defaults', () {
      test('should apply discriminated default when input is null', () {
        final defaultValue = {'type': 'circle', 'radius': 5};
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'circle': Ack.object({
              'type': Ack.string(),
              'radius': Ack.integer(),
            }),
            'square': Ack.object({'type': Ack.string(), 'side': Ack.integer()}),
          },
        ).copyWith(defaultValue: defaultValue);

        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
        final value = result.getOrThrow()!;
        expect(value, equals(defaultValue));
      });

      test('should validate default through discriminator routing', () {
        final defaultValue = {'type': 'square', 'side': 10};
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'circle': Ack.object({
              'type': Ack.string(),
              'radius': Ack.integer(),
            }),
            'square': Ack.object({'type': Ack.string(), 'side': Ack.integer()}),
          },
        ).copyWith(defaultValue: defaultValue);

        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
        final value = result.getOrThrow()!;
        expect(value['type'], equals('square'));
        expect(value['side'], equals(10));
      });

      test('should clone discriminated defaults', () {
        final defaultValue = {'type': 'circle', 'radius': 5};
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'circle': Ack.object({
              'type': Ack.string(),
              'radius': Ack.integer(),
            }),
          },
        ).copyWith(defaultValue: defaultValue);

        final result1 = schema.safeParse(null);
        final result2 = schema.safeParse(null);

        expect(result1.isOk, isTrue);
        expect(result2.isOk, isTrue);

        final value1 = result1.getOrThrow()!;
        final value2 = result2.getOrThrow()!;

        expect(value1, equals(value2));
        expect(identical(value1, value2), isFalse);
      });

      test('should not apply default when input is provided', () {
        final defaultValue = {'type': 'circle', 'radius': 5};
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'circle': Ack.object({
              'type': Ack.string(),
              'radius': Ack.integer(),
            }),
            'square': Ack.object({'type': Ack.string(), 'side': Ack.integer()}),
          },
        ).copyWith(defaultValue: defaultValue);

        final result = schema.safeParse({'type': 'square', 'side': 20});

        expect(result.isOk, isTrue);
        final value = result.getOrThrow()!;
        expect(value['type'], equals('square'));
        expect(value['side'], equals(20));
      });

      test('should emit default in toJsonSchema', () {
        final defaultValue = {'type': 'circle', 'radius': 5};
        final schema = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'circle': Ack.object({
              'type': Ack.string(),
              'radius': Ack.integer(),
            }),
          },
        ).copyWith(defaultValue: defaultValue);

        final jsonSchema = schema.toJsonSchema();

        expect(jsonSchema['default'], equals(defaultValue));
      });
    });

    group('Complex scenarios', () {
      test('should handle list of objects with defaults', () {
        final defaultList = [
          {'name': 'Item 1', 'count': 1},
          {'name': 'Item 2', 'count': 2},
        ];
        final schema = Ack.list(
          Ack.object({'name': Ack.string(), 'count': Ack.integer()}),
        ).copyWith(defaultValue: defaultList);

        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
        final value = result.getOrThrow()!;
        expect(value.length, equals(2));
        expect(value[0]['name'], equals('Item 1'));
        expect(value[1]['count'], equals(2));
      });

      test('should handle object with list defaults', () {
        final defaultObj = {
          'tags': ['tag1', 'tag2'],
          'items': [1, 2, 3],
        };
        final schema = Ack.object({
          'tags': Ack.list(Ack.string()),
          'items': Ack.list(Ack.integer()),
        }).copyWith(defaultValue: defaultObj);

        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
        final value = result.getOrThrow()!;
        expect(value['tags'], equals(['tag1', 'tag2']));
        expect(value['items'], equals([1, 2, 3]));
      });

      test('should handle deeply nested defaults', () {
        final defaultObj = {
          'level1': {
            'level2': {
              'level3': {'value': 'deep'},
            },
          },
        };
        final schema = Ack.object({
          'level1': Ack.object({
            'level2': Ack.object({
              'level3': Ack.object({'value': Ack.string()}),
            }),
          }),
        }).copyWith(defaultValue: defaultObj);

        final result = schema.safeParse(null);

        expect(result.isOk, isTrue);
        final value = result.getOrThrow()!;
        expect(
          (((value['level1'] as Map)['level2'] as Map)['level3']
              as Map)['value'],
          equals('deep'),
        );
      });
    });
  });
}
