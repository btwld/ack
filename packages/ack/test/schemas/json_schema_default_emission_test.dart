import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('JSON Schema Default Emission Policy', () {
    test('Primitive schemas should emit default when set', () {
      // String
      final stringWithDefault = Ack.string().withDefault('default');
      final stringJsonSchema = stringWithDefault.toJsonSchema();
      expect(stringJsonSchema['default'], equals('default'));

      // Integer
      final intWithDefault = Ack.integer().withDefault(42);
      expect(intWithDefault.toJsonSchema()['default'], equals(42));

      // Double
      final doubleWithDefault = Ack.double().withDefault(3.14);
      expect(doubleWithDefault.toJsonSchema()['default'], equals(3.14));

      // Boolean
      final boolWithDefault = Ack.boolean().withDefault(true);
      expect(boolWithDefault.toJsonSchema()['default'], equals(true));
    });

    test('AnySchema should emit default when set (special case)', () {
      // AnySchema is unique - it accepts defaults unlike other composites
      final anyWithDefault = Ack.any().withDefault('fallback');
      final jsonSchema = anyWithDefault.toJsonSchema();
      expect(jsonSchema['default'], equals('fallback'));
    });

    test('Composite schemas should never emit top-level default', () {
      // ObjectSchema
      final obj = Ack.object({'key': Ack.string()});
      final objJsonSchema = obj.toJsonSchema();
      expect(
        objJsonSchema.containsKey('default'),
        isFalse,
        reason: 'ObjectSchema should not emit default',
      );

      // ListSchema
      final list = Ack.list(Ack.string());
      final listJsonSchema = list.toJsonSchema();
      expect(
        listJsonSchema.containsKey('default'),
        isFalse,
        reason: 'ListSchema should not emit default',
      );

      // AnyOfSchema
      final anyOf = Ack.anyOf([Ack.string(), Ack.integer()]);
      final anyOfJsonSchema = anyOf.toJsonSchema();
      expect(
        anyOfJsonSchema.containsKey('default'),
        isFalse,
        reason: 'AnyOfSchema should not emit default',
      );

      // DiscriminatedObjectSchema
      final disc = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'a': Ack.object({'type': Ack.string()}),
        },
      );
      final discJsonSchema = disc.toJsonSchema();
      expect(
        discJsonSchema.containsKey('default'),
        isFalse,
        reason: 'DiscriminatedObjectSchema should not emit default',
      );
    });

    test('Optional schemas should proxy defaults to wrapped schema', () {
      // Optional flag should behave transparently and reuse the base schema JSON
      final optionalWithDefault = Ack.string().optional().withDefault('x');
      final jsonSchema = optionalWithDefault.toJsonSchema();

      // Optional flag delegates to wrapped schema's toJsonSchema
      expect(
        jsonSchema['default'],
        equals('x'),
        reason: 'Optional field should proxy default from wrapped schema',
      );
      expect(jsonSchema['type'], equals('string'));
    });

    test(
      'Defaults in object properties (via Optional) should emit correctly',
      () {
        final schema = Ack.object({
          'required': Ack.string(),
          'withDefault': Ack.string().optional().withDefault('default_value'),
        });

        final jsonSchema = schema.toJsonSchema();

        // Top-level object should not have default
        expect(
          jsonSchema.containsKey('default'),
          isFalse,
          reason: 'ObjectSchema itself should not emit default',
        );

        // Property with default should emit it in its subschema
        final properties = jsonSchema['properties'] as Map;
        final withDefaultProp = properties['withDefault'] as Map;
        expect(
          withDefaultProp['default'],
          equals('default_value'),
          reason: 'Optional property with default should emit default',
        );

        // Required field should be in required array
        final required = jsonSchema['required'] as List;
        expect(required, contains('required'));
        expect(
          required,
          isNot(contains('withDefault')),
          reason: 'Optional field should not be in required array',
        );
      },
    );

    test('Nested composites should not emit defaults at any level', () {
      // Nested list in object
      final nestedSchema = Ack.object({
        'users': Ack.list(Ack.object({'name': Ack.string()})),
      });

      final jsonSchema = nestedSchema.toJsonSchema();

      // Top-level object: no default
      expect(jsonSchema.containsKey('default'), isFalse);

      // List property: no default
      final properties = jsonSchema['properties'] as Map;
      final usersList = properties['users'] as Map;
      expect(
        usersList.containsKey('default'),
        isFalse,
        reason: 'Nested ListSchema should not emit default',
      );

      // Nested object in items: no default
      final items = usersList['items'] as Map;
      expect(
        items.containsKey('default'),
        isFalse,
        reason: 'Nested ObjectSchema should not emit default',
      );
    });
  });
}
