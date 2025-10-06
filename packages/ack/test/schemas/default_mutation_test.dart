import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Default Value Mutation Safety', () {
    group('Map defaults', () {
      test('should clone map defaults to prevent mutation', () {
        final originalDefault = {'name': 'Guest', 'role': 'user'};
        final schema = Ack.any().copyWith(defaultValue: originalDefault);

        // Parse twice with null input to get defaults
        final result1 = schema.safeParse(null);
        final result2 = schema.safeParse(null);

        expect(result1.isOk, isTrue);
        expect(result2.isOk, isTrue);

        final value1 = result1.getOrThrow() as Map<String, Object?>;
        final value2 = result2.getOrThrow() as Map<String, Object?>;

        // Values should be equal but not identical instances
        expect(value1, equals(value2));
        expect(
          identical(value1, value2),
          isFalse,
          reason: 'Each parse should return a separate cloned instance',
        );

        // Original default should not be affected
        expect(originalDefault, equals({'name': 'Guest', 'role': 'user'}));
      });

      test('should deeply clone nested map defaults', () {
        final originalDefault = {
          'user': {
            'name': 'Guest',
            'settings': {'theme': 'dark', 'notifications': true},
          },
        };
        final schema = Ack.any().copyWith(defaultValue: originalDefault);

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);

        final value = result.getOrThrow() as Map<String, Object?>;
        final user = value['user'] as Map<String, Object?>;
        final settings = user['settings'] as Map<String, Object?>;

        // Verify deep clone by checking nested maps are separate instances
        expect(value, equals(originalDefault));
        expect(identical(value, originalDefault), isFalse);
        expect(
          identical(user, (originalDefault['user'] as Map<String, Object?>)),
          isFalse,
        );
        expect(
          identical(
            settings,
            ((originalDefault['user'] as Map<String, Object?>)['settings']),
          ),
          isFalse,
        );
      });

      test('should return unmodifiable map', () {
        final originalDefault = {'name': 'Guest'};
        final schema = Ack.any().copyWith(defaultValue: originalDefault);

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);

        final value = result.getOrThrow() as Map<String, Object?>;

        // Attempting to modify should throw
        expect(() => value['name'] = 'Modified', throwsUnsupportedError);
        expect(() => value['new'] = 'field', throwsUnsupportedError);
        expect(() => value.clear(), throwsUnsupportedError);
      });
    });

    group('List defaults', () {
      test('should clone list defaults to prevent mutation', () {
        final originalDefault = ['item1', 'item2', 'item3'];
        final schema = Ack.any().copyWith(defaultValue: originalDefault);

        // Parse twice with null input to get defaults
        final result1 = schema.safeParse(null);
        final result2 = schema.safeParse(null);

        expect(result1.isOk, isTrue);
        expect(result2.isOk, isTrue);

        final value1 = result1.getOrThrow() as List<Object?>;
        final value2 = result2.getOrThrow() as List<Object?>;

        // Values should be equal but not identical instances
        expect(value1, equals(value2));
        expect(
          identical(value1, value2),
          isFalse,
          reason: 'Each parse should return a separate cloned instance',
        );

        // Original default should not be affected
        expect(originalDefault, equals(['item1', 'item2', 'item3']));
      });

      test('should deeply clone nested list defaults', () {
        final originalDefault = [
          'simple',
          ['nested', 'list'],
          {
            'nested': ['deeply', 'nested', 'items'],
          },
        ];
        final schema = Ack.any().copyWith(defaultValue: originalDefault);

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);

        final value = result.getOrThrow() as List<Object?>;

        // Verify deep clone by checking nested structures are separate instances
        expect(value, equals(originalDefault));
        expect(identical(value, originalDefault), isFalse);
        expect(identical(value[1], originalDefault[1]), isFalse);
        expect(identical(value[2], originalDefault[2]), isFalse);
      });

      test('should return unmodifiable list', () {
        final originalDefault = ['item1', 'item2'];
        final schema = Ack.any().copyWith(defaultValue: originalDefault);

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);

        final value = result.getOrThrow() as List<Object?>;

        // Attempting to modify should throw
        expect(() => value[0] = 'modified', throwsUnsupportedError);
        expect(() => value.add('new'), throwsUnsupportedError);
        expect(() => value.clear(), throwsUnsupportedError);
      });
    });

    group('Primitive defaults', () {
      test('string defaults are immutable by nature', () {
        const originalDefault = 'default value';
        final schema = Ack.string().copyWith(defaultValue: originalDefault);

        final result1 = schema.safeParse(null);
        final result2 = schema.safeParse(null);

        expect(result1.isOk, isTrue);
        expect(result2.isOk, isTrue);

        final value1 = result1.getOrThrow();
        final value2 = result2.getOrThrow();

        // Strings are immutable, so same instance is fine
        expect(value1, equals(originalDefault));
        expect(value2, equals(originalDefault));
        expect(
          identical(value1, value2),
          isTrue,
          reason: 'Strings are immutable, same instance is safe',
        );
      });

      test('number defaults are immutable by nature', () {
        const originalDefault = 42;
        final schema = Ack.integer().copyWith(defaultValue: originalDefault);

        final result1 = schema.safeParse(null);
        final result2 = schema.safeParse(null);

        expect(result1.isOk, isTrue);
        expect(result2.isOk, isTrue);

        final value1 = result1.getOrThrow();
        final value2 = result2.getOrThrow();

        expect(value1, equals(originalDefault));
        expect(value2, equals(originalDefault));
      });

      test('boolean defaults are immutable by nature', () {
        const originalDefault = true;
        final schema = Ack.boolean().copyWith(defaultValue: originalDefault);

        final result1 = schema.safeParse(null);
        final result2 = schema.safeParse(null);

        expect(result1.isOk, isTrue);
        expect(result2.isOk, isTrue);

        final value1 = result1.getOrThrow();
        final value2 = result2.getOrThrow();

        expect(value1, equals(originalDefault));
        expect(value2, equals(originalDefault));
      });
    });

    group('Mixed nested defaults', () {
      test('should handle map containing lists', () {
        final originalDefault = {
          'tags': ['tag1', 'tag2'],
          'counts': [1, 2, 3],
        };
        final schema = Ack.any().copyWith(defaultValue: originalDefault);

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);

        final value = result.getOrThrow() as Map<String, Object?>;
        final tags = value['tags'] as List<Object?>;

        // Should be unmodifiable at all levels
        expect(() => value['tags'] = ['new'], throwsUnsupportedError);
        expect(() => tags[0] = 'modified', throwsUnsupportedError);
        expect(() => tags.add('new'), throwsUnsupportedError);
      });

      test('should handle list containing maps', () {
        final originalDefault = [
          {'id': 1, 'name': 'first'},
          {'id': 2, 'name': 'second'},
        ];
        final schema = Ack.any().copyWith(defaultValue: originalDefault);

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);

        final value = result.getOrThrow() as List<Object?>;
        final firstItem = value[0] as Map<String, Object?>;

        // Should be unmodifiable at all levels
        expect(() => value[0] = {}, throwsUnsupportedError);
        expect(() => value.add({}), throwsUnsupportedError);
        expect(() => firstItem['id'] = 999, throwsUnsupportedError);
        expect(() => firstItem['new'] = 'field', throwsUnsupportedError);
      });
    });

    group('Edge cases', () {
      test('should handle null default value', () {
        final schema = Ack.any().nullable().copyWith(defaultValue: null);

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);
        expect(result.getOrThrow(), isNull);
      });

      test('should handle empty map default', () {
        final originalDefault = <String, Object?>{};
        final schema = Ack.any().copyWith(defaultValue: originalDefault);

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);

        final value = result.getOrThrow() as Map<String, Object?>;
        expect(value.isEmpty, isTrue);
        expect(() => value['new'] = 'field', throwsUnsupportedError);
      });

      test('should handle empty list default', () {
        final originalDefault = <Object?>[];
        final schema = Ack.any().copyWith(defaultValue: originalDefault);

        final result = schema.safeParse(null);
        expect(result.isOk, isTrue);

        final value = result.getOrThrow() as List<Object?>;
        expect(value.isEmpty, isTrue);
        expect(() => value.add('item'), throwsUnsupportedError);
      });
    });
  });
}
