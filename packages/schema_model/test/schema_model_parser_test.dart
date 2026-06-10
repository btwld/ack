import 'package:schema_model/schema_model.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaModel.fromJsonSchema', () {
    test('parses typed scalar keywords', () {
      final string = SchemaModel.fromJsonSchema({
        'type': 'string',
        'format': 'email',
        'minLength': 3,
        'maxLength': 64,
        'pattern': r'.+@.+',
      });
      final integer = SchemaModel.fromJsonSchema({
        'type': 'integer',
        'minimum': 1,
        'maximum': 10,
        'multipleOf': 2,
      });
      final number = SchemaModel.fromJsonSchema({
        'type': 'number',
        'exclusiveMinimum': 0,
        'exclusiveMaximum': 1,
      });
      final boolean = SchemaModel.fromJsonSchema({
        'type': 'boolean',
        'const': true,
      });

      expect(string, isA<StringSchemaModel>());
      expect(integer, isA<IntegerSchemaModel>());
      expect(number, isA<NumberSchemaModel>());
      expect(boolean, isA<BooleanSchemaModel>());
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
        final model = SchemaModel.fromJsonSchema({
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

        final object = model as ObjectSchemaModel;
        expect(object.propertyOrdering, ['name', 'tags']);
        expect(object.properties!['name'], isA<StringSchemaModel>());
        expect(object.properties!['tags'], isA<ArraySchemaModel>());
        expect(object.required, ['name']);
        expect(object.additionalProperties, isA<AdditionalPropertiesSchema>());
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

      final model = SchemaModel.fromJsonSchema(json);

      expect(model, isA<StringSchemaModel>());
      expect(model.nullable, isTrue);
      expect(model.description, 'nickname');
      expect(model.defaultValue, 'leo');
      expect(model.extensions['definitions'], {
        'User': {'type': 'object'},
      });
      expect(model.toJsonSchema(), json);
    });

    test('parses refs in bare and metadata-wrapped forms', () {
      final bare = SchemaModel.fromJsonSchema({
        r'$ref': '#/definitions/Foo~0Bar~1Baz',
      });
      final wrapped = SchemaModel.fromJsonSchema({
        'title': 'Node',
        'allOf': [
          {r'$ref': '#/definitions/Node'},
        ],
      });

      expect((bare as RefSchemaModel).refName, 'Foo~Bar/Baz');
      expect(bare.toJsonSchema(), {r'$ref': '#/definitions/Foo~0Bar~1Baz'});
      expect((wrapped as RefSchemaModel).refName, 'Node');
      expect(wrapped.title, 'Node');
      expect(wrapped.toJsonSchema(), {
        'title': 'Node',
        'allOf': [
          {r'$ref': '#/definitions/Node'},
        ],
      });
    });

    test('warns instead of throwing for unsupported shapes', () {
      final unknown = SchemaModel.fromJsonSchema({'x-custom': true});
      final unsupportedRef = SchemaModel.fromJsonSchema({
        r'$ref': 'https://example.com/schema.json',
      });
      final typeList = SchemaModel.fromJsonSchema({
        'type': ['string', 'null'],
        'minLength': 1,
      });
      final booleanItems = SchemaModel.fromJsonSchema({
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
      final corpus = <SchemaModel>[
        const StringSchemaModel(
          format: 'email',
          minLength: 3,
          nullable: true,
          defaultValue: 'a@b.com',
        ),
        const IntegerSchemaModel(minimum: 1, maximum: 10),
        const NumberSchemaModel(multipleOf: 0.5),
        const BooleanSchemaModel(constValue: false),
        const ArraySchemaModel(items: StringSchemaModel(minLength: 1)),
        const ObjectSchemaModel(
          properties: {'name': StringSchemaModel()},
          required: ['name'],
          additionalProperties: AdditionalPropertiesSchema(
            IntegerSchemaModel(),
          ),
        ),
        const NullSchemaModel(title: 'Nothing'),
        const AnyOfSchemaModel(
          schemas: [StringSchemaModel(), IntegerSchemaModel()],
        ),
        const OneOfSchemaModel(
          schemas: [
            StringSchemaModel(constValue: 'x'),
            IntegerSchemaModel(),
          ],
          nullable: true,
        ),
        const AllOfSchemaModel(
          schemas: [
            StringSchemaModel(minLength: 2),
            StringSchemaModel(maxLength: 8),
          ],
        ),
        const RefSchemaModel(refName: 'Node'),
      ];

      for (final model in corpus) {
        final json = model.toJsonSchema();
        final parsed = SchemaModel.fromJsonSchema(json);

        expect(
          parsed.toJsonSchema(),
          json,
          reason: model.runtimeType.toString(),
        );
      }
    });
  });
}
