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
      final schema = Ack.anyOf([Ack.string(), Ack.integer()]).describe('choice');

      final json = schema.toJsonSchemaModel();

      expect(json.anyOf, isNotNull);
      expect(json.description, 'choice');
    });

    test('any() allows arrays of arrays (items left unconstrained)', () {
      final json = Ack.any().toJsonSchemaModel();

      final arrayBranch =
          json.anyOf!.firstWhere((s) => s.type == JsonSchemaType.array);
      expect(arrayBranch.items, isNull,
          reason: 'array branch should not constrain item types');
    });
  });
}
