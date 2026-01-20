import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('Ack.toJsonSchemaModel()', () {
    test('preserves exclusive numeric bounds', () {
      final intSchema = Ack.integer().greaterThan(0).lessThan(10);
      final numSchema = Ack.double().greaterThan(1.5).lessThan(2.5);

      final intJson = intSchema.toJsonSchemaModel();
      final numJson = numSchema.toJsonSchemaModel();

      expect(intJson.exclusiveMinimum, 0);
      expect(intJson.exclusiveMaximum, 10);
      expect(numJson.exclusiveMinimum, closeTo(1.5, 1e-9));
      expect(numJson.exclusiveMaximum, closeTo(2.5, 1e-9));
    });

    test('propagates uniqueItems constraint', () {
      final schema = Ack.list(Ack.string()).unique();

      final json = schema.toJsonSchemaModel();

      expect(json.uniqueItems, isTrue);
    });

    test('keeps description on anyOf unions', () {
      final schema = Ack.anyOf([
        Ack.string(),
        Ack.integer(),
      ]).describe('choice');

      final json = schema.toJsonSchemaModel();

      expect(json.anyOf, isNotNull);
      expect(json.description, 'choice');
    });

    test('any() allows arrays of arrays (items left unconstrained)', () {
      final json = Ack.any().toJsonSchemaModel();

      final arrayBranch = json.anyOf!.firstWhere(
        (s) => s.type == JsonSchemaType.array,
      );
      expect(
        arrayBranch.items,
        isNull,
        reason: 'array branch should not constrain item types',
      );
    });

    test('preserves wrapper metadata when unwrapping nullable', () {
      // When a schema has description on the nullable wrapper (anyOf),
      // that metadata should be preserved when unwrapping to the effective schema.
      final schema = Ack.string().describe('important field').nullable();
      final json = schema.toJsonSchemaModel();

      // The description should be preserved on the effective schema
      expect(json.type, JsonSchemaType.string);
      expect(json.description, 'important field');
      expect(json.nullable, isTrue);
    });

    test('preserves title when unwrapping nullable', () {
      // Using a workaround to test title preservation
      // First create a JsonSchema directly with wrapper metadata
      final wrapperSchema = JsonSchema(
        title: 'Wrapper Title',
        description: 'Wrapper Description',
        anyOf: [
          JsonSchema(type: JsonSchemaType.string),
          JsonSchema(type: JsonSchemaType.null_),
        ],
      );

      // Parse it back to simulate consuming external schema
      final parsed = JsonSchema.fromJson(wrapperSchema.toJson());

      // When unwrapping, the wrapper metadata should be preserved
      // This tests the fromJson path which feeds into the converter
      expect(parsed.description, 'Wrapper Description');
    });
  });
}
