import 'package:ack/ack.dart';
import 'package:test/test.dart';

import '../lib/discriminated_example.dart';

void main() {
  group('Discriminated Types Implementation Tests', () {
    group('Schema Generation Tests', () {
      test('Animal discriminated schema is generated correctly', () {
        expect(animalSchema, isA<DiscriminatedObjectSchema>());
      });

      test('Shape discriminated schema is generated correctly', () {
        expect(shapeSchema, isA<DiscriminatedObjectSchema>());
      });

      test('Cat schema is generated correctly', () {
        expect(catSchema, isA<ObjectSchema>());
      });

      test('Dog schema is generated correctly', () {
        expect(dogSchema, isA<ObjectSchema>());
      });
    });

    group('Schema Validation Tests', () {
      test('Animal schema validates Cat data', () {
        final catData = {'type': 'cat', 'meow': true, 'lives': 9};

        final result = animalSchema.safeParse(catData);
        expect(result.isOk, isTrue);
        final data = result.getOrThrow() as Map<String, dynamic>;
        expect(data['meow'], isTrue);
        expect(data['lives'], equals(9));
      });

      test('Animal schema validates Dog data', () {
        final dogData = {
          'type': 'dog',
          'bark': false,
          'breed': 'Golden Retriever',
        };

        final result = animalSchema.safeParse(dogData);
        expect(result.isOk, isTrue);
        final data = result.getOrThrow() as Map<String, dynamic>;
        expect(data['bark'], isFalse);
        expect(data['breed'], equals('Golden Retriever'));
      });

      test('Animal schema validates Bird data', () {
        final birdData = {'type': 'bird', 'canFly': true, 'wingspan': 2.5};

        final result = animalSchema.safeParse(birdData);
        expect(result.isOk, isTrue);
        final data = result.getOrThrow() as Map<String, dynamic>;
        expect(data['canFly'], isTrue);
        expect(data['wingspan'], equals(2.5));
      });

      test('Animal schema rejects unknown type', () {
        final invalidData = {'type': 'fish', 'swimming': true};

        expect(() => animalSchema.parse(invalidData), throwsException);
      });
    });

    group('Shape Discriminated Types Tests', () {
      test('Shape schema validates Circle data', () {
        final circleData = {'kind': 'circle', 'radius': 5.0};

        final result = shapeSchema.safeParse(circleData);
        expect(result.isOk, isTrue);
        final data = result.getOrThrow() as Map<String, dynamic>;
        expect(data['radius'], equals(5.0));
      });

      test('Shape schema validates Rectangle data', () {
        final rectangleData = {
          'kind': 'rectangle',
          'width': 4.0,
          'height': 3.0,
        };

        final result = shapeSchema.safeParse(rectangleData);
        expect(result.isOk, isTrue);
        final data = result.getOrThrow() as Map<String, dynamic>;
        expect(data['width'], equals(4.0));
        expect(data['height'], equals(3.0));
      });

      test('Shape schema rejects unknown kind', () {
        final invalidData = {'kind': 'triangle', 'base': 5.0, 'height': 4.0};

        expect(() => shapeSchema.parse(invalidData), throwsException);
      });
    });

    group('Individual Schema Tests', () {
      test('Cat schema validates correctly', () {
        // Sub-schemas now include discriminator field
        final catData = {'type': 'cat', 'meow': true, 'lives': 7};

        final result = catSchema.parse(catData) as Map<String, dynamic>;
        expect(result['type'], equals('cat'));
        expect(result['meow'], isTrue);
        expect(result['lives'], equals(7));
      });

      test('Dog schema validates correctly', () {
        // Sub-schemas now include discriminator field
        final dogData = {'type': 'dog', 'bark': true, 'breed': 'Labrador'};

        final result = dogSchema.parse(dogData) as Map<String, dynamic>;
        expect(result['type'], equals('dog'));
        expect(result['bark'], isTrue);
        expect(result['breed'], equals('Labrador'));
      });
    });
  });
}
