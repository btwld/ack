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

      expect(model.toJsonSchema(), {
        'anyOf': [
          {'type': 'string', 'description': 'nickname'},
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
  });
}
