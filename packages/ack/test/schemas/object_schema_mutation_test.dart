import 'package:ack/ack.dart';
import 'package:test/test.dart';

enum _Colour { red, blue }

void main() {
  group('ObjectSchema immutability', () {
    test('does not reflect mutations to source map after construction', () {
      final props = <String, AckSchema>{
        'name': Ack.string(),
      };

      final schema = Ack.object(props);

      // Mutate original map after schema creation
      props['age'] = Ack.integer();

      expect(schema.properties.containsKey('age'), isFalse);
      expect(schema.properties.containsKey('name'), isTrue);
    });

    test('properties map is unmodifiable', () {
      final schema = Ack.object({
        'name': Ack.string(),
      });

      expect(
        () => schema.properties['name'] = Ack.string().minLength(3),
        throwsUnsupportedError,
      );
      expect(
        () => schema.properties['age'] = Ack.integer(),
        throwsUnsupportedError,
      );
    });
  });

  group('DiscriminatedObjectSchema immutability', () {
    test('does not reflect mutations to schemas map after construction', () {
      final variants = <String, AckSchema>{
        'cat': Ack.object({'type': Ack.literal('cat')}),
      };

      final schema = DiscriminatedObjectSchema(
        discriminatorKey: 'type',
        schemas: variants,
      );

      variants['dog'] = Ack.object({'type': Ack.literal('dog')});

      expect(schema.schemas.containsKey('dog'), isFalse);
      expect(schema.schemas.keys, contains('cat'));
    });

    test('schemas map is unmodifiable', () {
      final schema = Ack.discriminated(
        discriminatorKey: 'type',
        schemas: {
          'cat': Ack.object({'type': Ack.literal('cat')}),
        },
      );

      expect(
        () => schema.schemas['cat'] = Ack.object({'type': Ack.literal('cat')}),
        throwsUnsupportedError,
      );
      expect(
        () => schema.schemas['dog'] = Ack.object({'type': Ack.literal('dog')}),
        throwsUnsupportedError,
      );
    });
  });

  group('AnyOfSchema immutability', () {
    test('does not reflect mutations to source list after construction', () {
      final variants = <AckSchema>[
        Ack.string(),
        Ack.integer(),
      ];

      final schema = Ack.anyOf(variants);

      variants.add(Ack.boolean());

      expect(schema.schemas.length, 2);
    });

    test('schemas list is unmodifiable', () {
      final schema = Ack.anyOf([
        Ack.string(),
        Ack.integer(),
      ]);

      expect(() => schema.schemas.add(Ack.boolean()), throwsUnsupportedError);
      expect(() => schema.schemas.removeAt(0), throwsUnsupportedError);
    });
  });

  group('EnumSchema immutability', () {
    test('does not reflect mutations to source list after construction', () {
      final variants = <_Colour>[_Colour.red];

      final schema = EnumSchema(values: variants);

      variants.add(_Colour.blue);

      expect(schema.values, equals([_Colour.red]));
    });

    test('values list is unmodifiable', () {
      final schema = EnumSchema(values: [_Colour.red, _Colour.blue]);

      expect(() => schema.values.add(_Colour.red), throwsUnsupportedError);
      expect(() => schema.values.removeAt(0), throwsUnsupportedError);
    });
  });
}
