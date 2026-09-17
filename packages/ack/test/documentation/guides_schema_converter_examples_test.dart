import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Mirrors the documented exhaustive converter over ACK's typed model.
Object convertSchemaModel(AckSchemaModel schema) {
  return switch (schema) {
    AckStringSchemaModel() => 'string',
    AckIntegerSchemaModel() => 'integer',
    AckNumberSchemaModel() => 'number',
    AckBooleanSchemaModel() => 'boolean',
    AckObjectSchemaModel() => 'object',
    AckArraySchemaModel() => 'array',
    AckAnyOfSchemaModel() => 'anyOf',
    AckOneOfSchemaModel() => 'oneOf',
    AckAllOfSchemaModel() => 'allOf',
    AckNullSchemaModel() => 'null',
    AckRefSchemaModel() => 'ref',
  };
}

void main() {
  group('Docs converter imported-schema handling', () {
    late AckSchema<Object, Object> schema;
    late AckSchemaModel imported;

    setUp(() {
      schema = Ack.fromJsonSchema({'type': 'string', 'minLength': 1});
      imported = schema.toSchemaModel();
    });

    test('imported schemas use existing composition and reference models', () {
      expect(imported, isA<AckAllOfSchemaModel>());
      final allOf = imported as AckAllOfSchemaModel;
      expect(allOf.schemas.single, isA<AckRefSchemaModel>());
      expect(convertSchemaModel(imported), 'allOf');
    });

    test('JSON-map targets use the direct map export', () {
      final Map<String, Object?> emitted = schema.toJsonSchema();

      expect(emitted, isA<Map<String, Object?>>());
      expect(emitted, equals(imported.toJsonSchema()));
      expect(emitted, isNotEmpty);
    });
  });
}
