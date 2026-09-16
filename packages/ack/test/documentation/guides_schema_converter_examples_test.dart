import 'package:ack/ack.dart';
import 'package:test/test.dart';

/// Mirrors the documented converter-author choice for imported fragments:
/// emit the generic Draft-7 map, or reject when the target cannot represent
/// an untyped JSON Schema keyword bag.
Object convertImportedFragment(
  AckSchemaModel schema, {
  required bool emitJsonSchema,
}) {
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
    AckImportedSchemaModel() =>
      emitJsonSchema
          ? schema.toJsonSchema()
          : throw UnsupportedError(
              'Imported JSON Schema fragments are not supported by this target.',
            ),
  };
}

void main() {
  group('Docs converter imported-fragment handling', () {
    late AckSchemaModel imported;

    setUp(() {
      imported = importJsonSchema({
        'type': 'string',
        'minLength': 1,
      }).schema.toSchemaModel();
    });

    test('imported schemas surface as AckImportedSchemaModel', () {
      expect(imported, isA<AckImportedSchemaModel>());
    });

    test('JSON-map targets emit the generic Draft-7 fragment', () {
      final emitted = convertImportedFragment(imported, emitJsonSchema: true);

      expect(emitted, isA<Map<String, Object?>>());
      expect(emitted, equals(imported.toJsonSchema()));
      expect(imported.toJsonSchema(), isNotEmpty);
    });

    test('typed targets can reject imported fragments', () {
      expect(
        () => convertImportedFragment(imported, emitJsonSchema: false),
        throwsA(
          isA<UnsupportedError>().having(
            (error) => error.message,
            'message',
            contains('Imported JSON Schema fragments'),
          ),
        ),
      );
    });
  });
}
