import 'package:ack/ack.dart';
import 'package:ack_json_schema_builder/ack_json_schema_builder.dart';
import 'package:test/test.dart';

void main() {
  group('toJsonSchemaBuilder()', () {
    group('Primitives', () {
      test('converts basic string schema', () {
        final schema = Ack.string();
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts string with minLength', () {
        final schema = Ack.string().minLength(5);
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts string with maxLength', () {
        final schema = Ack.string().maxLength(50);
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts string with description', () {
        final schema = Ack.string().describe('User name');
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts integer schema', () {
        final schema = Ack.integer();
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts integer with minimum', () {
        final schema = Ack.integer().min(0);
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts integer with maximum', () {
        final schema = Ack.integer().max(100);
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts double schema', () {
        final schema = Ack.double();
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts boolean schema', () {
        final schema = Ack.boolean();
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });
    });

    group('Objects', () {
      test('converts basic object schema', () {
        final schema = Ack.object({'name': Ack.string(), 'age': Ack.integer()});
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts object with optional fields', () {
        final schema = Ack.object({
          'name': Ack.string(),
          'age': Ack.integer().optional(),
        });
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts nested object schema', () {
        final schema = Ack.object({
          'user': Ack.object({'name': Ack.string()}),
        });
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });
    });

    group('Arrays', () {
      test('converts basic array schema', () {
        final schema = Ack.list(Ack.string());
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts array with minItems', () {
        final schema = Ack.list(Ack.string()).minLength(1);
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });

      test('converts array of objects', () {
        final schema = Ack.list(
          Ack.object({'id': Ack.integer(), 'name': Ack.string()}),
        );
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });
    });

    group('Enums', () {
      test('converts string enum schema', () {
        final schema = Ack.enumString(['red', 'green', 'blue']);
        final result = schema.toJsonSchemaBuilder();

        expect(result, isNotNull);
      });
    });

    group('Complex Scenarios', () {
      test('converts complete user schema', () {
        final schema = Ack.object({
          'id': Ack.string().minLength(1),
          'name': Ack.string().minLength(2).maxLength(50),
          'email': Ack.string().email(),
          'age': Ack.integer().min(0).max(120).optional(),
          'tags': Ack.list(Ack.string()).optional(),
        });

        final result = schema.toJsonSchemaBuilder();
        expect(result, isNotNull);
      });
    });
  });
}
