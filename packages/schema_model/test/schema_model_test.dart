import 'package:schema_model/schema_model.dart';
import 'package:test/test.dart';

void main() {
  group('SchemaModel sealed variants', () {
    test('renders string constraints and const literals', () {
      const model = StringSchemaModel(
        constValue: 'cat',
        minLength: 3,
        maxLength: 12,
        pattern: r'^[a-z]+$',
      );

      expect(model.toJsonSchema(), {
        'type': 'string',
        'const': 'cat',
        'minLength': 3,
        'maxLength': 12,
        'pattern': r'^[a-z]+$',
      });
    });

    test('keeps number and integer as distinct variants', () {
      const integer = IntegerSchemaModel(minimum: 1);
      const number = NumberSchemaModel(minimum: 1.5);

      expect(integer.toJsonSchema(), {'type': 'integer', 'minimum': 1});
      expect(number.toJsonSchema(), {'type': 'number', 'minimum': 1.5});
    });

    test('wraps nullable primitive schemas without nullable keyword', () {
      const model = StringSchemaModel(description: 'nickname', nullable: true);

      // Description is hoisted to the top level so generic JSON Schema
      // consumers can discover it without descending into anyOf branches.
      expect(model.toJsonSchema(), {
        'description': 'nickname',
        'anyOf': [
          {'type': 'string'},
          {'type': 'null'},
        ],
      });
    });

    test('composition nullable adds one null branch', () {
      const model = AnyOfSchemaModel(
        nullable: true,
        schemas: [StringSchemaModel(), NullSchemaModel()],
      );

      expect(model.toJsonSchema(), {
        'anyOf': [
          {'type': 'string'},
          {'type': 'null'},
        ],
      });
    });

    test('renders object additional properties as one typed policy', () {
      const model = ObjectSchemaModel(
        properties: {'name': StringSchemaModel()},
        required: ['name'],
        additionalProperties: AdditionalPropertiesDisallowed(),
      );

      expect(model.toJsonSchema(), {
        'type': 'object',
        'properties': {
          'name': {'type': 'string'},
        },
        'required': ['name'],
        'additionalProperties': false,
      });
    });

    test(
      'renders explicit object required fields even with property default',
      () {
        const model = ObjectSchemaModel(
          properties: {'name': StringSchemaModel(defaultValue: 'guest')},
          required: ['name'],
        );

        expect(model.toJsonSchema(), {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'default': 'guest'},
          },
          'required': ['name'],
        });
      },
    );

    test('renders allOf directly for adapter tests', () {
      const model = AllOfSchemaModel(
        schemas: [
          StringSchemaModel(minLength: 2),
          StringSchemaModel(maxLength: 8),
        ],
      );

      expect(model.toJsonSchema(), {
        'allOf': [
          {'type': 'string', 'minLength': 2},
          {'type': 'string', 'maxLength': 8},
        ],
      });
    });

    test('uses structural warnings in equality and hashCode', () {
      const left = StringSchemaModel(
        warnings: [
          SchemaModelWarning(
            code: 'test_warning',
            message: 'A test warning.',
            context: {'path': 'left'},
          ),
        ],
      );
      const right = StringSchemaModel(
        warnings: [
          SchemaModelWarning(
            code: 'test_warning',
            message: 'A test warning.',
            context: {'path': 'left'},
          ),
        ],
      );

      expect(left, right);
      expect(left.hashCode, right.hashCode);
    });

    test('uses non-rendered metadata in equality and hashCode', () {
      const left = AnyOfSchemaModel(
        schemas: [StringSchemaModel()],
        discriminator: SchemaDiscriminatorModel(propertyName: 'type'),
      );
      const same = AnyOfSchemaModel(
        schemas: [StringSchemaModel()],
        discriminator: SchemaDiscriminatorModel(propertyName: 'type'),
      );
      const different = AnyOfSchemaModel(
        schemas: [StringSchemaModel()],
        discriminator: SchemaDiscriminatorModel(propertyName: 'kind'),
      );

      expect(left.toJsonSchema(), same.toJsonSchema());
      expect(left.toJsonSchema(), different.toJsonSchema());
      expect(left, same);
      expect(left.hashCode, same.hashCode);
      expect(left, isNot(different));

      const ordered = ObjectSchemaModel(
        properties: {'name': StringSchemaModel()},
        propertyOrdering: ['name'],
      );
      const unordered = ObjectSchemaModel(
        properties: {'name': StringSchemaModel()},
      );

      expect(ordered.toJsonSchema(), unordered.toJsonSchema());
      expect(ordered, isNot(unordered));

      const dateBounded = StringSchemaModel(
        format: 'date',
        formatMinimum: '2026-01-01',
      );
      const dateUnbounded = StringSchemaModel(format: 'date');

      expect(dateBounded.toJsonSchema(), dateUnbounded.toJsonSchema());
      expect(dateBounded, isNot(dateUnbounded));
    });
  });
}
