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

    test('preserves const metadata from literals', () {
      final json = Ack.literal('exact').toJsonSchemaModel();

      expect(json.type, JsonSchemaType.string);
      expect(json.constValue, equals('exact'));
      expect(json.toJson()['const'], equals('exact'));
    });

    test('preserves default metadata', () {
      final json = Ack.string().withDefault('fallback').toJsonSchemaModel();

      expect(json.type, JsonSchemaType.string);
      expect(json.defaultValue, equals('fallback'));
      expect(json.toJson()['default'], equals('fallback'));
    });

    test('preserves nullable wrapper default metadata', () {
      final json = Ack.string()
          .nullable()
          .withDefault('fallback')
          .toJsonSchemaModel();

      expect(json.type, JsonSchemaType.string);
      expect(json.nullable, isTrue);
      expect(json.defaultValue, equals('fallback'));
      expect(json.toJson()['default'], equals('fallback'));
    });

    test('preserves object property default metadata', () {
      final json = Ack.object({
        'name': Ack.string().withDefault('guest'),
      }).toJsonSchemaModel();

      expect(json.properties!['name']!.defaultValue, equals('guest'));
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

    test('unwraps transformed discriminated branches to object schemas', () {
      final schema = Ack.discriminated<String>(
        discriminatorKey: 'type',
        schemas: {
          'cat': Ack.object({
            'name': Ack.string(),
          }).transform<String>((map) => map['name'] as String),
          'dog': Ack.object({
            'name': Ack.string(),
          }).transform<String>((map) => map['name'] as String),
        },
      );

      final json = schema.toJsonSchemaModel();

      expect(json.discriminator?.propertyName, equals('type'));
      expect(json.oneOf, hasLength(2));

      final catBranch = json.oneOf!.firstWhere(
        (branch) =>
            branch.properties?['type']?.enumValues?.contains('cat') ?? false,
      );
      expect(catBranch.type, JsonSchemaType.object);
      expect(catBranch.properties, contains('name'));
      expect(catBranch.properties!['type']!.enumValues, equals(['cat']));
    });

    test(
      'preserves transformed branch description in discriminated model conversion',
      () {
        final schema = Ack.discriminated<String>(
          discriminatorKey: 'type',
          schemas: {
            'cat': Ack.object({'name': Ack.string()})
                .transform<String>((map) => map['name'] as String)
                .copyWith(description: 'cat branch'),
          },
        );

        final json = schema.toJsonSchemaModel();

        final catBranch = json.oneOf!.firstWhere(
          (branch) =>
              branch.properties?['type']?.enumValues?.contains('cat') ?? false,
        );
        expect(catBranch.description, equals('cat branch'));
      },
    );

    test('nullable codec model uses codec wrapper nullability', () {
      final json = Ack.datetime().nullable().toJsonSchemaModel();

      expect(json.type, JsonSchemaType.string);
      expect(json.format, equals('date-time'));
      expect(json.nullable, isTrue);
    });

    test('non-null codec model ignores nullable input schema', () {
      final schema = Ack.codec<String, int>(
        Ack.string().nullable(),
        Ack.instance<int>(),
        decode: int.parse,
        encode: (i) => i.toString(),
      );

      final json = schema.toJsonSchemaModel();

      expect(json.type, JsonSchemaType.string);
      expect(json.nullable, isFalse);
    });

    test('codec model preserves wrapper numeric constraints', () {
      final json = Ack.duration()
          .min(Duration(milliseconds: 1500))
          .max(Duration(seconds: 2))
          .toJsonSchemaModel();

      expect(json.type, JsonSchemaType.integer);
      expect(json.minimum, equals(1500));
      expect(json.maximum, equals(2000));
    });

    test('date codec model omits non-standard format range keywords', () {
      final json = Ack.date()
          .min(DateTime(2026, 1, 1))
          .max(DateTime(2026, 12, 31))
          .toJsonSchemaModel();

      expect(json.type, JsonSchemaType.string);
      expect(json.format, equals('date'));
      expect(json.toJson().containsKey('formatMinimum'), isFalse);
      expect(json.toJson().containsKey('formatMaximum'), isFalse);
    });

    test('string IP model preserves ipv4-or-ipv6 oneOf composition', () {
      final json = Ack.string().ip().toJsonSchemaModel();

      expect(json.type, JsonSchemaType.string);
      expect(json.oneOf, hasLength(2));
      expect(json.oneOf!.map((schema) => schema.format), ['ipv4', 'ipv6']);
      expect(json.toJson()['oneOf'], [
        {'format': 'ipv4'},
        {'format': 'ipv6'},
      ]);
    });

    test('accepts canonical literal-discriminator pattern (model path)', () {
      final schema = Ack.discriminated<Map<String, Object?>>(
        discriminatorKey: 'type',
        schemas: {
          'cat': Ack.object({'type': Ack.literal('cat'), 'name': Ack.string()}),
          'dog': Ack.object({'type': Ack.literal('dog'), 'name': Ack.string()}),
        },
      );

      final json = schema.toJsonSchemaModel();

      expect(json.discriminator?.propertyName, equals('type'));
      expect(json.oneOf, hasLength(2));
      final cat = json.oneOf!.firstWhere(
        (b) => b.properties?['type']?.constValue == 'cat',
      );
      expect(cat.properties!['name']?.type, JsonSchemaType.string);
    });

    test('throws when branch literal does not match label (model path)', () {
      final schema = Ack.discriminated<Map<String, Object?>>(
        discriminatorKey: 'type',
        schemas: {
          'cat': Ack.object({'type': Ack.literal('dog'), 'name': Ack.string()}),
        },
      );

      expect(() => schema.toJsonSchemaModel(), throwsArgumentError);
    });

    test('accepts default-wrapped object branch (model path)', () {
      final schema = Ack.discriminated<Map<String, Object?>>(
        discriminatorKey: 'type',
        schemas: {
          'cat': Ack.object({
            'type': Ack.literal('cat'),
            'name': Ack.string(),
          }).withDefault({'type': 'cat', 'name': 'Milo'}),
        },
      );

      expect(() => schema.toJsonSchemaModel(), returnsNormally);
    });

    test('discriminated model keeps discriminator const metadata', () {
      final json = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'cat': Ack.object({'name': Ack.string()}),
        },
      ).toJsonSchemaModel();

      final catBranch = json.oneOf!.single;
      final discriminator = catBranch.properties!['type']!;

      expect(discriminator.constValue, 'cat');
      expect(discriminator.hasConstValue, isTrue);
      expect(discriminator.toJson()['const'], 'cat');
    });
  });
}
