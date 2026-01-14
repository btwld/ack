import 'package:ack/ack.dart';
import 'package:test/test.dart';

enum TestColor { red, green, blue }

void main() {
  group('Schema Equality', () {
    group('StringSchema', () {
      test('equal schemas are equal', () {
        final a = Ack.string().minLength(5).describe('test');
        final b = Ack.string().minLength(5).describe('test');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different constraints are not equal', () {
        final a = Ack.string().minLength(5);
        final b = Ack.string().minLength(10);
        expect(a, isNot(equals(b)));
      });

      test('different nullable are not equal', () {
        final a = Ack.string().nullable();
        final b = Ack.string();
        expect(a, isNot(equals(b)));
      });

      test('different strictParsing are not equal', () {
        final a = Ack.string().strictParsing();
        final b = Ack.string();
        expect(a, isNot(equals(b)));
      });

      test('copyWith preserves equality', () {
        final original = Ack.string().minLength(5).describe('test');
        final copy = original.copyWith();
        expect(original, equals(copy));
        expect(original.hashCode, equals(copy.hashCode));
      });
    });

    group('IntegerSchema', () {
      test('equal schemas are equal', () {
        final a = Ack.integer().min(0).max(100);
        final b = Ack.integer().min(0).max(100);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different constraints are not equal', () {
        final a = Ack.integer().min(0);
        final b = Ack.integer().min(10);
        expect(a, isNot(equals(b)));
      });
    });

    group('DoubleSchema', () {
      test('equal schemas are equal', () {
        final a = Ack.double().min(0.0).max(1.0);
        final b = Ack.double().min(0.0).max(1.0);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('BooleanSchema', () {
      test('equal schemas are equal', () {
        final a = Ack.boolean().describe('enabled');
        final b = Ack.boolean().describe('enabled');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('ListSchema', () {
      test('equal schemas are equal', () {
        final a = Ack.list(Ack.string());
        final b = Ack.list(Ack.string());
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different item schemas are not equal', () {
        final a = Ack.list(Ack.string());
        final b = Ack.list(Ack.integer());
        expect(a, isNot(equals(b)));
      });

      test('nested lists are equal', () {
        final a = Ack.list(Ack.list(Ack.string()));
        final b = Ack.list(Ack.list(Ack.string()));
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('with constraints are equal', () {
        final a = Ack.list(Ack.string()).minItems(1).maxItems(10);
        final b = Ack.list(Ack.string()).minItems(1).maxItems(10);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('ObjectSchema', () {
      test('equal schemas are equal', () {
        final a = Ack.object({'name': Ack.string(), 'age': Ack.integer()});
        final b = Ack.object({'name': Ack.string(), 'age': Ack.integer()});
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different properties are not equal', () {
        final a = Ack.object({'name': Ack.string()});
        final b = Ack.object({'title': Ack.string()});
        expect(a, isNot(equals(b)));
      });

      test('different additionalProperties are not equal', () {
        final a = Ack.object({'name': Ack.string()}, additionalProperties: true);
        final b =
            Ack.object({'name': Ack.string()}, additionalProperties: false);
        expect(a, isNot(equals(b)));
      });

      test('nested objects are equal', () {
        final a = Ack.object({
          'user': Ack.object({
            'name': Ack.string(),
            'address': Ack.object({'city': Ack.string()}),
          }),
        });
        final b = Ack.object({
          'user': Ack.object({
            'name': Ack.string(),
            'address': Ack.object({'city': Ack.string()}),
          }),
        });
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('AnyOfSchema', () {
      test('equal schemas are equal', () {
        final a = Ack.anyOf([Ack.string(), Ack.integer()]);
        final b = Ack.anyOf([Ack.string(), Ack.integer()]);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different order is not equal', () {
        final a = Ack.anyOf([Ack.string(), Ack.integer()]);
        final b = Ack.anyOf([Ack.integer(), Ack.string()]);
        expect(a, isNot(equals(b)));
      });
    });

    group('DiscriminatedObjectSchema', () {
      test('equal schemas are equal', () {
        final a = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'user': Ack.object({'name': Ack.string()}),
            'admin': Ack.object({'role': Ack.string()}),
          },
        );
        final b = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {
            'user': Ack.object({'name': Ack.string()}),
            'admin': Ack.object({'role': Ack.string()}),
          },
        );
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different discriminator keys are not equal', () {
        final a = Ack.discriminated(
          discriminatorKey: 'type',
          schemas: {'user': Ack.object({'name': Ack.string()})},
        );
        final b = Ack.discriminated(
          discriminatorKey: 'kind',
          schemas: {'user': Ack.object({'name': Ack.string()})},
        );
        expect(a, isNot(equals(b)));
      });
    });

    group('EnumSchema', () {
      test('equal schemas are equal', () {
        final a = Ack.enumValues(TestColor.values);
        final b = Ack.enumValues(TestColor.values);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('AnySchema', () {
      test('equal schemas are equal', () {
        final a = Ack.any().describe('anything');
        final b = Ack.any().describe('anything');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });
    });

    group('TransformedSchema', () {
      test('same transformer are equal', () {
        String transform(String? s) => s?.toUpperCase() ?? '';
        final a = Ack.string().transform(transform);
        final b = Ack.string().transform(transform);
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different transformers are not equal', () {
        final a = Ack.string().transform((s) => s?.toUpperCase() ?? '');
        final b = Ack.string().transform((s) => s?.toLowerCase() ?? '');
        expect(a, isNot(equals(b)));
      });
    });

    group('Cross-type inequality', () {
      test('different schema types are not equal', () {
        final stringSchema = Ack.string();
        final intSchema = Ack.integer();
        final boolSchema = Ack.boolean();

        expect(stringSchema, isNot(equals(intSchema)));
        expect(stringSchema, isNot(equals(boolSchema)));
        expect(intSchema, isNot(equals(boolSchema)));
      });
    });

    group('Set and Map operations', () {
      test('schemas work correctly in Set', () {
        final schema1 = Ack.string().minLength(5);
        final schema2 = Ack.string().minLength(5);
        final schema3 = Ack.string().minLength(10);

        final set = {schema1, schema2, schema3};
        expect(set.length, equals(2));
        expect(set.contains(schema1), isTrue);
        expect(set.contains(schema2), isTrue);
        expect(set.contains(schema3), isTrue);
      });

      test('schemas work correctly as Map keys', () {
        final schema1 = Ack.string().minLength(5);
        final schema2 = Ack.string().minLength(5);
        final schema3 = Ack.string().minLength(10);

        final map = <AckSchema, String>{
          schema1: 'first',
          schema2: 'second', // Should overwrite first
          schema3: 'third',
        };

        expect(map.length, equals(2));
        expect(map[schema1], equals('second'));
        expect(map[schema3], equals('third'));
      });
    });

    group('Refinements', () {
      test('same refinement function are equal', () {
        bool validate(String value) => value.isNotEmpty;
        final a = Ack.string().refine(validate, message: 'not empty');
        final b = Ack.string().refine(validate, message: 'not empty');
        expect(a, equals(b));
      });

      test('different refinement functions are not equal', () {
        final a = Ack.string().refine((v) => v.isNotEmpty, message: 'not empty');
        final b = Ack.string().refine((v) => v.length > 1, message: 'not empty');
        expect(a, isNot(equals(b)));
      });
    });

    group('Default values', () {
      test('same defaults are equal', () {
        final a = Ack.string().withDefault('hello');
        final b = Ack.string().withDefault('hello');
        expect(a, equals(b));
      });

      test('different defaults are not equal', () {
        final a = Ack.string().withDefault('hello');
        final b = Ack.string().withDefault('world');
        expect(a, isNot(equals(b)));
      });
    });
  });
}
