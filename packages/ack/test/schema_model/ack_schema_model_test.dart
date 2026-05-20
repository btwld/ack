import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('AckSchemaModel sealed variants', () {
    test('renders string constraints and const literals', () {
      const model = AckStringSchemaModel(
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
      const integer = AckIntegerSchemaModel(minimum: 1);
      const number = AckNumberSchemaModel(minimum: 1.5);

      expect(integer.toJsonSchema(), {'type': 'integer', 'minimum': 1});
      expect(number.toJsonSchema(), {'type': 'number', 'minimum': 1.5});
    });

    test('wraps nullable primitive schemas without nullable keyword', () {
      const model = AckStringSchemaModel(
        description: 'nickname',
        nullable: true,
      );

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
      const model = AckAnyOfSchemaModel(
        nullable: true,
        schemas: [AckStringSchemaModel(), AckNullSchemaModel()],
      );

      expect(model.toJsonSchema(), {
        'anyOf': [
          {'type': 'string'},
          {'type': 'null'},
        ],
      });
    });

    test('renders object additional properties as one typed policy', () {
      const model = AckObjectSchemaModel(
        properties: {'name': AckStringSchemaModel()},
        required: ['name'],
        additionalProperties: AckAdditionalPropertiesDisallowed(),
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

    test('renders allOf directly for adapter tests', () {
      const model = AckAllOfSchemaModel(
        schemas: [
          AckStringSchemaModel(minLength: 2),
          AckStringSchemaModel(maxLength: 8),
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
      const left = AckStringSchemaModel(
        warnings: [
          AckSchemaModelWarning(
            code: 'test_warning',
            message: 'A test warning.',
            context: {'path': 'left'},
          ),
        ],
      );
      const right = AckStringSchemaModel(
        warnings: [
          AckSchemaModelWarning(
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
      const left = AckAnyOfSchemaModel(
        schemas: [AckStringSchemaModel()],
        discriminator: AckSchemaDiscriminatorModel(propertyName: 'type'),
      );
      const same = AckAnyOfSchemaModel(
        schemas: [AckStringSchemaModel()],
        discriminator: AckSchemaDiscriminatorModel(propertyName: 'type'),
      );
      const different = AckAnyOfSchemaModel(
        schemas: [AckStringSchemaModel()],
        discriminator: AckSchemaDiscriminatorModel(propertyName: 'kind'),
      );

      expect(left.toJsonSchema(), same.toJsonSchema());
      expect(left.toJsonSchema(), different.toJsonSchema());
      expect(left, same);
      expect(left.hashCode, same.hashCode);
      expect(left, isNot(different));

      const ordered = AckObjectSchemaModel(
        properties: {'name': AckStringSchemaModel()},
        propertyOrdering: ['name'],
      );
      const unordered = AckObjectSchemaModel(
        properties: {'name': AckStringSchemaModel()},
      );

      expect(ordered.toJsonSchema(), unordered.toJsonSchema());
      expect(ordered, isNot(unordered));

      const dateBounded = AckStringSchemaModel(
        format: 'date',
        formatMinimum: '2026-01-01',
      );
      const dateUnbounded = AckStringSchemaModel(format: 'date');

      expect(dateBounded.toJsonSchema(), dateUnbounded.toJsonSchema());
      expect(dateBounded, isNot(dateUnbounded));
    });
  });
}
