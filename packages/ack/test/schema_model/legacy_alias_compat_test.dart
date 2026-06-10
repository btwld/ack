// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package

import 'package:ack/ack.dart';
import 'package:test/test.dart';

String _variantName(AckSchemaModel model) {
  return switch (model) {
    AckRefSchemaModel() => 'ref',
    AckStringSchemaModel() => 'string',
    AckIntegerSchemaModel() => 'integer',
    AckNumberSchemaModel() => 'number',
    AckBooleanSchemaModel() => 'boolean',
    AckArraySchemaModel() => 'array',
    AckObjectSchemaModel() => 'object',
    AckNullSchemaModel() => 'null',
    AckAnyOfSchemaModel() => 'anyOf',
    AckOneOfSchemaModel() => 'oneOf',
    AckAllOfSchemaModel() => 'allOf',
  };
}

void main() {
  group('legacy schema model aliases', () {
    test('forward const constructors and type checks', () {
      const schema = AckObjectSchemaModel(
        properties: {'name': AckStringSchemaModel()},
        additionalProperties: AckAdditionalPropertiesSchema(
          AckStringSchemaModel(),
        ),
      );

      expect(schema, isA<ObjectSchemaModel>());
      expect(schema, isA<AckObjectSchemaModel>());
      expect(schema.additionalProperties, isA<AdditionalPropertiesSchema>());
      expect(schema.additionalProperties, isA<AckAdditionalPropertiesSchema>());
    });

    test('preserve type identity', () {
      expect(AckObjectSchemaModel, ObjectSchemaModel);
      expect(AckStringSchemaModel, StringSchemaModel);
      expect(AckSchemaModelWarning, SchemaModelWarning);
      expect(AckAdditionalPropertiesAllowed, AdditionalPropertiesAllowed);
    });

    test('preserve sealed exhaustiveness', () {
      expect(_variantName(const AckRefSchemaModel(refName: 'Node')), 'ref');
      expect(_variantName(const AckStringSchemaModel()), 'string');
      expect(_variantName(const AckIntegerSchemaModel()), 'integer');
      expect(_variantName(const AckNumberSchemaModel()), 'number');
      expect(_variantName(const AckBooleanSchemaModel()), 'boolean');
      expect(_variantName(const AckArraySchemaModel()), 'array');
      expect(_variantName(const AckObjectSchemaModel()), 'object');
      expect(_variantName(const AckNullSchemaModel()), 'null');
      expect(
        _variantName(
          const AckAnyOfSchemaModel(schemas: [AckStringSchemaModel()]),
        ),
        'anyOf',
      );
      expect(
        _variantName(
          const AckOneOfSchemaModel(schemas: [AckStringSchemaModel()]),
        ),
        'oneOf',
      );
      expect(
        _variantName(
          const AckAllOfSchemaModel(schemas: [AckStringSchemaModel()]),
        ),
        'allOf',
      );
    });
  });
}
