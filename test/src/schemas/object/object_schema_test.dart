import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../../../test_helpers.dart';

void main() {
  group('ObjectSchema', () {
    test('copyWith changes additionalProperties and required', () {
      final schema = ObjectSchema(
          {
            'age': IntegerSchema(),
          },
          additionalProperties: false,
          required: ['age']);
      final newSchema = schema.copyWith(additionalProperties: true);

      final result = newSchema.validate({'age': 30, 'extra': 'value'});
      expect(result.isOk, isTrue);
    });

    test('Non-nullable schema fails on null', () {
      final schema = ObjectSchema({
        'age': IntegerSchema(),
      });
      final result = schema.validate(null);
      expect(result.isFail, isTrue);
      expect(result, hasOneSchemaError('non_nullable_value'));
    });

    test('Nullable schema passes on null', () {
      final schema = ObjectSchema({
        'age': IntegerSchema(),
      }, nullable: true);
      final result = schema.validate(null);
      expect(result.isOk, isTrue);
    });

    test('Invalid type returns invalid type error', () {
      final schema = ObjectSchema({
        'age': IntegerSchema(),
      });
      final result = schema.validate('not a map');
      expect(result.isFail, isTrue);
      expect(result, hasOneSchemaError('invalid_type'));
    });

    test('Valid object passes with correct properties', () {
      final schema = ObjectSchema(
          {
            'age': IntegerSchema(),
          },
          additionalProperties: false,
          required: ['age']);
      final result = schema.validate({'age': 25});
      expect(result.isOk, isTrue);
    });

    test('extend merges properties correctly', () {
      final baseSchema = ObjectSchema({
        'age': IntegerSchema(),
      }, additionalProperties: false);

      final extendedSchema = baseSchema.extend(
          {
            'score': IntegerSchema(),
          },
          additionalProperties: false,
          required: ['score']);
      final result = extendedSchema.validate({'age': 30, 'score': 100});
      expect(result.isOk, isTrue);
    });
  });
  group('Nested Object Merge (without using validators)', () {
    test('should merge nested object schemas correctly', () {
      final baseSchema = ObjectSchema(
          {
            'user': ObjectSchema(
                {
                  'age': IntegerSchema(),
                },
                additionalProperties: false,
                required: ['age']),
            'settings': ObjectSchema(
                {
                  'theme': StringSchema(),
                },
                additionalProperties: false,
                required: ['theme']),
          },
          additionalProperties: false,
          required: ['user']);

      final extensionSchema = ObjectSchema(
          {
            'user': ObjectSchema(
              {
                'name': StringSchema(),
              },
              additionalProperties: true,
              required: ['name'],
            ),
            'settings': ObjectSchema(
              {
                'notifications': BooleanSchema(),
              },
              additionalProperties: true,
              required: ['notifications'],
            ),
            'extra': BooleanSchema()
          },
          additionalProperties: true,
          required: ['extra']);

      final mergedSchema = baseSchema.extend(
        extensionSchema.getProperties(),
        additionalProperties: extensionSchema.getAllowsAdditionalProperties(),
        required: extensionSchema.getRequiredProperties(),
        constraints: extensionSchema.getConstraints(),
      );

      // Verify merged schema properties
      final mergedProperties = mergedSchema.getProperties();
      expect(mergedProperties.length, equals(3)); // user, settings, extra

      final mergedUserSchema = mergedProperties['user'] as ObjectSchema;
      final mergedUserProperties = mergedUserSchema.getProperties();
      expect(mergedUserProperties.length, equals(2)); // age, name
      expect(mergedUserProperties['age'], isA<IntegerSchema>());
      expect(mergedUserProperties['name'], isA<StringSchema>());
      expect(mergedUserSchema.getAllowsAdditionalProperties(), isTrue);
      expect(mergedUserSchema.getRequiredProperties(),
          containsAll(['age', 'name']));

      final mergedSettingsSchema = mergedProperties['settings'] as ObjectSchema;
      final mergedSettingsProperties = mergedSettingsSchema.getProperties();
      expect(
          mergedSettingsProperties.length, equals(2)); // theme, notifications
      expect(mergedSettingsProperties['theme'], isA<StringSchema>());
      expect(mergedSettingsProperties['notifications'], isA<BooleanSchema>());
      expect(mergedSettingsSchema.getAllowsAdditionalProperties(), isTrue);
      expect(mergedSettingsSchema.getRequiredProperties(),
          containsAll(['theme', 'notifications']));

      expect(mergedProperties['extra'], isA<BooleanSchema>());
      expect(mergedSchema.getAllowsAdditionalProperties(), isTrue);
      expect(
          mergedSchema.getRequiredProperties(), containsAll(['user', 'extra']));

      final validObject = {
        'user': {
          'age': 30,
          'name': 'John',
          'nickname': 'Johnny',
        },
        'settings': {
          'theme': 'light',
          'notifications': false,
          'language': 'en',
        },
        'extra': true,
      };

      final validResult = mergedSchema.validate(validObject);
      expect(validResult.isOk, isTrue);

      final invalidObject = {
        'user': {
          'age': 30,
        },
        'settings': {
          'theme': 'light',
          'notifications': false,
        },
        'extra': true,
      };

      final invalidResult = mergedSchema.validate(invalidObject);
      expect(invalidResult.isFail, isTrue);
    });
  });
  group('Constructor validation', () {
    test(
        'throws ArgumentError when required properties are not in properties map',
        () {
      expect(
        () => ObjectSchema(
          {
            'name': StringSchema(),
          },
          required: ['name', 'age'],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Required properties must be present in the properties map [age]',
          ),
        ),
      );
    });

    test('throws ArgumentError when required properties are not unique', () {
      expect(
        () => ObjectSchema(
          {
            'name': StringSchema(),
            'age': IntegerSchema(),
          },
          required: ['name', 'name', 'age'],
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Required properties must be unique',
          ),
        ),
      );
    });

    test('constructs successfully with valid arguments', () {
      final schema = ObjectSchema(
        {
          'name': StringSchema(),
          'age': IntegerSchema(),
        },
        required: ['name', 'age'],
      );

      expect(schema, isA<ObjectSchema>());
      expect(schema.getRequiredProperties(), containsAll(['name', 'age']));
      expect(schema.getProperties(), hasLength(2));
    });
  });
}
