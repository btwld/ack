import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('AckSchemaModel.fromJsonSchema', () {
    test('parses typed scalar keywords', () {
      final string = AckSchemaModel.fromJsonSchema({
        'type': 'string',
        'format': 'email',
        'minLength': 3,
        'maxLength': 64,
        'pattern': r'.+@.+',
      });
      final integer = AckSchemaModel.fromJsonSchema({
        'type': 'integer',
        'minimum': 1,
        'maximum': 10,
        'multipleOf': 2,
      });
      final number = AckSchemaModel.fromJsonSchema({
        'type': 'number',
        'exclusiveMinimum': 0,
        'exclusiveMaximum': 1,
      });
      final boolean = AckSchemaModel.fromJsonSchema({
        'type': 'boolean',
        'const': true,
      });

      expect(string, isA<AckStringSchemaModel>());
      expect(integer, isA<AckIntegerSchemaModel>());
      expect(number, isA<AckNumberSchemaModel>());
      expect(boolean, isA<AckBooleanSchemaModel>());
      expect(string.toJsonSchema(), {
        'type': 'string',
        'format': 'email',
        'minLength': 3,
        'maxLength': 64,
        'pattern': r'.+@.+',
      });
      expect(integer.toJsonSchema(), {
        'type': 'integer',
        'minimum': 1,
        'maximum': 10,
        'multipleOf': 2,
      });
      expect(number.toJsonSchema(), {
        'type': 'number',
        'exclusiveMinimum': 0,
        'exclusiveMaximum': 1,
      });
      expect(boolean.toJsonSchema(), {'type': 'boolean', 'const': true});
    });

    test(
      'parses arrays, objects, required fields, and additional properties',
      () {
        final model = AckSchemaModel.fromJsonSchema({
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'tags': {
              'type': 'array',
              'items': {'type': 'integer'},
            },
          },
          'required': ['name'],
          'minProperties': 1,
          'additionalProperties': {'type': 'string'},
        });

        final object = model as AckObjectSchemaModel;
        expect(object.propertyOrdering, ['name', 'tags']);
        expect(object.properties!['name'], isA<AckStringSchemaModel>());
        expect(object.properties!['tags'], isA<AckArraySchemaModel>());
        expect(object.required, ['name']);
        expect(
          object.additionalProperties,
          isA<AckAdditionalPropertiesSchema>(),
        );
        expect(model.toJsonSchema(), {
          'type': 'object',
          'properties': {
            'name': {'type': 'string'},
            'tags': {
              'type': 'array',
              'items': {'type': 'integer'},
            },
          },
          'required': ['name'],
          'minProperties': 1,
          'additionalProperties': {'type': 'string'},
        });
      },
    );

    test('canonicalizes nullable anyOf wrappers back to nullable models', () {
      final json = {
        'description': 'nickname',
        'default': 'leo',
        'definitions': {
          'User': {'type': 'object'},
        },
        'anyOf': [
          {'type': 'string', 'minLength': 1},
          {'type': 'null'},
        ],
      };

      final model = AckSchemaModel.fromJsonSchema(json);

      expect(model, isA<AckStringSchemaModel>());
      expect(model.nullable, isTrue);
      expect(model.description, 'nickname');
      expect(model.defaultValue, 'leo');
      expect(model.extensions['definitions'], {
        'User': {'type': 'object'},
      });
      expect(model.toJsonSchema(), json);
    });

    test('parses refs in bare and metadata-wrapped forms', () {
      final bare = AckSchemaModel.fromJsonSchema({
        r'$ref': '#/definitions/Foo~0Bar~1Baz',
      });
      final wrapped = AckSchemaModel.fromJsonSchema({
        'title': 'Node',
        'allOf': [
          {r'$ref': '#/definitions/Node'},
        ],
      });

      expect((bare as AckRefSchemaModel).refName, 'Foo~Bar/Baz');
      expect(bare.toJsonSchema(), {r'$ref': '#/definitions/Foo~0Bar~1Baz'});
      expect((wrapped as AckRefSchemaModel).refName, 'Node');
      expect(wrapped.title, 'Node');
      expect(wrapped.toJsonSchema(), {
        'title': 'Node',
        'allOf': [
          {r'$ref': '#/definitions/Node'},
        ],
      });
    });

    test('warns instead of throwing for unsupported shapes', () {
      final unknown = AckSchemaModel.fromJsonSchema({'x-custom': true});
      final unsupportedRef = AckSchemaModel.fromJsonSchema({
        r'$ref': 'https://example.com/schema.json',
      });
      final typeList = AckSchemaModel.fromJsonSchema({
        'type': ['string', 'null'],
        'minLength': 1,
      });
      final booleanItems = AckSchemaModel.fromJsonSchema({
        'type': 'array',
        'items': true,
      });

      expect(unknown.warnings.single.code, 'unsupported_schema_shape');
      expect(unknown.extensions['x-custom'], isTrue);
      expect(unsupportedRef.warnings.single.code, 'unsupported_ref');
      expect(typeList.warnings.single.code, 'unsupported_type_array');
      expect(typeList.nullable, isTrue);
      expect(booleanItems.warnings.single.code, 'unsupported_items_schema');
      expect(booleanItems.toJsonSchema(), {'type': 'array'});
    });

    test('round-trips rendered JSON for model variants', () {
      final corpus = <AckSchemaModel>[
        const AckStringSchemaModel(
          format: 'email',
          minLength: 3,
          nullable: true,
          defaultValue: 'a@b.com',
        ),
        const AckIntegerSchemaModel(minimum: 1, maximum: 10),
        const AckNumberSchemaModel(multipleOf: 0.5),
        const AckBooleanSchemaModel(constValue: false),
        const AckArraySchemaModel(items: AckStringSchemaModel(minLength: 1)),
        const AckObjectSchemaModel(
          properties: {'name': AckStringSchemaModel()},
          required: ['name'],
          additionalProperties: AckAdditionalPropertiesSchema(
            AckIntegerSchemaModel(),
          ),
        ),
        const AckNullSchemaModel(title: 'Nothing'),
        const AckAnyOfSchemaModel(
          schemas: [AckStringSchemaModel(), AckIntegerSchemaModel()],
        ),
        const AckOneOfSchemaModel(
          schemas: [
            AckStringSchemaModel(constValue: 'x'),
            AckIntegerSchemaModel(),
          ],
          nullable: true,
        ),
        const AckAllOfSchemaModel(
          schemas: [
            AckStringSchemaModel(minLength: 2),
            AckStringSchemaModel(maxLength: 8),
          ],
        ),
        const AckRefSchemaModel(refName: 'Node'),
      ];

      for (final model in corpus) {
        final json = model.toJsonSchema();
        final parsed = AckSchemaModel.fromJsonSchema(json);

        expect(
          parsed.toJsonSchema(),
          json,
          reason: model.runtimeType.toString(),
        );
      }
    });
  });
}
