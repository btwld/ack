import 'package:ack/ack.dart';
import 'package:test/test.dart';

void main() {
  group('API Reference Documentation Examples', () {
    group('SchemaResult', () {
      test('Basic usage', () {
        final schema = Ack.string.minLength(3);
        final result = schema.validate('ab'); // Too short

        expect(result.isOk, isFalse);

        // Test getOrNull
        final value = result.getOrNull();
        expect(value, isNull);

        // Test getError
        final error = result.getError();
        expect(error, isA<SchemaError>());

        // Test getOrThrow
        expect(() => result.getOrThrow(), throwsA(isA<AckException>()));
      });
    });

    group('Schema Types', () {
      test('StringSchema', () {
        // Test minLength
        final minLengthSchema = Ack.string.minLength(3);
        expect(minLengthSchema.validate('abc').isOk, isTrue);
        expect(minLengthSchema.validate('ab').isOk, isFalse);

        // Test maxLength
        final maxLengthSchema = Ack.string.maxLength(5);
        expect(maxLengthSchema.validate('abcde').isOk, isTrue);
        expect(maxLengthSchema.validate('abcdef').isOk, isFalse);

        // Test notEmpty
        final notEmptySchema = Ack.string.notEmpty();
        expect(notEmptySchema.validate('a').isOk, isTrue);
        expect(notEmptySchema.validate('').isOk, isFalse);

        // Test email
        final emailSchema = Ack.string.email();
        expect(emailSchema.validate('user@example.com').isOk, isTrue);
        expect(emailSchema.validate('invalid-email').isOk, isFalse);
      });

      test('IntSchema', () {
        // Test min
        final minSchema = Ack.int.min(5);
        expect(minSchema.validate(5).isOk, isTrue);
        expect(minSchema.validate(4).isOk, isFalse);

        // Test max
        final maxSchema = Ack.int.max(10);
        expect(maxSchema.validate(10).isOk, isTrue);
        expect(maxSchema.validate(11).isOk, isFalse);
      });

      test('DoubleSchema', () {
        // Test min
        final minSchema = Ack.double.min(5.0);
        expect(minSchema.validate(5.0).isOk, isTrue);
        expect(minSchema.validate(4.9).isOk, isFalse);

        // Test max
        final maxSchema = Ack.double.max(10.0);
        expect(maxSchema.validate(10.0).isOk, isTrue);
        expect(maxSchema.validate(10.1).isOk, isFalse);
      });

      test('ListSchema', () {
        // Test minItems
        final minItemsSchema = Ack.list(Ack.string).minItems(2);
        expect(minItemsSchema.validate(['a', 'b']).isOk, isTrue);
        expect(minItemsSchema.validate(['a']).isOk, isFalse);

        // Test maxItems
        final maxItemsSchema = Ack.list(Ack.string).maxItems(3);
        expect(maxItemsSchema.validate(['a', 'b', 'c']).isOk, isTrue);
        expect(maxItemsSchema.validate(['a', 'b', 'c', 'd']).isOk, isFalse);

        // Test uniqueItems
        final uniqueItemsSchema = Ack.list(Ack.string).uniqueItems();
        expect(uniqueItemsSchema.validate(['a', 'b', 'c']).isOk, isTrue);
        expect(uniqueItemsSchema.validate(['a', 'b', 'a']).isOk, isFalse);
      });

      test('ObjectSchema', () {
        final userSchema = Ack.object({
          'name': Ack.string.minLength(2),
          'age': Ack.int.min(0),
        }, required: [
          'name'
        ]);

        // Test valid object
        expect(userSchema.validate({'name': 'John', 'age': 30}).isOk, isTrue);

        // Test missing required field
        expect(userSchema.validate({'age': 30}).isOk, isFalse);

        // Test invalid field
        expect(userSchema.validate({'name': 'J', 'age': 30}).isOk, isFalse);
      });
    });

    group('Common Methods', () {
      test('nullable', () {
        final schema = Ack.string.nullable();
        expect(schema.validate(null).isOk, isTrue);
        expect(schema.validate('value').isOk, isTrue);
      });

      test('strict', () {
        final schema = Ack.int.strict();
        expect(schema.validate(123).isOk, isTrue);
        expect(schema.validate('123').isOk, isFalse);
      });
    });

    group('Error Handling Methods', () {
      test('getOrElse', () {
        final schema = Ack.string.minLength(3);
        final result = schema.validate('ab'); // Invalid

        final value = result.getOrElse(() => 'default');
        expect(value, equals('default'));
      });
    });

    group('OpenAPI Integration', () {
      test('OpenApiSchemaConverter', () {
        final schema = Ack.object({
          'name': Ack.string.minLength(2).maxLength(50),
          'age': Ack.int.min(0).max(120),
        }, required: [
          'name'
        ]);

        final converter = JsonSchemaConverter(schema: schema);
        final openApiSchema = converter.toSchema();

        expect(openApiSchema, isA<Map<String, dynamic>>());
        expect(openApiSchema['type'], equals('object'));
        expect(openApiSchema['required'], contains('name'));
        expect(openApiSchema['properties'], isA<Map<String, dynamic>>());
        final properties = openApiSchema['properties'] as Map<String, dynamic>;
        expect(properties['name'], isA<Map<String, dynamic>>());
        expect(properties['age'], isA<Map<String, dynamic>>());
      });
    });
  });
}
